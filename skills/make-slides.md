# Skill: make-slides
# 從 PDF 教科書製作學術演講投影片

## 觸發條件
使用者說「做投影片」「製作簡報」「make slides」「把這本書做成 PPT」時啟用此 skill。

---

## Step 0｜Session 開始時蒐集資訊（一次問完）

```
你好！我是你的投影片製作助手。請回答以下問題（用中文回答就好）：

1. PDF 放在哪裡？（貼上完整路徑）
2. 演講時間多長？用途是什麼？（例：一小時教學課、接實作）
3. 要涵蓋整本書還是特定章節？
4. 有沒有特別想加的概念或技術？（用白話說，我去書裡找）
5. 投影片語言：中文 / 英文 / 中英混合？
```

---

## Step 1｜讀取 PDF 結構

```python
import fitz
doc = fitz.open("PDF路徑")
print(f"總頁數：{len(doc)}")
toc = doc.get_toc()
for item in toc: print(item)
```

若無內嵌目錄：掃描前 20 頁找章節標題。

---

## Step 2｜詢問工作流程偏好

問使用者以下三個選擇（用選項清單呈現）：

### 問題 A：是否先審核內容？
- **【A1】先給我看每張投影片的大綱（推薦）**
  我先列出每一張投影片的標題、要點、圖片來源，你確認後再生成。
- **【A2】直接生成，不用先看大綱**
  我直接產出完整投影片。

### 問題 B：輸出格式？
- **【B1】本地 PPTX（推薦，可自動嵌入 PDF 圖片）**
  用 python-pptx 在你的電腦直接產生 .pptx 檔案，PDF 裡的圖片自動截取並嵌入。
- **【B2】Claude Design 用的 Marp 程式碼**
  產生 Marp markdown，你複製貼到 claude.ai 或直接用 `marp --pptx` 轉檔。
  ⚠️ 圖片需手動插入，因為 Claude Design 無法讀取你本地的 PDF 圖片。

### 問題 C：投影片風格？

| 編號 | 風格名稱 | 說明 |
|:---:|:---|:---|
| 1 | **Morandi Soft**（莫蘭迪柔和）| 米白底、灰藍/灰綠/灰粉莫蘭迪配色，學術優雅 |
| 2 | **Navy Academic**（深藍學術）| 深海軍藍 header、白色內容區，清晰專業 |
| 3 | **Dark Professional**（深色專業）| 深灰黑底、淡色文字，高對比 |
| 4 | **Warm Clinical**（暖色臨床）| 米白底、橄欖綠/磚紅 accent，溫暖醫療感 |
| 5 | **Pure Minimal**（極簡白）| 全白底、黑色文字、單一 accent 色，最簡潔 |

### 問題 D：字型？

| 編號 | 字型組合 | 效果 |
|:---:|:---|:---|
| 1 | **Noto Sans TC + Noto Sans**（推薦）| 正體中文完整支援，跨平台一致 |
| 2 | **PingFang TC + Helvetica Neue** | macOS 原生，顯示效果最好（但非跨平台）|
| 3 | **Source Han Sans TC + Source Han Sans** | 思源黑體，Adobe 出品，優雅 |
| 4 | **Microsoft JhengHei + Calibri** | Windows 最相容，Office 環境佳 |

---

## Step 3｜生成大綱（若選 A1）

每張投影片輸出格式：
```
### S[章]-[頁]｜[標題]
- 要點 1
- 要點 2
- 圖片：Fig. X-X（原書 p.XX）或「無圖」
- 出處：Ch.X, p.XX–XX, [節名]
```

等使用者確認後進入 Step 4。

---

## Step 4｜生成投影片

### 選 B1（本地 PPTX）

```python
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
import fitz
from PIL import Image
import io, os

# 1. 依選擇的風格套用配色（見配色表）
# 2. 依選擇的字型設定
# 3. 逐章生成，每章存一個 .pptx 到 output/
# 4. 圖片：render PDF 頁面為 PNG（白底），嵌入對應投影片
# 5. 圖片下方加標註：Fig. X-X — [原書圖說]
```

**每完成一章告訴使用者：**
```
✓ Ch.X 完成 → output/ChXX_主題.pptx
下一步：
• 「繼續 Ch.X+1」
• 「第 X 章第 N 張修改：[說明]」
• 「我要加 [概念] 進第 X 章」
• 「把所有章節合併成一個 pptx」
```

