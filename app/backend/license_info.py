"""Conservative, entirely local license display; LICENSE remains authoritative."""

from pathlib import Path


def classify_license(text: str) -> dict[str, str]:
    normalized = " ".join(text.lower().split())
    result = {
        "name": "Custom project license",
        "summary": "See bundled LICENSE for full terms.",
        "commercial": "",
    }
    if "mit license" in normalized and "non-commercial" in normalized:
        return result
    if all(
        part in normalized
        for part in (
            "non-commercial",
            "attribution",
            "prior written permission from filip twardowski",
            "commercial licensing may be granted separately",
        )
    ):
        result.update(
            name="TwardyPass Non-Commercial Source License",
            summary="Non-commercial use permitted with attribution. See LICENSE for full conditions.",
            commercial="Commercial use requires prior written permission from Filip Twardowski.",
        )
    elif all(
        part in normalized
        for part in (
            "mit license",
            "permission is hereby granted, free of charge",
            "to deal in the software",
        )
    ):
        result.update(name="MIT License", summary="See bundled LICENSE for permissions and conditions.")
    elif "apache license" in normalized and "version 2.0" in normalized:
        result.update(
            name="Apache License 2.0", summary="See bundled LICENSE for permissions and conditions."
        )
    return result


def read_license(path: Path) -> dict[str, str]:
    try:
        return classify_license(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError):
        return {
            "name": "License unavailable",
            "summary": "See bundled LICENSE for full terms.",
            "commercial": "",
        }
