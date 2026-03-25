#!/usr/bin/env bash
# Claude Code status line — Solarized dark palette
# Reads JSON from stdin (Claude Code statusLine protocol)

input=$(cat)

# ── Solarized dark 256-colour helpers ──────────────────────────────────────
reset="\033[0m"
orange="\033[38;5;166m"
yellow="\033[38;5;136m"
blue="\033[38;5;33m"
white="\033[38;5;15m"
dim="\033[38;5;240m"
green="\033[38;5;64m"
violet="\033[38;5;61m"
red="\033[38;5;124m"

sep="${dim} │ ${reset}"

# ── Extract all fields in one python3 call ──────────────────────────────────
eval "$(echo "$input" | python3 -c "
import sys, json
from datetime import datetime, timezone

d = json.load(sys.stdin)
cwd   = d.get('workspace', {}).get('current_dir') or d.get('cwd', '')
model = d.get('model', {}).get('display_name', '')
_r    = lambda v: str(round(v)) if v != '' else ''
pct   = _r(d.get('context_window', {}).get('used_percentage', ''))
rl    = d.get('rate_limits', {})
fh    = _r(rl.get('five_hour', {}).get('used_percentage', ''))
sd    = _r(rl.get('seven_day', {}).get('used_percentage', ''))

def time_until(ts):
    if not ts:
        return ''
    try:
        secs = max(0, int(ts - datetime.now(timezone.utc).timestamp()))
        h, m = divmod(secs // 60, 60)
        d = h // 24
        if d >= 1:
            return f'{d}d{h % 24}h' if h % 24 else f'{d}d'
        return f'{h}h{m:02d}m' if h else f'{m}m'
    except Exception:
        return ''

fh_reset = time_until(rl.get('five_hour', {}).get('resets_at'))
sd_reset = time_until(rl.get('seven_day', {}).get('resets_at'))

print(f'_cwd={chr(39)}{cwd}{chr(39)}')
print(f'_model={chr(39)}{model}{chr(39)}')
print(f'_pct={chr(39)}{pct}{chr(39)}')
print(f'_fh={chr(39)}{fh}{chr(39)}')
print(f'_sd={chr(39)}{sd}{chr(39)}')
print(f'_fh_reset={chr(39)}{fh_reset}{chr(39)}')
print(f'_sd_reset={chr(39)}{sd_reset}{chr(39)}')
" 2>/dev/null)"

# ── Colour helper (green/yellow/orange/red by percentage) ───────────────────
_pct_color() {
    local n=${1%.*}
    if   [ "$n" -ge 95 ] 2>/dev/null; then printf "%b" "$red"
    elif [ "$n" -ge 80 ] 2>/dev/null; then printf "%b" "$orange"
    elif [ "$n" -ge 50 ] 2>/dev/null; then printf "%b" "$yellow"
    else                                    printf "%b" "$green"
    fi
}

# ── Model ────────────────────────────────────────────────────────────────────
model_part=""
if [ -n "$_model" ]; then
    model_part="${violet}${_model}${reset}"
    if [ -n "${CLAUDE_LOCAL_GPUS:-}" ]; then
        model_part+="${dim}·${CLAUDE_LOCAL_GPUS}×GPU${reset}"
    fi
fi

# ── Working directory ────────────────────────────────────────────────────────
dir_part=""
[ -n "$_cwd" ] && dir_part="${blue}$(basename "$_cwd")${reset}"

# ── Git context ───────────────────────────────────────────────────────────────
git_part=""
if git -C "$_cwd" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    branch=$(git -C "$_cwd" symbolic-ref --quiet --short HEAD 2>/dev/null \
             || git -C "$_cwd" rev-parse --short HEAD 2>/dev/null \
             || echo "(unknown)")
    s=""
    git -C "$_cwd" diff --quiet --ignore-submodules --cached 2>/dev/null || s+="+"
    git -C "$_cwd" diff-files --quiet --ignore-submodules -- 2>/dev/null  || s+="!"
    [ -n "$(git -C "$_cwd" ls-files --others --exclude-standard 2>/dev/null)" ] && s+="?"
    git -C "$_cwd" rev-parse --verify refs/stash &>/dev/null && s+="\$"
    remote=$(git -C "$_cwd" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || true)
    if [ -n "$remote" ] && [ "$remote" != "(unknown)" ]; then
        ahead=$(git  -C "$_cwd" rev-list --left-right "${branch}...${remote}" 2>/dev/null | grep -c '^<' || true)
        behind=$(git -C "$_cwd" rev-list --left-right "${branch}...${remote}" 2>/dev/null | grep -c '^>' || true)
        [ "$ahead"  -gt 0 ] 2>/dev/null && { [ -n "$s" ] && s+=" "; s+="↑${ahead}"; }
        [ "$behind" -gt 0 ] 2>/dev/null && { [ -n "$s" ] && s+=" "; s+="↓${behind}"; }
    fi
    [ -n "$s" ] && s=" [${s}]"
    git_part="${yellow}${branch}${orange}${s}${reset}"
fi

# ── Context usage ─────────────────────────────────────────────────────────────
usage_part=""
if [ -n "$_pct" ]; then
    c=$(_pct_color "$_pct")
    usage_part="${white}ctx:${c}${_pct}%${reset}"
fi

# ── Rate limits ───────────────────────────────────────────────────────────────
rate_part=""
if [ -n "$_fh" ] || [ -n "$_sd" ]; then
    r=""
    if [ -n "$_fh" ]; then
        r+="${white}5h:$(_pct_color "$_fh")${_fh}%${reset}"
        [ -n "$_fh_reset" ] && r+="${dim}(${_fh_reset})${reset}"
    fi
    [ -n "$_fh" ] && [ -n "$_sd" ] && r+=" "
    if [ -n "$_sd" ]; then
        r+="${white}7d:$(_pct_color "$_sd")${_sd}%${reset}"
        [ -n "$_sd_reset" ] && r+="${dim}(${_sd_reset})${reset}"
    fi
    rate_part="$r"
fi

# ── Assemble with separators ──────────────────────────────────────────────────
parts=""
for p in "$model_part" "$dir_part" "$git_part" "$usage_part" "$rate_part"; do
    [ -z "$p" ] && continue
    [ -n "$parts" ] && parts+="$sep"
    parts+="$p"
done

printf "%b" "$parts"
