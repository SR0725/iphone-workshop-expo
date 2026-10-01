#!/bin/bash
# 手機和電腦連不上時的備用方式：透過 Expo 的公開通道連線。
cd "$(dirname "$0")" || exit 1
NODE_VERSION=22.23.3
ARCH=$(uname -m)
[ "$ARCH" = "x86_64" ] && ARCH=x64
PORTABLE_NODE="$HOME/.rayworkshop/node-v$NODE_VERSION-darwin-$ARCH"
[ -x "$PORTABLE_NODE/bin/node" ] && export PATH="$PORTABLE_NODE/bin:$PATH"

pause_and_exit() { echo; read -n 1 -s -r -p "按任意鍵關閉這個視窗"; echo; exit "$1"; }

if ! command -v node >/dev/null 2>&1; then
  echo "找不到 Node.js。請先在 Codex 貼上講義裡的「環境準備提示詞」。"
  pause_and_exit 1
fi
if [ ! -f node_modules/expo/package.json ]; then
  echo "第一次啟動：正在安裝專案套件，請稍等幾分鐘……"
  npm ci || { echo "安裝失敗。把這個視窗的文字全部複製給 Codex，請它找原因。"; pause_and_exit 1; }
fi
if [ ! -f node_modules/@expo/ngrok/package.json ]; then
  echo "第一次使用備用連線：安裝通道工具 @expo/ngrok……"
  npm install --no-save --no-audit --no-fund "@expo/ngrok@^4.1.0" || { echo "安裝失敗。把這個視窗的文字全部複製給 Codex，請它找原因。"; pause_and_exit 1; }
fi
if [ -z "$WORKSHOP_SKIP_LOGIN" ] && ! npx expo whoami >/dev/null 2>&1; then
  echo
  echo "=========================================================="
  echo " iPhone 的 Expo Go 規定：電腦和手機要登入同一個 Expo 帳號。"
  echo " 瀏覽器會打開 Expo 登入頁。還沒有帳號就點 Sign up 免費註冊。"
  echo " 登入完成後回到這個視窗。"
  echo "=========================================================="
  npx expo login --browser || { echo "Expo 登入沒有完成。可以再雙擊一次這個檔案重試，或請助教協助。"; pause_and_exit 1; }
fi
echo
echo "=========================================================="
echo " 備用連線：透過 Expo 的公開通道，手機不用和電腦在同一個網路。"
echo " 速度比較慢。保持這個視窗開著，用 iPhone 相機掃 QR Code。"
echo " 用完請按 Control+C 或關掉這個視窗。"
if [ -z "$WORKSHOP_SKIP_LOGIN" ]; then
  echo " 手機的 Expo Go 要登入這個 Expo 帳號：$(npx expo whoami 2>/dev/null)"
fi
echo "=========================================================="
echo
npx expo start --tunnel --go
echo
echo "備用連線已停止。若不是你自己停止的，把這個視窗的文字複製給 Codex 或助教。"
pause_and_exit 0
