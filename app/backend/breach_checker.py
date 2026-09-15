from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass

import requests

from app.version import VERSION

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

    return check_hash_range(prefix, suffix, timeout)


def check_hash_range(prefix: str, suffix: str, timeout: float = 8.0) -> BreachResult:
    headers = {
        "User-Agent": f"TwardyPass/{VERSION} (+local password security workbench)",
        "Add-Padding": "true",
    }

    try:
        response = requests.get(
            HIBP_RANGE_URL.format(prefix=prefix),
            headers=headers,
            timeout=timeout,
            allow_redirects=False,
        )
        response.raise_for_status()
        if response.status_code != 200:
            return BreachResult(False, 0, "error", "Unexpected breach service response.")
    except requests.RequestException:
        return BreachResult(False, 0, "error", "Breach service unavailable. Try again later.")

    valid = 0
    for line in response.text.splitlines():
        try:
            returned_suffix, count_text = line.split(":", 1)
            returned_suffix = returned_suffix.strip().upper()
            if not re.fullmatch(r"[0-9A-F]{35}", returned_suffix):
                continue
            count = int(count_text.strip())
            if count < 0:
                continue
            valid += 1
            if returned_suffix == suffix:
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

    if not valid:
        return BreachResult(False, 0, "error", "Invalid breach service response. No result recorded.")
    return BreachResult(
        False,
        0,
        "clear",
        "No match found in the Pwned Passwords dataset.",
    )
