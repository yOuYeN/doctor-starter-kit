# Claude Code 簡報製作技能包

> 由 You-Yan Chen 整理提供。適用於 macOS 與 Windows（WSL2），完全免費使用（需有 Claude 帳號）。

---

## 這個技能包能做什麼？

安裝完成後，你可以用 Claude Code 從參考書 PDF 製作學術演講投影片：

- 自動讀取 PDF 目錄、提取章節內容
- 自動截取書中圖片並嵌入對應投影片
- 生成 PowerPoint (.pptx) 或 Marp 投影片
- 支援 5 種風格、4 種字型選擇
- 以白話中文溝通，無需學任何指令

---

## 安裝前準備

### 需要的工具

1. **Node.js**（用來安裝 Claude Code）
   → 前往 [nodejs.org](https://nodejs.org) 下載 LTS 版本

2. **Claude Code CLI**
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

3. **Claude 帳號**：[claude.ai](https://claude.ai)（免費版可用，Pro 版效果更好）

---

## 安裝步驟

1. 將 `doctor-starter-kit` 資料夾放到桌面
2. 開啟終端機（Terminal.app，在「應用程式 > 工具程式」）
3. 執行安裝腳本：

```bash
cd ~/Desktop/doctor-starter-kit
bash install.sh
```

安裝完成後，工作資料夾會建立在 `~/Documents/claude-slides/`

---

## 開始使用

安裝完成後，關閉並重新開啟終端機，然後輸入：

```bash
slides
```

這個指令會自動進入工作資料夾並以**無閃爍模式**啟動 Claude Code（捲動順暢、支援滑鼠選取、記憶體效率更好）。

> 若還沒重新開啟終端機，也可以手動輸入：
> ```bash
> cd ~/Documents/claude-slides && CLAUDE_CODE_NO_FLICKER=1 claude
> ```

Claude 啟動後會主動問你幾個問題：
- PDF 放在哪裡
- 演講時間與用途
- 要整本書還是特定章節
- 有無特別想強調的內容
- 投影片語言

接著會讓你選風格、字型、輸出格式，然後開始製作。

---

## 製作過程

Claude 會逐章生成，每章完成後給你以下選項：

| 你想做的事 | 怎麼說 |
|:---|:---|
| 繼續下一章 | 「繼續做第 X 章」 |
| 修改某張投影片 | 「第 X 章第 N 張太多字，精簡成 3 個重點」 |
| 加入特定概念 | 「我想在第 X 章加入 ____ 的說明」 |
| 合併成一個檔案 | 「把所有章節合併成一個 pptx」 |

---

## Windows 使用者

最簡單的方式是安裝 **WSL2**（Windows Subsystem for Linux）：

1. 以系統管理員身分開啟 PowerShell，輸入：
   ```powershell
   wsl --install
   ```
2. 重新開機後，開啟「Ubuntu」（從開始功能表搜尋）
3. 後續步驟與 Mac 完全相同，`install.sh` 可直接使用

> WSL2 安裝後，所有功能（自動讀 PDF、截圖嵌入、生成 .pptx）均可正常運作。

---

## 遇到問題？

- 把錯誤訊息直接貼給 Claude，它會自己修正後繼續
- 聯絡 You-Yan Chen

---

*整理日期：2026-04*
