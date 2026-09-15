import hashlib
import json
import math
import string
from pathlib import Path
from unittest.mock import Mock

import pytest
import requests
from pypdf import PdfReader

from app.backend.analyzer import analyze_password
from app.backend.breach_checker import check_pwned_password
from app.backend.generator import PRESETS, SYMBOLS, TOKENS, generate_passphrase, generate_password
from app.backend.license_info import classify_license, read_license
from app.backend.policy import PRESETS as POLICIES
from app.backend.policy import evaluate_policy
from app.backend.reports import sanitized_report, write_json, write_pdf
from app.backend.session import SessionStats

DUMMY = "DUMMY_ONLY_not_a_real_credential_8274!"


@pytest.mark.parametrize(
    "password",
    ["", "🔒" * 20, "Zażółć-DUMMY-東京-8274!", "DUMMY-" * 1365 + "xx"],
    ids=["empty", "emoji", "unicode", "8192chars"],
)
def test_analysis_shape_unicode_and_limit(password):
    result = analyze_password(password)
    assert result["length"] == min(8192, len(password))
    assert isinstance(result["guesses"], str)
    assert 0 <= result["score"] <= 100
    assert result["dna"]["breachSafety"] is None
    assert set(result["attack"]) == {"onlineThrottled", "onlineUnthrottled", "offlineSlow", "offlineFast"}


def test_no_matched_fragments_in_findings():
    result = analyze_password("DUMMY_password_2097!", ["DUMMY"])
    details = " ".join(f["detail"] for f in result["findings"])
    assert "2097" not in details and "DUMMY" not in details
    assert {"year", "common_word", "personal", "suffix"} <= {f["type"] for f in result["findings"]}


@pytest.mark.parametrize("preset", PRESETS.values())
def test_generator_presets(preset):
    result = generate_password(**preset)
    assert result["length"] == preset["length"]
    for key, pool in (
        ("uppercase", string.ascii_uppercase),
        ("lowercase", string.ascii_lowercase),
        ("digits", string.digits),
        ("symbols", SYMBOLS),
    ):
        assert any(c in pool for c in result["password"]) == preset[key]


def test_exclusions_are_strict():
    result = generate_password(excluded="abcXYZ234!@", length=64)
    assert not set(result["password"]) & set("abcXYZ234!@")
    with pytest.raises(ValueError):
        generate_password(excluded=string.ascii_lowercase)
    with pytest.raises(ValueError):
        generate_password(uppercase=False, lowercase=False, digits=False, symbols=False)


def test_exact_uniform_space_entropy():
    # Only 'a' and 'A' remain; 2^4 minus all-a and all-A = 14 valid strings.
    excluded = "".join(c for c in string.ascii_letters if c not in "aA")
    result = generate_password(length=4, digits=False, symbols=False, excluded=excluded)
    assert set(result["password"]) == {"a", "A"}
    assert result["entropy"] == round(math.log2(14), 1)


@pytest.mark.parametrize("capitalization", ["lower", "title", "upper"])
@pytest.mark.parametrize("separator", ["-", ".", "_", " ", "/"])
def test_passphrase_options(capitalization, separator):
    result = generate_passphrase(4, separator, capitalization, number=True, symbol=True)
    phrase = result["password"]
    assert phrase[-1] in SYMBOLS and phrase[-3:-1].isdigit()
    tokens = phrase[:-3].split(separator)
    assert len(tokens) == 4
    assert all(token.lower() in TOKENS for token in tokens)
    assert result["entropy"] == round(4 * math.log2(len(TOKENS)) + math.log2(100 * len(SYMBOLS)), 1)
    if capitalization == "upper":
        assert phrase.upper() == phrase
    if capitalization == "title":
        assert all(token == token.title() for token in tokens)


def response(text, status=200):
    result = Mock(text=text, status_code=status)
    result.raise_for_status.return_value = None
    return result


def test_breach_prefix_padding_and_local_match(monkeypatch):
    digest = hashlib.sha1(DUMMY.encode(), usedforsecurity=False).hexdigest().upper()
    get = Mock(return_value=response(f"{'A' * 35}:0\n{digest[5:]}:12\nmalformed"))
    monkeypatch.setattr(requests, "get", get)
    result = check_pwned_password(DUMMY)
    assert result.found and result.count == 12
    args, kwargs = get.call_args
    assert args[0] == "https://api.pwnedpasswords.com/range/" + digest[:5]
    assert kwargs["headers"]["Add-Padding"] == "true"
    assert kwargs["allow_redirects"] is False
    assert DUMMY not in repr(get.call_args) and digest not in repr(get.call_args)


