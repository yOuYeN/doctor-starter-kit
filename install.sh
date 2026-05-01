#!/bin/bash
# Claude Code 簡報技能包 - 一鍵安裝腳本
# 適用於 macOS

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "====================================="
echo "  Claude Code 簡報助手 - 安裝程式"
echo "====================================="
echo ""

# 0. 擴展 PATH（確保 npm 全域安裝的工具可以被找到）
export PATH="/usr/local/bin:/opt/homebrew/bin:$HOME/.local/bin:$PATH"
[ -s "$HOME/.nvm/nvm.sh" ] && source "$HOME/.nvm/nvm.sh"

# 1. 確認或自動安裝 Claude Code
if ! command -v claude &> /dev/null; then
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}✗ 尚未安裝 Node.js${NC}"
        echo ""
        echo "請先前往 https://nodejs.org 下載安裝 Node.js，"
        echo "完成後重新執行此腳本。"
        exit 1
    fi
    echo -e "${YELLOW}→ 正在安裝 Claude Code...${NC}"
    npm install -g @anthropic-ai/claude-code
    export PATH="/usr/local/bin:/opt/homebrew/bin:$HOME/.local/bin:$PATH"
    echo -e "${GREEN}✓ Claude Code 安裝完成${NC}"
else
    echo -e "${GREEN}✓ Claude Code 已安裝${NC}"
fi

# 2. 確認或自動安裝 Marp CLI
if ! command -v marp &> /dev/null; then
    echo -e "${YELLOW}→ 正在安裝 Marp CLI...${NC}"
    npm install -g @marp-team/marp-cli
    echo -e "${GREEN}✓ Marp CLI 安裝完成${NC}"
else
    echo -e "${GREEN}✓ Marp CLI 已安裝${NC}"
fi

# 3. 安裝 Python 套件
echo -e "${YELLOW}→ 正在安裝 Python 套件...${NC}"
pip3 install pymupdf python-pptx pillow --quiet
echo -e "${GREEN}✓ Python 套件安裝完成（pymupdf / python-pptx / pillow）${NC}"

# 4. 建立工作資料夾
WORKSPACE="$HOME/Documents/claude-slides"
mkdir -p "$WORKSPACE/source"
mkdir -p "$WORKSPACE/output"
mkdir -p "$WORKSPACE/.claude/skills"
echo -e "${GREEN}✓ 工作資料夾建立完成：$WORKSPACE${NC}"

# 5. 複製 CLAUDE.md 與 skills 到工作資料夾
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" "$WORKSPACE/CLAUDE.md"
    echo -e "${GREEN}✓ Claude 使用說明已複製到工作資料夾${NC}"
fi

if [ -f "$SCRIPT_DIR/skills/make-slides.md" ]; then
    cp "$SCRIPT_DIR/skills/make-slides.md" "$WORKSPACE/.claude/skills/make-slides.md"
    echo -e "${GREEN}✓ make-slides skill 已安裝${NC}"
fi

# 6. 設定 Claude 權限
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
    cp "$SCRIPT_DIR/claude-settings.json" "$CLAUDE_DIR/settings.json"
    echo -e "${GREEN}✓ Claude 設定檔已安裝${NC}"
else
    echo -e "${GREEN}✓ 已有 Claude 設定檔，略過${NC}"
fi

# 6b. 安裝狀態列腳本
if [ -f "$SCRIPT_DIR/statusline-command.sh" ]; then
    cp "$SCRIPT_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
    chmod +x "$CLAUDE_DIR/statusline-command.sh"
    echo -e "${GREEN}✓ 狀態列腳本已安裝${NC}"
fi

# 6c. 將 statusLine 設定注入 settings.json（若尚未存在）
if ! grep -q '"statusLine"' "$CLAUDE_DIR/settings.json" 2>/dev/null; then
    python3 -c "
import json
path = '$CLAUDE_DIR/settings.json'
sl_path = '$CLAUDE_DIR/statusline-command.sh'
with open(path) as f:
    data = json.load(f)
data['statusLine'] = {'type': 'command', 'command': f'bash {sl_path}'}
with open(path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
"
    echo -e "${GREEN}✓ 狀態列已加入設定檔${NC}"
else
    echo -e "${GREEN}✓ 狀態列設定已存在，略過${NC}"
fi

# 7. 建立 slides 指令（放到 claude 同一個 bin 目錄，不需重開 Terminal）
CLAUDE_BIN=$(which claude 2>/dev/null)
if [ -n "$CLAUDE_BIN" ]; then
    SLIDES_PATH="$(dirname "$CLAUDE_BIN")/slides"
    cat > "$SLIDES_PATH" << 'SLIDESEOF'
#!/bin/bash
cd ~/Documents/claude-slides && exec claude "$@"
SLIDESEOF
    chmod +x "$SLIDES_PATH"
    echo -e "${GREEN}✓ 'slides' 指令已建立${NC}"
else
    echo -e "${RED}✗ 找不到 claude 路徑，slides 指令未建立${NC}"
fi

echo ""
echo "====================================="
echo -e "${GREEN}  安裝完成！${NC}"
echo "====================================="
echo ""
echo "現在直接輸入："
echo ""
echo "  slides"
echo ""
echo "即可啟動 Claude Code 簡報助手。"
echo "進入後用中文告訴 Claude 你要做什麼。"
echo ""
