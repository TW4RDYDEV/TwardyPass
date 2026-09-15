# -*- mode: python ; coding: utf-8 -*-
# Portable Windows folder build. Metadata comes from app/version.py.
from pathlib import Path
import runpy
from PyInstaller.utils.win32.versioninfo import (
    FixedFileInfo, StringFileInfo, StringStruct, StringTable,
    VarFileInfo, VarStruct, VSVersionInfo,
)

root = Path(SPECPATH)
version = runpy.run_path(str(root / "app" / "version.py"))["VERSION"]
parts = tuple(int(n) for n in version.split(".")) + (0,)
version_info = VSVersionInfo(
    ffi=FixedFileInfo(filevers=parts, prodvers=parts, mask=0x3F, flags=0,
                      OS=0x40004, fileType=1, subtype=0, date=(0, 0)),
    kids=[StringFileInfo([StringTable("040904B0", [
        StringStruct("CompanyName", "TW4RDYDEV / TWARDY.exe"),
        StringStruct("FileDescription", "TwardyPass Password Security Workbench"),
        StringStruct("FileVersion", version), StringStruct("ProductVersion", version),
        StringStruct("ProductName", "TwardyPass"),
        StringStruct("OriginalFilename", "TwardyPass.exe"),
        StringStruct("LegalCopyright", "Copyright (c) 2026 Filip Twardowski. All rights reserved."),
    ])]), VarFileInfo([VarStruct("Translation", [1033, 1200])])],
)
a = Analysis(
    [str(root / "main.py")], pathex=[str(root)],
    datas=[(str(root / "app" / "ui"), "app/ui"), (str(root / "assets"), "assets"),
           (str(root / "LICENSE"), ".")],
    hiddenimports=["PySide6.QtQuick", "PySide6.QtQuickControls2", "PySide6.QtNetwork"],
    excludes=["tkinter", "pytest", "pypdf"],
)
# Qt's Windows build requires the operating system's unversioned ICU ABI.
# A developer PATH may contain an unrelated ICU DLL (e.g. from document tools).
# Do not shadow the Windows system DLL with that incompatible implementation.
a.binaries = [entry for entry in a.binaries if Path(entry[0]).name.lower() != "icuuc.dll"]
pyz = PYZ(a.pure)
exe = EXE(pyz, a.scripts, [], exclude_binaries=True, name="TwardyPass", console=False,
          debug=False, upx=False, icon=str(root / "assets" / "TwardyPass-app-icon.ico"),
          version=version_info)
coll = COLLECT(exe, a.binaries, a.datas, strip=False, upx=False, name="TwardyPass")
