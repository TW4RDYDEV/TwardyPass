from __future__ import annotations

import math
import random
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


def _filter_chars(chars: str, exclude_ambiguous: bool) -> str:
    if not exclude_ambiguous:
        return chars
    return "".join(ch for ch in chars if ch not in AMBIGUOUS)


def generate_password(
    length: int = 20,
    uppercase: bool = True,
    lowercase: bool = True,
    digits: bool = True,
    symbols: bool = True,
    exclude_ambiguous: bool = True,
) -> dict[str, object]:
    length = max(4, min(128, int(length)))

    groups: list[str] = []
    if lowercase:
        groups.append(_filter_chars(string.ascii_lowercase, exclude_ambiguous))
    if uppercase:
        groups.append(_filter_chars(string.ascii_uppercase, exclude_ambiguous))
    if digits:
        groups.append(_filter_chars(string.digits, exclude_ambiguous))
    if symbols:
        groups.append(_filter_chars(SYMBOLS, exclude_ambiguous))

    groups = [group for group in groups if group]
    if not groups:
        groups = [_filter_chars(string.ascii_letters + string.digits, exclude_ambiguous)]

    if length < len(groups):
        length = len(groups)

    pool = "".join(groups)
    password_chars = [secrets.choice(group) for group in groups]
    password_chars.extend(secrets.choice(pool) for _ in range(length - len(password_chars)))
    random.SystemRandom().shuffle(password_chars)
    password = "".join(password_chars)

    entropy = length * math.log2(len(set(pool))) if len(set(pool)) > 1 else 0.0
    return {
        "password": password,
        "entropy": round(entropy, 1),
        "poolSize": len(set(pool)),
        "length": length,
    }


def generate_passphrase(words: int = 6, separator: str = "-") -> dict[str, object]:
    words = max(4, min(12, int(words)))
    separators = {"-", ".", "_", " ", "/"}
    separator = separator if separator in separators else "-"

    # 32 × 32 = 1,024 possible adjective+noun compounds per token.
    tokens = [f"{secrets.choice(ADJECTIVES)}{secrets.choice(NOUNS)}" for _ in range(words)]
    phrase = separator.join(tokens)
    entropy = words * math.log2(len(ADJECTIVES) * len(NOUNS))

    return {
        "password": phrase,
        "entropy": round(entropy, 1),
        "words": words,
        "separator": separator,
    }
