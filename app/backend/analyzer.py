from __future__ import annotations

import math
import re
from dataclasses import dataclass
from typing import Any

from zxcvbn import zxcvbn

COMMON_FRAGMENTS = {
    "password",
    "pass",
    "admin",
    "welcome",
    "qwerty",
    "letmein",
    "login",
    "dragon",
    "monkey",
    "football",
    "baseball",
    "master",
    "shadow",
    "summer",
    "winter",
    "spring",
    "autumn",
    "secret",
    "love",
    "hello",
    "abc",
    "123",
}

KEYBOARD_ROWS = (
    "qwertyuiop",
    "asdfghjkl",
    "zxcvbnm",
    "1234567890",
)


@dataclass(frozen=True)
class Finding:
    severity: str
    title: str
    detail: str

    def to_dict(self) -> dict[str, str]:
        return {
            "severity": self.severity,
            "title": self.title,
            "detail": self.detail,
        }


def _clamp(value: float, low: int = 0, high: int = 100) -> int:
    return int(max(low, min(high, round(value))))


def _charset_size(password: str) -> int:
    size = 0
    if re.search(r"[a-z]", password):
        size += 26
    if re.search(r"[A-Z]", password):
        size += 26
    if re.search(r"\d", password):
        size += 10
    if re.search(r"[^A-Za-z0-9]", password):
        size += 33
    return size


def _naive_entropy(password: str) -> float:
    if not password:
        return 0.0
    charset = _charset_size(password)
    return len(password) * math.log2(charset) if charset > 1 else 0.0


def _has_sequence(password: str, min_len: int = 4) -> bool:
    lowered = password.lower()
    alphabets = (
        "abcdefghijklmnopqrstuvwxyz",
        "zyxwvutsrqponmlkjihgfedcba",
        "0123456789",
        "9876543210",
    )
    for sequence in alphabets:
        for i in range(len(sequence) - min_len + 1):
            if sequence[i : i + min_len] in lowered:
                return True
    return False


def _has_keyboard_walk(password: str, min_len: int = 4) -> bool:
    lowered = password.lower()
    for row in KEYBOARD_ROWS:
        for source in (row, row[::-1]):
            for i in range(len(source) - min_len + 1):
                if source[i : i + min_len] in lowered:
                    return True
    return False


def _has_repeated_run(password: str) -> bool:
    return bool(re.search(r"(.)\1{2,}", password))


def _has_repeated_block(password: str) -> bool:
    return bool(re.search(r"(.{2,5})\1+", password, flags=re.IGNORECASE))


def _classification(score: int) -> str:
    if score < 20:
        return "Critical"
    if score < 40:
        return "Weak"
    if score < 60:
        return "Moderate"
    if score < 80:
        return "Strong"
    if score < 95:
        return "Very Strong"
    return "Exceptional"


def _score_color(score: int) -> str:
    if score < 20:
        return "#FF5F6D"
    if score < 40:
        return "#FF7A68"
    if score < 60:
        return "#FFBF5B"
    if score < 80:
        return "#49D6B1"
    return "#35C2FF"


def _time_label(value: Any) -> str:
    if value is None:
        return "Unknown"
    text = str(value).strip()
    return text[:1].upper() + text[1:] if text else "Unknown"


