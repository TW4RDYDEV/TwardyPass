from __future__ import annotations

import hashlib
from dataclasses import dataclass

import requests

HIBP_RANGE_URL = "https://api.pwnedpasswords.com/range/{prefix}"


@dataclass(frozen=True)
class BreachResult:
    found: bool
    count: int
    status: str
    message: str

    def to_dict(self) -> dict[str, object]:
        return {
            "found": self.found,
            "count": self.count,
            "status": self.status,
            "message": self.message,
        }


def check_pwned_password(password: str, timeout: float = 8.0) -> BreachResult:
    if not password:
        return BreachResult(False, 0, "error", "Enter a password before checking breach exposure.")

    digest = hashlib.sha1(password.encode("utf-8"), usedforsecurity=False).hexdigest().upper()
    prefix, suffix = digest[:5], digest[5:]

    headers = {
        "User-Agent": "TwardyPass/1.0 (+local password security workbench)",
        "Add-Padding": "true",
    }

    try:
        response = requests.get(
            HIBP_RANGE_URL.format(prefix=prefix),
            headers=headers,
            timeout=timeout,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        return BreachResult(False, 0, "error", f"Breach service unavailable: {exc}")

    for line in response.text.splitlines():
        try:
            returned_suffix, count_text = line.split(":", 1)
            if returned_suffix.strip().upper() == suffix:
                count = int(count_text.strip())
                if count > 0:
                    return BreachResult(
                        True,
                        count,
                        "compromised",
                        f"This password appears {count:,} times in the Pwned Passwords corpus.",
                    )
        except (ValueError, TypeError):
            continue

    return BreachResult(
        False,
        0,
        "clear",
        "No match was found in the Pwned Passwords corpus.",
    )
