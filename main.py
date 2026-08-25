from __future__ import annotations

import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

from app.bridge import AppBridge


def main() -> int:
    # TwardyPass uses custom QML controls.
    # The Windows native Qt style does not support full control customization,
    # so use Qt's Basic style as the foundation for our own design.
    QQuickStyle.setStyle("Basic")

    app = QGuiApplication(sys.argv)
    app.setApplicationName("TwardyPass")
    app.setOrganizationName("TwardyPass")

    engine = QQmlApplicationEngine()

    bridge = AppBridge()
    engine.rootContext().setContextProperty("bridge", bridge)

    qml_file = Path(__file__).resolve().parent / "app" / "ui" / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_file)))

    if not engine.rootObjects():
        return 1

    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
