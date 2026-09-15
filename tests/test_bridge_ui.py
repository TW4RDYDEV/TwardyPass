from pathlib import Path
from unittest.mock import Mock

from PySide6.QtCore import QObject, Qt, QUrl, qInstallMessageHandler
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickItem
from PySide6.QtTest import QSignalSpy, QTest

from app.bridge import AppBridge

DUMMY = "DUMMY_ONLY_FOR_QT_TEST_8274!"


def find_visual(item: QQuickItem, name):
    if item.objectName() == name:
        return item
    for child in item.childItems():
        match = find_visual(child, name)
        if match is not None:
            return match
    return None


def test_bridge_revision_offline_and_cleanup(qt_app, monkeypatch):
    bridge = AppBridge()
    spy = QSignalSpy(bridge.breachFinished)
    bridge.setPrivacy(False, True, 30, 0, True)
    bridge.updateAnalyzer(DUMMY, "DUMMY")
    revision = bridge._revision
    bridge.copySecure(DUMMY)
    bridge.clearSensitiveData()
    bridge._accept_breach(revision, {"status": "compromised", "found": True, "count": 1})
    assert spy.count() == 0
    assert bridge.analysis["length"] == 0
    assert bridge.breach["status"] == "idle"
    assert not bridge._password and not bridge._context and not bridge._clipboard_secret
    assert qt_app.clipboard().text() == ""
    assert bridge.statistics["analyzed"] == 0
    assert not bridge._clipboard_timer.isActive()
    bridge.updateAnalyzer(DUMMY, "")
    revision = bridge._revision
    bridge.invalidateAnalyzer()
    bridge._accept_breach(revision, {"status": "clear", "found": False, "count": 0})
    assert bridge.breach["status"] == "idle"
    bridge.setPrivacy(True, True, 30, 0, False)
    worker = Mock()
    monkeypatch.setattr(bridge, "_breach_worker", worker)
    bridge.updateAnalyzer(DUMMY, "")
    bridge.checkBreach()
    worker.assert_not_called()
    bridge.clearSensitiveData()


def test_clipboard_preserves_unrelated_data_and_timeout(qt_app):
    bridge = AppBridge()
    bridge.copySecure(DUMMY)
    qt_app.clipboard().setText("UNRELATED_DUMMY_CLIPBOARD")
    bridge.clearSensitiveClipboard()
    assert qt_app.clipboard().text() == "UNRELATED_DUMMY_CLIPBOARD"
    bridge.copySecure(DUMMY)
    bridge._clipboard_timer.start(10)
    QTest.qWait(50)
    assert qt_app.clipboard().text() == ""
    bridge.setPrivacy(False, True, 30, 1, False)
    bridge.updateAnalyzer(DUMMY, "")
    bridge._inactivity_timer.start(10)
    QTest.qWait(50)
    assert bridge.analysis["length"] == 0
    bridge.clearSensitiveData()


def test_qml_pages_long_inputs_and_panic(qt_app):
    messages = []
    old_handler = qInstallMessageHandler(lambda kind, ctx, msg: messages.append(msg))
    engine = QQmlApplicationEngine()
    bridge = AppBridge()
    engine.rootContext().setContextProperty("bridge", bridge)
    try:
        engine.load(QUrl.fromLocalFile(str(Path("app/ui/Main.qml").resolve())))
        assert engine.rootObjects(), messages
        window = engine.rootObjects()[0]
        window.show()
        QTest.qWait(100)
        password = window.findChild(QObject, "analyzerPassword")
        context = window.findChild(QObject, "analyzerContext")
        password.setProperty("text", ("DUMMY-TEST-8274!" * 600)[:8192])
        context.setProperty("text", "DUMMY")
        QTest.qWait(500)
        assert bridge.analysis["length"] == 8192
        assert isinstance(bridge.analysis["guesses"], str)
        password.setProperty("text", "🔒" * 8192)
        QTest.qWait(500)
        assert bridge.analysis["length"] == 8192
        for i, name in enumerate(["A", "B", "C"]):
            window.findChild(QObject, "compare" + name).setProperty("text", DUMMY * (i + 1))
        generated = window.findChild(QObject, "generatedPassword")
        generated.setProperty("text", DUMMY)
        password.setProperty("reveal", True)
        for width, height in [(1180, 720), (1440, 900), (1920, 1080), (2560, 1440)]:
            window.resize(width, height)
            for page in range(6):
                window.setProperty("currentPage", page)
                QTest.qWait(30)
            sizes = [window.findChild(QObject, "candidate" + name).property("width") for name in "ABC"]
            assert max(sizes) - min(sizes) < 0.01
            cells = [find_visual(window.contentItem(), "matrixCell0_" + str(i)) for i in range(3)]
            assert cells[0].property("width") > 100
            assert max(c.property("width") for c in cells) - min(c.property("width") for c in cells) < 0.01
        # Exercise the actual privacy button through the Qt metaobject signal.
        window.setProperty("currentPage", 4)
        window.findChild(QObject, "privacyClearButton").clicked.emit()
        QTest.qWait(250)
        assert password.property("text") == "" and context.property("text") == ""
        assert generated.property("text") == "" and not password.property("reveal")
        assert all(window.findChild(QObject, "compare" + name).property("text") == "" for name in "ABC")
        assert bridge.analysis["length"] == 0
        # Refill and exercise the real application shortcut.
        window.setProperty("currentPage", 0)
        password.setProperty("text", DUMMY)
        QTest.qWait(250)
        window.requestActivate()
        QTest.qWait(30)
        QTest.keyClick(window, Qt.Key_X, Qt.ControlModifier | Qt.ShiftModifier)
        QTest.qWait(250)
        assert password.property("text") == ""
        assert bridge.analysis["length"] == 0
        radar = window.findChild(QObject, "securityRadar")
        assert radar.property("width") >= 190
        serious = [
            m
            for m in messages
            if any(
                s in m.lower()
                for s in (
                    "error",
                    "warning",
                    "binding loop",
                    "unable",
                    "invalid",
                    "not a function",
                    "cannot assign",
                )
            )
        ]
        assert not serious, serious
        window.close()
    finally:
        engine.deleteLater()
        qt_app.processEvents()
        qInstallMessageHandler(old_handler)
