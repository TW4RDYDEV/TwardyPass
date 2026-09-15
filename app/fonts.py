"""Use installed Windows system fonts when Qt's headless backend cannot enumerate them."""

import os
from pathlib import Path

from PySide6.QtGui import QFont, QFontDatabase


def configure_fonts(app):
    if os.name == "nt":
        folder = Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts"
        os.environ.setdefault("QT_QPA_FONTDIR", str(folder))
        for name in ("segoeui.ttf", "segoeuib.ttf", "seguisb.ttf", "consola.ttf"):
            path = folder / name
            if path.is_file():
                QFontDatabase.addApplicationFont(str(path))
    app.setFont(QFont("Segoe UI" if os.name == "nt" else "sans-serif", 10))
