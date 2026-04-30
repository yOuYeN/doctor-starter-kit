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

# 1. 檢查 Claude Code 是否已安裝
if ! command -v claude &> /dev/null; then
    echo -e "${RED}✗ 尚未安裝 Claude Code${NC}"
    echo ""
    echo "請先執行以下指令安裝："
    echo "  npm install -g @anthropic-ai/claude-code"
    echo ""
    echo "若尚未安裝 Node.js，請先前往 https://nodejs.org 下載安裝。"
    exit 1
fi
echo -e "${GREEN}✓ Claude Code 已安裝${NC}"

# 2. 檢查 Marp CLI
if ! command -v marp &> /dev/null; then
    echo -e "${YELLOW}→ 正在安裝 Marp CLI（Markdown 轉 PowerPoint 工具）...${NC}"
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

# 6. 設定 Claude 權限（若尚未有設定檔）
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
    cp "$SCRIPT_DIR/claude-settings.json" "$CLAUDE_DIR/settings.json"
    echo -e "${GREEN}✓ Claude 設定檔已安裝${NC}"
else
    echo -e "${YELLOW}⚠ 已有 Claude 設定檔，略過（不覆蓋）${NC}"
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

# 7. 設定 NO_FLICKER 模式（改善終端機顯示）
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    if ! grep -q "claude-slides.*NO_FLICKER" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Claude Code 投影片助手（無閃爍模式）" >> "$SHELL_RC"
        echo "alias slides='cd ~/Documents/claude-slides && claude'" >> "$SHELL_RC"
        echo -e "${GREEN}✓ 已新增 'slides' 指令到 $SHELL_RC${NC}"
    else
        echo -e "${GREEN}✓ 'slides' 指令已存在，略過${NC}"
    fi
fi

echo ""
echo "====================================="
echo -e "${GREEN}  安裝完成！${NC}"
echo "====================================="
echo ""
echo "接下來請關閉並重新開啟終端機，然後輸入："
echo ""
echo "  slides"
echo ""
echo "（這個指令會直接進入工作資料夾並啟動 Claude Code）"
echo "進入後用中文告訴 Claude 你要做什麼。"
echo "詳細說明請參閱 README.md。"
echo ""
