@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title Small Things - Expo Go (tunnel)
set "NODE_VERSION=22.23.3"
set "NODE_ARCH=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "NODE_ARCH=arm64"
set "PORTABLE_NODE=%LOCALAPPDATA%\RayWorkshop\node-v%NODE_VERSION%-win-%NODE_ARCH%"
if exist "%PORTABLE_NODE%\node.exe" set "PATH=%PORTABLE_NODE%;%PATH%"
where node >nul 2>nul
if errorlevel 1 goto :no_node
if not exist "node_modules\expo\package.json" goto :install
goto :ngrok

:install
echo.
echo 第一次啟動：正在安裝專案套件，請稍等幾分鐘……
call npm.cmd ci
if errorlevel 1 goto :install_failed
goto :ngrok

:ngrok
if exist "node_modules\@expo\ngrok\package.json" goto :account
echo.
echo 第一次使用備用連線：安裝通道工具 @expo/ngrok……
call npm.cmd install --no-save --no-audit --no-fund @expo/ngrok@^4.1.0
if errorlevel 1 goto :install_failed
goto :account

:account
if defined WORKSHOP_SKIP_LOGIN goto :serve
call npx.cmd expo whoami >nul 2>nul
if not errorlevel 1 goto :serve
echo.
echo ==========================================================
echo  iPhone 的 Expo Go 規定：電腦和手機要登入同一個 Expo 帳號。
echo  瀏覽器會打開 Expo 登入頁。還沒有帳號就點 Sign up 免費註冊。
echo  登入完成後回到這個視窗。
echo ==========================================================
call npx.cmd expo login --browser
if errorlevel 1 goto :login_failed
goto :serve

:serve
echo.
echo ==========================================================
echo  備用連線：透過 Expo 的公開通道，手機不用和電腦在同一個網路。
echo  速度比較慢。保持這個視窗開著，用 iPhone 相機掃 QR Code。
echo  用完請按 Ctrl+C 或關掉這個視窗。
echo  手機的 Expo Go 要登入這個 Expo 帳號：
if not defined WORKSHOP_SKIP_LOGIN call npx.cmd expo whoami
echo ==========================================================
echo.
call npx.cmd expo start --tunnel --go
echo.
echo 備用連線已停止。若不是你自己停止的，把這個視窗的文字複製給 Codex 或助教。
pause
exit /b 0

:no_node
echo.
echo 找不到 Node.js。請先在 Codex 貼上講義裡的「環境準備提示詞」。
pause
exit /b 1

:install_failed
echo.
echo 安裝失敗。把這個視窗的文字全部複製給 Codex，請它找原因。
pause
exit /b 1

:login_failed
echo.
echo Expo 登入沒有完成。可以再雙擊一次這個檔案重試，或請助教協助。
pause
exit /b 1
