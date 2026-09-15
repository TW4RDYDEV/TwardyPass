from __future__ import annotations

import hashlib
import threading
from pathlib import Path

from PySide6.QtCore import Property, QObject, Qt, QTimer, QUrl, Signal, Slot
from PySide6.QtGui import QGuiApplication

from app.backend.analyzer import analyze_password
from app.backend.breach_checker import check_hash_range
from app.backend.generator import PRESETS as GENERATOR_PRESETS
from app.backend.generator import generate_passphrase, generate_password
from app.backend.license_info import read_license
from app.backend.policy import PRESETS as POLICY_PRESETS
from app.backend.policy import evaluate_policy
from app.backend.reports import sanitized_report, write_json, write_pdf
from app.backend.session import SessionStats
from app.version import VERSION


class AppBridge(QObject):
    stateChanged = Signal()
    settingsChanged = Signal()
    statsChanged = Signal()
    sensitiveCleared = Signal()
    breachFinished = Signal("QVariantMap")
    breachStarted = Signal()
    toastRequested = Signal(str, str)
    _workerFinished = Signal(int, "QVariantMap")

    def __init__(self):
        super().__init__()
        self._password = self._context = self._clipboard_secret = ""
        self._analysis = analyze_password("")
        self._breach = self._empty_breach()
        self._policy = {}
        self._revision = 0
        self._offline = False
        self._mask = True
        self._clipboard_seconds = 30
        self._inactivity_seconds = 0
        self._stats_enabled = False
        self._stats = SessionStats()
        self._license = read_license(Path(__file__).resolve().parents[1] / "LICENSE")
        self._clipboard_timer = QTimer(self)
        self._clipboard_timer.setSingleShot(True)
        self._clipboard_timer.timeout.connect(self._clear_clipboard_if_matching)
        self._inactivity_timer = QTimer(self)
        self._inactivity_timer.setSingleShot(True)
        self._inactivity_timer.timeout.connect(self.clearSensitiveData)
        self._workerFinished.connect(self._accept_breach, Qt.QueuedConnection)

    @staticmethod
    def _empty_breach():
        return {"status": "idle", "found": False, "count": 0, "message": "Not checked"}

    @Property(str, constant=True)
    def version(self):
        return VERSION

    @Property("QVariantMap", constant=True)
    def licenseInfo(self):
        return self._license

    @Property("QVariantMap", notify=stateChanged)
    def analysis(self):
        return self._analysis

    @Property("QVariantMap", notify=stateChanged)
    def breach(self):
        return self._breach

    @Property("QVariantMap", notify=stateChanged)
    def policy(self):
        return self._policy

    @Property("QVariantMap", notify=statsChanged)
    def statistics(self):
        return self._stats.to_dict()

    @Property(bool, notify=settingsChanged)
    def offlineOnly(self):
        return self._offline

    @Property(bool, notify=settingsChanged)
    def maskByDefault(self):
        return self._mask

    @Property(bool, notify=settingsChanged)
    def statsEnabled(self):
        return self._stats_enabled

    @Property(int, notify=settingsChanged)
    def clipboardSeconds(self):
        return self._clipboard_seconds

    @Slot(bool, bool, int, int, bool)
    def setPrivacy(self, offline, mask, clipboard_seconds, inactivity_seconds, stats_enabled):
        if offline != self._offline:
            self.invalidateBreach()
        self._offline, self._mask = offline, mask
        self._clipboard_seconds = max(0, min(300, clipboard_seconds))
        self._inactivity_seconds = max(0, min(3600, inactivity_seconds))
        if not stats_enabled:
            self._stats.clear()
            self.statsChanged.emit()
        self._stats_enabled = stats_enabled
        if self._clipboard_secret:
            if self._clipboard_seconds:
                self._clipboard_timer.start(self._clipboard_seconds * 1000)
            else:
                self._clipboard_timer.stop()
        self.touchActivity()
        self.settingsChanged.emit()

    @Slot()
    def touchActivity(self):
        if self._inactivity_seconds:
            self._inactivity_timer.start(self._inactivity_seconds * 1000)
        else:
            self._inactivity_timer.stop()

    @Slot()
    def invalidateBreach(self):
        self._revision += 1
        self._breach = self._empty_breach()
        self._policy = {}
        self.stateChanged.emit()

    @Slot()
    def invalidateAnalyzer(self):
        self._password = self._context = ""
        self._analysis = analyze_password("")
        self.invalidateBreach()
        self.touchActivity()

    @Slot(str, str, result="QVariantMap")
    def analyzePassword(self, password, context_csv=""):
        result = analyze_password(password, [s.strip() for s in context_csv.split(",") if s.strip()])
        if password and self._stats_enabled:
            self._stats.record(result["score"])
            self.statsChanged.emit()
        self.touchActivity()
        return result

    @Slot(str, str)
    def updateAnalyzer(self, password, context_csv):
        self.invalidateBreach()
        self._password, self._context = password[:8192], context_csv[:2048]
        self._analysis = self.analyzePassword(self._password, self._context)
        self.stateChanged.emit()

    @Slot()
    def checkBreach(self):
        if self._offline or not self._password or self._breach["status"] == "checking":
            return
        self._revision += 1
        revision = self._revision
        # Worker receives only hash parts, never plaintext. Results must match this input revision.
        digest = hashlib.sha1(self._password.encode("utf-8"), usedforsecurity=False).hexdigest().upper()
        self._breach = {
            "status": "checking",
            "found": False,
            "count": 0,
            "message": "Checking anonymized hash range...",
        }
        self._policy = {}
        self.stateChanged.emit()
        self.breachStarted.emit()
        threading.Thread(
            target=self._breach_worker, args=(revision, digest[:5], digest[5:]), daemon=True
        ).start()

    def _breach_worker(self, revision, prefix, suffix):
        result = check_hash_range(prefix, suffix).to_dict()
        try:
            self._workerFinished.emit(revision, result)
        except RuntimeError:
            pass  # The application may have closed before the request finished.

    @Slot(int, "QVariantMap")
    def _accept_breach(self, revision, result):
        if revision != self._revision or self._offline:
            return
        self._breach = result
        self._policy = {}
        if result["found"] and self._stats_enabled:
            self._stats.breaches += 1
            self.statsChanged.emit()
        self.stateChanged.emit()
        self.breachFinished.emit(result)

    @Slot(str, result="QVariantMap")
    def generatorPreset(self, name):
        return GENERATOR_PRESETS.get(name, {})

    @Slot(str, result="QVariantMap")
    def policyPreset(self, name):
        return POLICY_PRESETS.get(name, {})

    @Slot("QVariantMap", result="QVariantMap")
    def generatePassword(self, options):
        try:
            self.touchActivity()
            return generate_password(**options)
        except (ValueError, TypeError):
            self.toastRequested.emit(
                "Check generator settings", "Select usable categories and review exclusions."
            )
            return {}

    @Slot("QVariantMap", result="QVariantMap")
    def generatePassphrase(self, options):
        try:
            self.touchActivity()
            return generate_passphrase(**options)
        except (ValueError, TypeError):
            self.toastRequested.emit("Check passphrase settings", "Review your configuration.")
            return {}

    @Slot("QVariantMap")
    def evaluatePolicy(self, config):
        self._policy = evaluate_policy(self._password, self._analysis, config, self._breach)
        self.stateChanged.emit()

    @Slot()
    def invalidatePolicy(self):
        self._policy = {}
        self.stateChanged.emit()

    @Slot(QUrl, str, result=bool)
    def exportReport(self, url, kind):
        if not self._password or kind not in {"json", "pdf"} or not url.isLocalFile():
            return False
        path = Path(url.toLocalFile())
        if path.suffix.lower() != "." + kind:
            self.toastRequested.emit("Check filename", "Use the selected report file extension.")
            return False
        try:
            report = sanitized_report(self._analysis, self._breach, self._policy)
            (write_json if kind == "json" else write_pdf)(path, report)
        except (OSError, ValueError):
            self.toastRequested.emit("Export failed", "Choose a writable file location and try again.")
            return False
        self.toastRequested.emit("Sanitized report exported", "Password and personal context are excluded.")
        return True

    @Slot(str)
    def copySecure(self, text):
        if not text:
            return
        QGuiApplication.clipboard().setText(text)
        self._clipboard_secret = text
        self._clipboard_timer.stop()
        if self._clipboard_seconds:
            self._clipboard_timer.start(self._clipboard_seconds * 1000)
        self.toastRequested.emit("Copied", f"Auto-clear: {self._clipboard_seconds}s (0 = off).")
        self.touchActivity()

    @Slot()
    def clearSensitiveClipboard(self):
        self._clear_clipboard_if_matching()

    def _clear_clipboard_if_matching(self):
        clipboard = QGuiApplication.clipboard()
        if self._clipboard_secret and clipboard.text() == self._clipboard_secret:
            clipboard.clear()
        self._clipboard_secret = ""
        self._clipboard_timer.stop()

    @Slot()
    def clearSensitiveData(self):
        self._inactivity_timer.stop()
        self.invalidateAnalyzer()
        self._inactivity_timer.stop()
        self._clear_clipboard_if_matching()
        self._stats.clear()
        self.statsChanged.emit()
        self.sensitiveCleared.emit()
        self._inactivity_timer.stop()
        self.toastRequested.emit(
            "Sensitive data cleared", "Inputs, results, reveal states and matching clipboard cleared."
        )
