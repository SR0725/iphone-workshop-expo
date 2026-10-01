# 給 Codex 的專案規則

這是「iPhone App Vibe Coding 工作坊」的學員專案。使用者不是工程師，請用繁體中文、白話、短句回覆；需要他操作時，一次只交代一個步驟。

## 專案是什麼
- Expo SDK 57 + React Native 的手機 App，在 iPhone 的 Expo Go 裡預覽。
- 需求在 `PRD.md`，畫面參考在 `design/`。設計稿（含 Stitch 匯出的 HTML）只是視覺參考，畫面一律用 React Native 元件重新實作，不可把 HTML 貼進來。
- 本機保存用專案已安裝的 `@react-native-async-storage/async-storage`。
- 不做登入、付款、後端、雲端資料庫、推播、多人同步、AI API。

## 不能動的東西
- 不升級或降級 Expo、React Native、React；不執行 `npm audit fix`、`npm update`、`npx expo install --fix`。
- 不新增需要原生程式碼、Expo Go 不支援的套件。真的需要新套件時，先說明原因和影響，等使用者同意。
- 不刪除、不重建、不重置使用者的專案或資料。要救援就另開資料夾。
- 不關閉防火牆或防毒、不繞過公司管理政策、不要求密碼、不付費。

## 指令與環境
- Windows 一律用 `npm.cmd`、`npx.cmd`，不要修改 PowerShell 執行原則。
- 如果找不到 `node`，先找工作坊安裝的免安裝版 Node：
  - Windows：`%LOCALAPPDATA%\RayWorkshop\node-v22.23.3-win-x64`（ARM 電腦是 `-win-arm64`）
  - Mac：`~/.rayworkshop/node-v22.23.3-darwin-arm64`（Intel Mac 是 `-darwin-x64`）的 `bin`
  - 只在你執行的指令裡暫時加到 PATH，不改系統或全域設定。
- 使用者用雙擊 `啟動App.cmd`（Windows）或 `啟動App.command`（Mac）啟動開發伺服器。它開著時，你改完程式，Expo Go 會自動更新。
- 不要另外常駐一個開發伺服器搶 8081 埠。需要自己驗證時，用下面的檢查；若真的要啟動伺服器，換別的埠，驗證完就關掉。

## 每次改完都要驗證
1. `npx tsc --noEmit`（Windows：`npx.cmd tsc --noEmit`）
2. `npx expo export --platform ios --output-dir .verify/ios`：確認 iPhone 用的程式能打包成功。
3. 告訴使用者在手機上要按哪裡、預期看到什麼。

打包成功、電腦瀏覽器能跑，都不等於 iPhone 已驗收；要等使用者回報手機畫面才算。Expo Go 裡的作品是開發預覽，不是獨立安裝的 App，也不是上架。

## 做事方式
- 新功能先用白話說明你的理解與計畫（三步以內），使用者確認再動手。一次只做一件事。
- 修錯時先找原因，再做最小修改，修完重跑原本出錯的步驟，並確認資料保存仍正常。
- 功能確認可用後建立「完成點」：
  - 有 Git：只在這個專案設定作者（用使用者自己提供的名字），`git add` 前先確認沒有金鑰或私人資料，再 commit。不要 push。
  - 沒有 Git：把專案壓縮成 `.checkpoints/日期時間-說明.zip`，排除 `node_modules`、`.expo`、`.verify`、`dist`、`.checkpoints`。
  - Mac 沒有開發者工具時不要呼叫 `git`，以免跳出安裝視窗（先用 `xcode-select -p` 檢查）。
