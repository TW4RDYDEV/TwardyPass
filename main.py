from __future__ import annotations

import sys
from pathlib import Path

from PySide6.QtCore import QTimer, QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

from app.bridge import AppBridge
from app.fonts import configure_fonts
from app.version import VERSION


def main() -> int:
    # TwardyPass uses custom QML controls.
    # The Windows native Qt style does not support full control customization,
    # so use Qt's Basic style as the foundation for our own design.
    QQuickStyle.setStyle("Basic")

    app = QGuiApplication(sys.argv)
    configure_fonts(app)
    app.setApplicationName("TwardyPass")
    app.setOrganizationName("TW4RDYDEV / TWARDY.exe")
    app.setApplicationVersion(VERSION)
    app.setWindowIcon(QIcon(str(Path(__file__).resolve().parent / "assets" / "TwardyPass-app-icon.ico")))

    engine = QQmlApplicationEngine()

    bridge = AppBridge()
    engine.rootContext().setContextProperty("bridge", bridge)

    qml_file = Path(__file__).resolve().parent / "app" / "ui" / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_file)))

    if not engine.rootObjects():
        return 1

    if "--smoke-test" in sys.argv:
        engine.rootObjects()[0].setProperty("visible", False)
        QTimer.singleShot(1500, app.quit)

    app.aboutToQuit.connect(bridge.clearSensitiveData)
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
