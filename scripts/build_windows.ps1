param([string]$Python = "python", [switch]$SkipInstall)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
if (-not $SkipInstall) {
    & $Python -m pip install -r requirements-dev.txt -c constraints.txt
    if ($LASTEXITCODE -ne 0) { throw "Dependency installation failed." }
}
& $Python -m ruff check .
if ($LASTEXITCODE -ne 0) { throw "Ruff failed." }
$PytestTemp = Join-Path $PSScriptRoot "..\.pytest-temp"

if (Test-Path $PytestTemp) {
    Remove-Item -Recurse -Force $PytestTemp
}

& $Python -m pytest -v --basetemp="$PytestTemp"

if ($LASTEXITCODE -ne 0) {
    throw "Tests failed."
}
& $Python -m PyInstaller --noconfirm --clean TwardyPass.spec
if ($LASTEXITCODE -ne 0) { throw "Windows build failed." }
$executable = Join-Path (Get-Location) "dist/TwardyPass/TwardyPass.exe"
$smokeProcess = Start-Process -FilePath $executable -ArgumentList "--smoke-test" -WindowStyle Hidden -PassThru
if (-not $smokeProcess.WaitForExit(30000)) {
    Stop-Process -Id $smokeProcess.Id -ErrorAction SilentlyContinue
    throw "Packaged startup smoke check timed out."
}
if ($smokeProcess.ExitCode -ne 0) { throw "Packaged startup smoke check failed." }
Copy-Item -LiteralPath LICENSE -Destination dist/TwardyPass/LICENSE.txt
Write-Host "Portable build: dist/TwardyPass/TwardyPass.exe"
Write-Host "Distribute the entire TwardyPass folder, including _internal."
