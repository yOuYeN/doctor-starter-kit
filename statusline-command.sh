#!/usr/bin/env bash
# Claude Code status line script — Morandi palette, 50-block context bar

input=$(cat)
[ -z "$input" ] && input="{}"

# --- Morandi ANSI 256-color codes ---
# Each section gets a distinct muted, desaturated tone.
C_MODEL="\e[38;5;181m"          # dusty rose        — model name
# Bar fill: dynamic (set below based on usage %)
#   0-50%  → 108 Morandi sage green
#   50-60% → 185 muted yellow
#   60-70% → 173 muted terracotta/orange
#   >70%   → 167 dusty red
C_BAR_EMPTY="\e[38;5;238m"      # dark warm gray    — empty bar blocks
# C_BAR_PCT matches C_BAR_FILL (set dynamically)
C_FIVE="\e[38;5;110m"           # muted blue-gray   — 5-hour quota
C_WEEK="\e[38;5;139m"           # soft mauve        — 7-day quota
C_GIT_BR="\e[38;5;180m"         # warm sand         — git branch
C_GIT_ADD="\e[38;5;108m"        # muted sage green  — git diff +
C_GIT_DEL="\e[38;5;167m"        # dusty red         — git diff -
C_AGENT="\e[38;5;147m"          # soft lavender     — agent name
C_SEP="\e[38;5;245m"            # cool mid-gray     — separators
C_RESET="\e[0m"

# --- Model ---
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "Claude Code"')

# --- Context window (50-block bar, each block = 2%) ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_str=""
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")

  # Dynamic fill color based on usage percentage
  if [ "$used_int" -gt 70 ]; then
    C_BAR_FILL="\e[38;5;167m"   # dusty red         — >70%
  elif [ "$used_int" -gt 60 ]; then
    C_BAR_FILL="\e[38;5;173m"   # muted terracotta  — 60-70%
  elif [ "$used_int" -gt 50 ]; then
    C_BAR_FILL="\e[38;5;185m"   # muted yellow      — 50-60%
  else
    C_BAR_FILL="\e[38;5;108m"   # Morandi sage green — 0-50%
  fi
  # Percentage text matches fill color so they read as a unit
  C_BAR_PCT="$C_BAR_FILL"

  # --- macOS notification: fire once when context crosses 65% ---
  NOTIFY_FLAG="/tmp/claude_compact_notified"
  if [ "$used_int" -ge 65 ]; then
    if [ ! -f "$NOTIFY_FLAG" ]; then
      touch "$NOTIFY_FLAG"
      osascript -e 'display notification "上下文用量已達 65%，是否考慮使用 /compact 壓縮對話？" with title "Claude Code" subtitle "Context Warning"' &>/dev/null &
    fi
  else
    [ -f "$NOTIFY_FLAG" ] && rm -f "$NOTIFY_FLAG"
  fi

  bar_total=50
  filled=$(( used_int * bar_total / 100 ))
  [ "$filled" -gt "$bar_total" ] && filled=$bar_total
  empty=$(( bar_total - filled ))
  bar_filled=""
  bar_empty=""
  for i in $(seq 1 $filled); do bar_filled="${bar_filled}█"; done
  for i in $(seq 1 $empty);  do bar_empty="${bar_empty}░"; done
  ctx_str="${C_BAR_FILL}${bar_filled}${C_BAR_EMPTY}${bar_empty}${C_RESET} ${C_BAR_PCT}${used_int}%${C_RESET}"
fi

# --- Rate limits ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
five_str=""
if [ -n "$five_pct" ] && [ -n "$five_reset" ]; then
  now=$(date +%s)
  secs_left=$(( five_reset - now ))
  [ "$secs_left" -lt 0 ] && secs_left=0
  h=$(( secs_left / 3600 ))
  m=$(( (secs_left % 3600) / 60 ))
  pct_int=$(printf "%.0f" "$five_pct")
  five_str="${C_FIVE}${h}H${m}m ${pct_int}%${C_RESET}"
fi

week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
week_str=""
if [ -n "$week_pct" ] && [ -n "$week_reset" ]; then
  now=$(date +%s)
  secs_left=$(( week_reset - now ))
  [ "$secs_left" -lt 0 ] && secs_left=0
  h=$(( secs_left / 3600 ))
  m=$(( (secs_left % 3600) / 60 ))
  pct_int=$(printf "%.0f" "$week_pct")
  week_str="${C_WEEK}${h}H${m}m ${pct_int}%${C_RESET}"
fi

# --- Git branch ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
git_branch=""
git_diff=""
if [ -n "$cwd" ]; then
  git_branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$git_branch" ]; then
    diff_stat=$(git -C "$cwd" --no-optional-locks diff --shortstat HEAD 2>/dev/null)
    if [ -n "$diff_stat" ]; then
      ins=$(echo "$diff_stat" | grep -o '[0-9]* insertion' | grep -o '[0-9]*')
      del=$(echo "$diff_stat" | grep -o '[0-9]* deletion' | grep -o '[0-9]*')
      [ -z "$ins" ] && ins=0
      [ -z "$del" ] && del=0
      git_diff="${C_GIT_ADD}+${ins}${C_RESET}${C_SEP}/${C_RESET}${C_GIT_DEL}-${del}${C_RESET}"
    fi
  fi
fi

# --- Agent name ---
agent_name=$(echo "$input" | jq -r '.agent.name // empty')

# --- Assemble output ---
# Build an array of already-colored segments; join with a colored separator.
parts=()

[ -n "$model" ]      && parts+=("${C_MODEL}${model}${C_RESET}")
[ -n "$ctx_str" ]    && parts+=("$ctx_str")
[ -n "$five_str" ]   && parts+=("${C_FIVE}1H:${C_RESET} $five_str")
[ -n "$week_str" ]   && parts+=("${C_WEEK}7D:${C_RESET} $week_str")

if [ -n "$git_branch" ]; then
  git_part="${C_GIT_BR} ${git_branch}${C_RESET}"
  [ -n "$git_diff" ] && git_part="${git_part} ${git_diff}"
  parts+=("$git_part")
fi

[ -n "$agent_name" ] && parts+=("${C_AGENT}${agent_name}${C_RESET}")

SEP="${C_SEP}  |  ${C_RESET}"
output=""
for part in "${parts[@]}"; do
  if [ -z "$output" ]; then
    output="$part"
  else
    output="${output}${SEP}${part}"
  fi
done

printf "%b" "$output"
