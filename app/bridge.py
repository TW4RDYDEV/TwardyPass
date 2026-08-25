from __future__ import annotations

import threading

from PySide6.QtCore import QObject, QTimer, Signal, Slot
from PySide6.QtGui import QGuiApplication

from app.backend.analyzer import analyze_password
from app.backend.breach_checker import check_pwned_password
from app.backend.generator import generate_passphrase, generate_password


class AppBridge(QObject):
    breachFinished = Signal("QVariantMap")
    breachStarted = Signal()
    toastRequested = Signal(str, str)

    def __init__(self) -> None:
        super().__init__()
        self._clipboard_secret = ""
        self._clipboard_timer = QTimer(self)
        self._clipboard_timer.setSingleShot(True)
        self._clipboard_timer.timeout.connect(self._clear_clipboard_if_matching)

    @Slot(str, str, result="QVariantMap")
    def analyzePassword(self, password: str, context_csv: str = "") -> dict:
        user_inputs = [item.strip() for item in context_csv.split(",") if item.strip()]
        return analyze_password(password, user_inputs=user_inputs)

    @Slot(str)
    def checkBreach(self, password: str) -> None:
        if not password:
            self.breachFinished.emit(
                {
                    "found": False,
                    "count": 0,
                    "status": "error",
                    "message": "Enter a password before checking breach exposure.",
                }
            )
            return

        self.breachStarted.emit()
        thread = threading.Thread(target=self._breach_worker, args=(password,), daemon=True)
        thread.start()

    def _breach_worker(self, password: str) -> None:
        result = check_pwned_password(password)
        self.breachFinished.emit(result.to_dict())

    @Slot(int, bool, bool, bool, bool, bool, result="QVariantMap")
    def generatePassword(
        self,
        length: int,
        uppercase: bool,
        lowercase: bool,
        digits: bool,
        symbols: bool,
        exclude_ambiguous: bool,
    ) -> dict:
        return generate_password(
            length=length,
            uppercase=uppercase,
            lowercase=lowercase,
            digits=digits,
            symbols=symbols,
            exclude_ambiguous=exclude_ambiguous,
        )

    @Slot(int, str, result="QVariantMap")
    def generatePassphrase(self, words: int, separator: str) -> dict:
        return generate_passphrase(words=words, separator=separator)

    @Slot(str, int)
    def copySecure(self, text: str, seconds: int = 30) -> None:
        if not text:
            return

        clipboard = QGuiApplication.clipboard()
        clipboard.setText(text)
        self._clipboard_secret = text

        seconds = max(5, min(300, int(seconds)))
        self._clipboard_timer.start(seconds * 1000)
        self.toastRequested.emit(
            "Copied securely", f"Clipboard will clear in {seconds} seconds if unchanged."
        )

    @Slot()
    def clearSensitiveClipboard(self) -> None:
        self._clear_clipboard_if_matching()

    def _clear_clipboard_if_matching(self) -> None:
        if not self._clipboard_secret:
            return

        clipboard = QGuiApplication.clipboard()
        if clipboard.text() == self._clipboard_secret:
            clipboard.clear()
            self.toastRequested.emit("Clipboard cleared", "Sensitive clipboard content was removed.")

        self._clipboard_secret = ""
        self._clipboard_timer.stop()