def analyze_password(password: str, user_inputs: list[str] | None = None) -> dict[str, Any]:
    user_inputs = [item.strip() for item in (user_inputs or []) if item and item.strip()]

    if not password:
        return {
            "score": 0,
            "classification": "Waiting",
            "color": "#8D9AAA",
            "entropy": 0.0,
            "length": 0,
            "guesses": 0,
            "guesses_log10": 0.0,
            "findings": [],
            "recommendations": ["Enter a password to begin the local security analysis."],
            "dna": {
                "length": 0,
                "unpredictability": 0,
                "patternSafety": 0,
                "characterMix": 0,
            },
            "attack": {
                "onlineThrottled": "—",
                "onlineUnthrottled": "—",
                "offlineSlow": "—",
                "offlineFast": "—",
            },
        }

    zx = zxcvbn(password, user_inputs=user_inputs, max_length=128)
    length = len(password)
    lowered = password.lower()
    unique_ratio = len(set(password)) / max(1, length)
    charset = _charset_size(password)
    naive_entropy = _naive_entropy(password)

    findings: list[Finding] = []
    penalties = 0

    if length < 8:
        findings.append(
            Finding(
                "danger",
                "Very short password",
                "Passwords under 8 characters are extremely exposed to guessing attacks.",
            )
        )
        penalties += 24
    elif length < 12:
        findings.append(
            Finding(
                "warning",
                "Limited length",
                "Increasing the password to at least 12–16 characters materially improves resistance.",
            )
        )
        penalties += 10
    elif length >= 16:
        findings.append(
            Finding(
                "good",
                "Excellent length",
                f"{length} characters gives the password a strong length foundation.",
            )
        )

    if _has_sequence(password):
        findings.append(
            Finding(
                "warning",
                "Sequential characters",
                "A predictable alphabetical or numeric sequence was detected.",
            )
        )
        penalties += 10

    if _has_keyboard_walk(password):
        findings.append(
            Finding(
                "warning", "Keyboard pattern", "A keyboard walk such as qwerty/asdf-style input was detected."
            )
        )
        penalties += 12

    if _has_repeated_run(password):
        findings.append(
            Finding(
                "warning", "Repeated characters", "Three or more identical characters appear consecutively."
            )
        )
        penalties += 8

    if _has_repeated_block(password):
        findings.append(
            Finding(
                "warning",
                "Repeated block",
                "A multi-character section is repeated, reducing unpredictability.",
            )
        )
        penalties += 10

    common_hits = sorted(
        fragment for fragment in COMMON_FRAGMENTS if len(fragment) >= 4 and fragment in lowered
    )
    if common_hits:
        findings.append(
            Finding(
                "danger",
                "Common password language",
                f"Predictable fragment detected: {', '.join(common_hits[:3])}.",
            )
        )
        penalties += min(24, 8 + 5 * len(common_hits))

    year_match = re.search(r"(?:19|20)\d{2}", password)
    if year_match:
        findings.append(
            Finding(
                "warning",
                "Predictable year",
                f"The year {year_match.group(0)} may be easy for an attacker to guess.",
            )
        )
        penalties += 7

    if user_inputs:
        personal_hits = [item for item in user_inputs if len(item) >= 3 and item.lower() in lowered]
        if personal_hits:
            findings.append(
                Finding(
                    "danger",
                    "Personal information detected",
                    "The password contains user-provided personal context.",
                )
            )
            penalties += 18

    if unique_ratio < 0.45 and length >= 8:
        findings.append(
            Finding(
                "warning",
                "Low character variety",
                "A large portion of the password reuses the same characters.",
            )
        )
        penalties += 8

    classes = sum(
        [
            bool(re.search(r"[a-z]", password)),
            bool(re.search(r"[A-Z]", password)),
            bool(re.search(r"\d", password)),
            bool(re.search(r"[^A-Za-z0-9]", password)),
        ]
    )

    base_map = {0: 14, 1: 31, 2: 52, 3: 74, 4: 91}
    score = base_map.get(int(zx.get("score", 0)), 14)
    score += min(8, max(0, length - 12) * 0.75)
    score += max(0, classes - 2) * 2
    score += min(5, max(0, naive_entropy - 70) / 12)
    score -= penalties
    score = _clamp(score)

    if int(zx.get("score", 0)) == 4 and length >= 20 and penalties == 0:
        score = max(score, 95)

    feedback = zx.get("feedback") or {}
    recommendations: list[str] = []
    warning = str(feedback.get("warning") or "").strip()
    if warning:
        recommendations.append(warning)
    recommendations.extend(str(item) for item in feedback.get("suggestions") or [] if str(item).strip())

    if length < 16:
        recommendations.append("Prefer 16+ characters for important accounts when the service allows it.")
    if classes < 3 and length < 20:
        recommendations.append(
            "Add more variety or, preferably, increase length with unrelated words or random characters."
        )
    if common_hits or year_match:
        recommendations.append("Avoid common words, dates, years, names, and predictable suffixes.")
    if not recommendations:
        recommendations.append(
            "No major structural weakness detected. Keep this password unique to one account."
        )

    deduped_recommendations: list[str] = []
    seen: set[str] = set()
    for item in recommendations:
        cleaned = item.strip().rstrip(".") + "."
        if cleaned.lower() not in seen:
            deduped_recommendations.append(cleaned)
            seen.add(cleaned.lower())

    if not findings:
        findings.append(
            Finding(
                "good",
                "No obvious structural weakness",
                "No common sequence, repetition, year, or personal-context match was detected.",
            )
        )

    crack = zx.get("crack_times_display") or {}
    guesses_log10 = float(zx.get("guesses_log10") or 0.0)

    length_metric = _clamp((length / 20) * 100)
    unpredictability = _clamp(guesses_log10 * 8.5)
    pattern_safety = _clamp(100 - penalties * 2.4)
    character_mix = _clamp((classes / 4) * 70 + unique_ratio * 30)

    return {
        "score": score,
        "classification": _classification(score),
        "color": _score_color(score),
        "entropy": round(naive_entropy, 1),
        "length": length,
        "charset": charset,
        "guesses": int(zx.get("guesses") or 0),
        "guesses_log10": round(guesses_log10, 2),
        "findings": [item.to_dict() for item in findings],
        "recommendations": deduped_recommendations[:5],
        "dna": {
            "length": length_metric,
            "unpredictability": unpredictability,
            "patternSafety": pattern_safety,
            "characterMix": character_mix,
        },
        "attack": {
            "onlineThrottled": _time_label(crack.get("online_throttling_100_per_hour")),
            "onlineUnthrottled": _time_label(crack.get("online_no_throttling_10_per_second")),
            "offlineSlow": _time_label(crack.get("offline_slow_hashing_1e4_per_second")),
            "offlineFast": _time_label(crack.get("offline_fast_hashing_1e10_per_second")),
        },
    }