### 選 B2（Marp code）

產生完整 Marp markdown，包含：
- CSS 樣式（依選定風格和字型）
- 每張投影片的 HTML/Markdown 內容
- 圖片位置用 `<!-- INSERT: Fig. X-X -->` 佔位

---

## Step 5｜自定義需求處理

使用者說「我想加 X」時：
1. 在 PDF 搜尋關鍵字
2. 摘要找到的內容，問「這是你要的嗎？」
3. 確認後插入對應章節
4. 找不到 → 問使用者提供說明，直接寫補充投影片

---

## 配色表

### Morandi Soft
```python
BG    = RGBColor(0xF4, 0xEF, 0xE8)  # 米白底
HDR   = RGBColor(0x7A, 0x95, 0xAD)  # 灰藍 header → 白字
SAGE  = RGBColor(0x8A, 0xA8, 0x8A)  # 灰綠 → 白字
TAN   = RGBColor(0xC4, 0xAA, 0x82)  # 灰棕 → 深字
ROSE  = RGBColor(0xC4, 0xA4, 0xA8)  # 灰粉 → 白字
LAV   = RGBColor(0xA0, 0x98, 0xB8)  # 灰紫 → 白字
LIGHT = RGBColor(0xE8, 0xE2, 0xD8)  # 淺框底 → 深字
TEXT  = RGBColor(0x3D, 0x38, 0x30)  # 主文深色
```

### Navy Academic
```python
BG    = RGBColor(0xFF, 0xFF, 0xFF)
HDR   = RGBColor(0x1B, 0x3A, 0x5C)  # 深海軍藍 → 白字
ACC1  = RGBColor(0x2A, 0x52, 0x98)  # 中藍 → 白字
ACC2  = RGBColor(0xE0, 0xE8, 0xF0)  # 淺藍框 → 深字
TEXT  = RGBColor(0x1A, 0x1A, 0x2E)
```

### Dark Professional
```python
BG    = RGBColor(0x1A, 0x1A, 0x2E)
HDR   = RGBColor(0x16, 0x21, 0x3E)
ACC1  = RGBColor(0x0F, 0x3F, 0x6B)  # 深藍 → 淺字
LIGHT = RGBColor(0x2D, 0x3A, 0x4E)  # 框底 → 淺字
TEXT  = RGBColor(0xE0, 0xE6, 0xF0)
```

### Warm Clinical
```python
BG    = RGBColor(0xFA, 0xF7, 0xF2)
HDR   = RGBColor(0x5C, 0x6B, 0x3D)  # 橄欖綠 → 白字
ACC1  = RGBColor(0x8B, 0x4A, 0x3A)  # 磚紅 → 白字
LIGHT = RGBColor(0xEE, 0xE8, 0xDF)  # 框底 → 深字
TEXT  = RGBColor(0x2D, 0x2A, 0x24)
```

### Pure Minimal
```python
BG    = RGBColor(0xFF, 0xFF, 0xFF)
HDR   = RGBColor(0x22, 0x22, 0x22)  # 近黑 → 白字
ACC1  = RGBColor(0x4A, 0x7C, 0xC4)  # 單一 accent 藍
LIGHT = RGBColor(0xF5, 0xF5, 0xF5)  # 框底 → 深字
TEXT  = RGBColor(0x22, 0x22, 0x22)
```

---

## 圖片處理規則

1. **截取方式**：render PDF 頁面為 PNG，composite 到白底（不用 extract_image，避免黑底問題）
2. **解析度**：`fitz.Matrix(2.5, 2.5)`
3. **標註**：每張圖片下方加 `Fig. X-X — [書中圖說摘要]`，字體用斜體、小字、accent 色
4. **大小**：圖片不超過投影片寬度的 45%；若整頁圖則佔 70%

```python
def extract_and_fix_image(doc, page_idx, output_path):
    page = doc[page_idx]
    mat = fitz.Matrix(2.5, 2.5)
    pix = page.get_pixmap(matrix=mat, colorspace=fitz.csRGB)
    img = Image.open(io.BytesIO(pix.tobytes("png")))
    # 已是白底，直接存
    img.save(output_path, "PNG")
```