@pytest.mark.parametrize(
    "body,status",
    [("garbage", "error"), ("", "error"), ("A" * 35 + ":0", "clear"), ("A" * 35 + ":-1", "error")],
)
def test_breach_parsing(monkeypatch, body, status):
    monkeypatch.setattr(requests, "get", Mock(return_value=response(body)))
    assert check_pwned_password(DUMMY).status == status


def test_breach_timeout_does_not_expose_exception(monkeypatch):
    monkeypatch.setattr(requests, "get", Mock(side_effect=requests.Timeout(DUMMY)))
    result = check_pwned_password(DUMMY)
    assert result.status == "error" and DUMMY not in result.message


def test_redirect_is_not_a_clean_result(monkeypatch):
    monkeypatch.setattr(requests, "get", Mock(return_value=response("A" * 35 + ":0", 302)))
    assert check_pwned_password(DUMMY).status == "error"


def test_policy_requires_current_manual_result():
    analysis = analyze_password(DUMMY)
    for status in ("idle", "checking", "error", "compromised"):
        result = evaluate_policy(DUMMY, analysis, {"requireBreach": True}, {"status": status})
        assert not result["passed"]
    assert evaluate_policy(DUMMY, analysis, {"requireBreach": True}, {"status": "clear"})["passed"]


@pytest.mark.parametrize("preset", POLICIES.values())
def test_empty_password_never_passes(preset):
    assert not evaluate_policy("", analyze_password(""), preset)["passed"]


def test_policy_rule_failures():
    value = "dummy_only_password_2026"
    result = evaluate_policy(
        value,
        analyze_password(value, ["dummy"]),
        {
            "uppercase": True,
            "symbols": True,
            "minLength": 50,
            "minScore": 99,
            "minEntropy": 900,
            "rejectPatterns": True,
            "rejectPersonal": True,
        },
    )
    outcomes = {r["id"]: r["passed"] for r in result["rules"]}
    assert not outcomes["uppercase"] and not outcomes["rejectPersonal"] and not outcomes["rejectPatterns"]
    assert outcomes["symbols"]  # underscore


def test_license_matches_bundled_and_handles_replacement(tmp_path):
    info = read_license(Path("LICENSE"))
    assert "Non-Commercial" in info["name"] and "Filip Twardowski" in info["commercial"]
    mit = "MIT License. Permission is hereby granted, free of charge, to deal in the Software."
    assert classify_license(mit)["name"] == "MIT License"
    assert classify_license(mit)["commercial"] == ""
    assert classify_license(mit + " Non-commercial use only.")["name"] == "Custom project license"
    assert classify_license("unknown custom terms")["commercial"] == ""
    assert "unavailable" in read_license(tmp_path / "missing")["name"]


def test_session_stats_only_aggregate():
    stats = SessionStats()
    for score in [20, 50, 90]:
        stats.record(score)
    stats.breaches += 1
    assert stats.to_dict() == {"analyzed": 3, "average": 53.3, "weak": 1, "strong": 1, "breaches": 1}
    assert all(isinstance(v, (int, float)) for v in vars(stats).values())
    stats.clear()
    assert not any(stats.to_dict().values())


def test_report_allowlist_and_pdf_text(tmp_path):
    analysis = analyze_password(DUMMY, ["DUMMY"])
    analysis["password"] = DUMMY
    analysis["findings"].append({"type": DUMMY, "detail": DUMMY, "title": DUMMY})
    analysis["recommendations"] = [DUMMY]
    analysis["attack"] = {"offlineFast": DUMMY}
    report = sanitized_report(
        analysis,
        {"status": "clear", "message": DUMMY},
        {"passed": False, "rules": [{"id": "minLength", "label": DUMMY, "passed": False}, {"id": DUMMY}]},
    )
    assert DUMMY not in json.dumps(report)
    json_path, pdf_path = tmp_path / "report.json", tmp_path / "report.pdf"
    write_json(json_path, report)
    write_pdf(pdf_path, report)
    assert DUMMY not in json_path.read_text()
    text = "".join(page.extract_text() for page in PdfReader(pdf_path).pages)
    assert DUMMY not in text and "TwardyPass" in text and "approximations" in text
    assert report["dna"]["breachSafety"] == 100
    assert sanitized_report(analysis)["dna"]["breachSafety"] is None
