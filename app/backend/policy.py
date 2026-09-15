"""Local, explanatory policy checks. Presets are not certifications."""

import re

PRESETS = {
    "BALANCED": {"minLength": 16, "minScore": 60},
    "HIGH SECURITY": {
        "minLength": 24,
        "minScore": 80,
        "minEntropy": 100,
        "rejectPatterns": True,
        "rejectPersonal": True,
        "requireBreach": True,
    },
    "NIST-INSPIRED": {"minLength": 15, "rejectPatterns": True, "requireBreach": True},
    "CUSTOM": {},
}

RULE_LABELS = {
    "present": "Password provided",
    "minLength": "Minimum length",
    "minScore": "Minimum score",
    "minEntropy": "Minimum estimated entropy",
    "uppercase": "Uppercase character",
    "lowercase": "Lowercase character",
    "digits": "Number",
    "symbols": "Symbol",
    "rejectPatterns": "No common patterns",
    "rejectPersonal": "No personal terms",
    "requireBreach": "Manual breach lookup: no match",
}


def evaluate_policy(password: str, analysis: dict, config: dict, breach: dict | None = None) -> dict:
    rules = [{"id": "present", "label": RULE_LABELS["present"], "passed": bool(password)}]
    for key, metric in (("minLength", "length"), ("minScore", "score"), ("minEntropy", "entropy")):
        threshold = max(0, float(config.get(key, 0)))
        if threshold:
            rules.append(
                {
                    "id": key,
                    "label": f"{RULE_LABELS[key]}: {threshold:g}",
                    "passed": analysis.get(metric, 0) >= threshold,
                }
            )
    for key, pattern in (
        ("uppercase", r"[A-Z]"),
        ("lowercase", r"[a-z]"),
        ("digits", r"\d"),
        ("symbols", r"[^\w\s]|_"),
    ):
        if config.get(key):
            rules.append({"id": key, "label": RULE_LABELS[key], "passed": bool(re.search(pattern, password))})
    types = {item["type"] for item in analysis.get("findings", [])}
    checks = {
        "rejectPatterns": not types.intersection(
            {"sequence", "keyboard", "repeat", "common_word", "dictionary", "year", "suffix"}
        ),
        "rejectPersonal": "personal" not in types,
        "requireBreach": (breach or {}).get("status") == "clear",
    }
    for key, passed in checks.items():
        if config.get(key):
            rules.append({"id": key, "label": RULE_LABELS[key], "passed": passed})
    return {"passed": all(rule["passed"] for rule in rules), "rules": rules}
