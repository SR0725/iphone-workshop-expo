@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title Small Things - Expo Go
set "NODE_VERSION=22.23.3"
set "NODE_ARCH=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "NODE_ARCH=arm64"
set "PORTABLE_NODE=%LOCALAPPDATA%\RayWorkshop\node-v%NODE_VERSION%-win-%NODE_ARCH%"
if exist "%PORTABLE_NODE%\node.exe" set "PATH=%PORTABLE_NODE%;%PATH%"
where node >nul 2>nul
if errorlevel 1 goto :no_node
if not exist "node_modules\expo\package.json" goto :install
goto :start

:install
echo.
echo 第一次啟動：正在安裝專案套件，請稍等幾分鐘……
call npm.cmd ci
if errorlevel 1 goto :install_failed
goto :start

:start
echo.
echo ==========================================================
echo  保持這個視窗開著。用 iPhone 相機掃下面的 QR Code，
echo  在 Expo Go 開啟。要停止請按 Ctrl+C。
echo ==========================================================
echo.
call npm.cmd run start -- --go
echo.
echo 開發伺服器已停止。若不是你自己停止的，把這個視窗的文字複製給 Codex。
pause
exit /b 0

:no_node
echo.
echo 找不到 Node.js。請先在 Codex 貼上講義裡的「環境準備提示詞」。
pause
exit /b 1

:install_failed
echo.
echo 套件安裝失敗。把這個視窗的文字全部複製給 Codex，請它找原因。
pause
exit /b 1
