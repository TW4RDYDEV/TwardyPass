from __future__ import annotations

import math
import secrets
import string

AMBIGUOUS = set("Il1O0o|`'\"")
SYMBOLS = "!@#$%^&*()-_=+[]{};:,.?/~"

ADJECTIVES = [
    "amber",
    "arctic",
    "autumn",
    "azure",
    "bright",
    "calm",
    "cedar",
    "cobalt",
    "cosmic",
    "crimson",
    "crystal",
    "daring",
    "deep",
    "ember",
    "frost",
    "gentle",
    "golden",
    "green",
    "hidden",
    "iron",
    "ivory",
    "lunar",
    "mellow",
    "misty",
    "navy",
    "noble",
    "polar",
    "quiet",
    "rapid",
    "royal",
    "silver",
    "solar",
]

NOUNS = [
    "anchor",
    "badger",
    "beacon",
    "brook",
    "canyon",
    "cedar",
    "comet",
    "coral",
    "eagle",
    "falcon",
    "field",
    "forest",
    "harbor",
    "hawk",
    "island",
    "lantern",
    "maple",
    "meadow",
    "meteor",
    "mountain",
    "ocean",
    "orbit",
    "otter",
    "piano",
    "river",
    "rocket",
    "summit",
    "tiger",
    "valley",
    "voyage",
    "willow",
    "wolf",
]


PRESETS = {
    "BALANCED": dict(
        length=20, uppercase=True, lowercase=True, digits=True, symbols=True, exclude_ambiguous=True
    ),
    "MAXIMUM SECURITY": dict(
        length=64, uppercase=True, lowercase=True, digits=True, symbols=True, exclude_ambiguous=False
    ),
    "WEBSITE COMPATIBLE": dict(
        length=24, uppercase=True, lowercase=True, digits=True, symbols=False, exclude_ambiguous=True
    ),
    "EASY TO TYPE": dict(
        length=24, uppercase=False, lowercase=True, digits=True, symbols=False, exclude_ambiguous=True
    ),
}


def generate_password(
    length=20, uppercase=True, lowercase=True, digits=True, symbols=True, exclude_ambiguous=True, excluded=""
) -> dict:
    length = max(4, min(128, int(length)))
    banned = set(excluded) | (AMBIGUOUS if exclude_ambiguous else set())
    groups = []
    for enabled, chars in (
        (lowercase, string.ascii_lowercase),
        (uppercase, string.ascii_uppercase),
        (digits, string.digits),
        (symbols, SYMBOLS),
    ):
        if enabled:
            group = "".join(ch for ch in chars if ch not in banned)
            if not group:
                raise ValueError("Excluded characters remove an entire selected category.")
            groups.append(group)
    if not groups:
        raise ValueError("Select at least one character category.")
    pool = "".join(groups)
    # Exact uniform sampling from strings containing every requested category.
    # Dynamic programming avoids unbounded rejection when exclusions leave tiny groups.
    full = (1 << len(groups)) - 1
    ways = [[int(mask == full) for mask in range(full + 1)]]
    for _ in range(length):
        ways.append(
            [
                sum(len(group) * ways[-1][mask | (1 << i)] for i, group in enumerate(groups))
                for mask in range(full + 1)
            ]
        )
    mask = 0
    chars = []
    for remaining in range(length, 0, -1):
        ticket = secrets.randbelow(ways[remaining][mask])
        for i, group in enumerate(groups):
            weight = len(group) * ways[remaining - 1][mask | (1 << i)]
            if ticket < weight:
                chars.append(secrets.choice(group))
                mask |= 1 << i
                break
            ticket -= weight
    return {
        "password": "".join(chars),
        "entropy": round(math.log2(ways[length][0]), 1),
        "poolSize": len(pool),
        "length": length,
    }


# Deduplicate actual output tokens, rather than assuming every pair is distinct.
TOKENS = sorted({a + n for a in ADJECTIVES for n in NOUNS})


def generate_passphrase(words=6, separator="-", capitalization="lower", number=False, symbol=False) -> dict:
    words = max(4, min(12, int(words)))
    separator = separator if separator in {"-", ".", "_", " ", "/"} else "-"
    tokens = [secrets.choice(TOKENS) for _ in range(words)]
    if capitalization == "title":
        tokens = [token.title() for token in tokens]
    elif capitalization == "upper":
        tokens = [token.upper() for token in tokens]
    elif capitalization != "lower":
        raise ValueError("Unknown capitalization option.")
    phrase = separator.join(tokens)
    entropy = words * math.log2(len(TOKENS))
    if number:
        phrase += str(secrets.randbelow(100)).zfill(2)
        entropy += math.log2(100)
    if symbol:
        phrase += secrets.choice(SYMBOLS)
        entropy += math.log2(len(SYMBOLS))
    return {"password": phrase, "entropy": round(entropy, 1), "words": words, "separator": separator}
