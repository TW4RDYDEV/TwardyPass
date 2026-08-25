# TwardyPass

TwardyPass is a privacy-first desktop password security workbench built with Python, PySide6/QML, zxcvbn, and the Have I Been Pwned Pwned Passwords API.

## Current features

- Real-time local password analysis
- 0–100 explanatory security score
- zxcvbn pattern-aware guessing estimates
- Security DNA indicators
- Local checks for sequences, keyboard walks, repeats, years, common fragments, and optional personal context
- Manual HIBP Pwned Passwords lookup using k-anonymity
- Padded HIBP range responses
- Cryptographically secure password generator
- Memorable passphrase generator
- Secure clipboard auto-clear
- Three-way local password comparison
- Panic clear shortcut (`Ctrl+Shift+X`)
- Dark QML dashboard UI

## Privacy model

TwardyPass does not store analyzed or generated passwords. Breach checks are manual. For HIBP Pwned Passwords checks, SHA-1 is computed locally and only the first five hexadecimal characters are sent to the range endpoint. Returned suffixes are compared locally.

## Run locally

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
python main.py
```

## Tests

```powershell
pytest
```

## Important note

Password-strength and crack-time estimates are educational risk indicators, not guarantees. Real attack cost depends on password uniqueness, service rate limits, hashing algorithms, hardware, credential reuse, and other factors.

## Roadmap

TwardyPass is actively being developed. The current release focuses on secure local password analysis, breach checking, password generation, comparison tools, and privacy-first desktop functionality.

Planned improvements for upcoming versions include:

* Windows standalone `.exe` release
* Portable build for users who do not have Python installed
* Improved installer and release packaging
* Advanced password policy analysis
* Expanded Security DNA visualization
* Improved attack-resistance estimates
* Enhanced breach intelligence
* More generator presets
* Stronger passphrase generation options
* Exportable security reports
* Additional privacy controls
* UI animations and visual improvements
* Extended automated testing
* GitHub Actions CI/CD
* Application screenshots and release documentation
* Additional platform support where practical

The goal is to continue evolving TwardyPass into a polished, privacy-focused password security workbench rather than a simple password strength checker.

### Next Release

The next planned release will focus primarily on:

* standalone Windows executable
* improved UI and animations
* expanded password analysis
* better reporting and visualization
* additional generator and privacy features

Development progress and new releases will be published through this repository.


## License

TwardyPass is released under the **TwardyPass Non-Commercial Source License**.

You may use, study, modify, and redistribute the project for non-commercial purposes with attribution.

**Commercial use, resale, paid redistribution, or incorporation into commercial products or services requires prior written permission from Filip Twardowski.**

See [LICENSE](LICENSE) for the full terms.
