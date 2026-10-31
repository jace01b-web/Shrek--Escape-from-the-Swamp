@echo off
start "Site Server" /min powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1" -Root "%~dp0." -Port 8137 -BasePath "/415567/paf4kzlxuj49ndhs69nqofdkjvy7lzr3/" -Proxy "https://app-415567.games.s3.yandex.net/415567/paf4kzlxuj49ndhs69nqofdkjvy7lzr3/"
timeout /t 2 >nul
start  http://localhost:8137/
