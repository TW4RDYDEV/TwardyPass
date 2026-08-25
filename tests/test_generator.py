from app.backend.generator import generate_passphrase, generate_password


def test_password_generator_respects_length_and_categories():
    result = generate_password(length=24, uppercase=True, lowercase=True, digits=True, symbols=True)
    password = result["password"]
    assert len(password) == 24
    assert any(ch.islower() for ch in password)
    assert any(ch.isupper() for ch in password)
    assert any(ch.isdigit() for ch in password)
    assert any(not ch.isalnum() for ch in password)


def test_passphrase_word_count():
    result = generate_passphrase(words=6, separator="-")
    assert len(result["password"].split("-")) == 6
