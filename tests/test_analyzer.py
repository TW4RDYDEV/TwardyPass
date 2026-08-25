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
