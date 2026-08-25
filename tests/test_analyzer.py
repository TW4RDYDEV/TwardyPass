from app.backend.analyzer import analyze_password


def test_common_password_is_weak():
    result = analyze_password("password123")
    assert result["score"] < 40


def test_long_randomish_password_is_stronger():
    weak = analyze_password("password123")
    strong = analyze_password("vQ7#pZ2!mN8@xR4$kL6&")
    assert strong["score"] > weak["score"]


def test_personal_context_is_detected():
    result = analyze_password("FilipSuperSecure2026!", ["Filip"])
    assert any(item["title"] == "Personal information detected" for item in result["findings"])


def test_password_over_128_characters_is_analyzed():
    password = ("A9!kLm2#Qx7$" * 30)[:300]
    result = analyze_password(password)

    assert result["length"] == 300
    assert result["classification"] != "Waiting"
    assert any(item["title"] == "Extended-length analysis" for item in result["findings"])


def test_password_at_ui_limit_is_analyzed():
    password = ("vQ7#pZ2!mN8@xR4$kL6&" * 500)[:8192]
    result = analyze_password(password)

    assert result["length"] == 8192
    assert isinstance(result["score"], int)
    assert 0 <= result["score"] <= 100


def test_strong_password_guess_count_is_qt_safe():
    # Around this length, zxcvbn can produce guess counts above signed 64-bit.
    # The value must cross the Python -> QVariantMap -> QML boundary as text.
    result = analyze_password("vQ7#pZ2!mN8@xR4$kL6&")

    assert result["length"] == 20
    assert result["classification"] != "Waiting"
    assert isinstance(result["guesses"], str)
    assert int(result["guesses"]) > 2**63 - 1


def test_very_long_randomish_password_keeps_analyzing():
    password = ("vQ7#pZ2!mN8@xR4$kL6&Ab3^Cd5*Ef8" * 300)[:8192]
    result = analyze_password(password)

    assert result["length"] == 8192
    assert result["classification"] != "Waiting"
    assert isinstance(result["guesses"], str)
    assert 0 <= result["score"] <= 100

