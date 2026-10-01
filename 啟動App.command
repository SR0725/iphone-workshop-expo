#!/bin/bash
# 雙擊這個檔案啟動開發伺服器，用 iPhone 的 Expo Go 預覽。
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
  npm ci || { echo "套件安裝失敗。把這個視窗的文字全部複製給 Codex，請它找原因。"; pause_and_exit 1; }
fi
echo
echo "=========================================================="
echo " 保持這個視窗開著。用 iPhone 相機掃下面的 QR Code，"
echo " 在 Expo Go 開啟。要停止請按 Control+C。"
echo "=========================================================="
echo
npx expo start --go
echo
echo "開發伺服器已停止。若不是你自己停止的，把這個視窗的文字複製給 Codex。"
pause_and_exit 0
