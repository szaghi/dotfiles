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
sd_at    = rl.get('seven_day', {}).get('resets_at')
sd_start = str(int(sd_at) - 7 * 86400) if sd_at else ''

print(f'_cwd={chr(39)}{cwd}{chr(39)}')
print(f'_model={chr(39)}{model}{chr(39)}')
print(f'_pct={chr(39)}{pct}{chr(39)}')
print(f'_fh={chr(39)}{fh}{chr(39)}')
print(f'_sd={chr(39)}{sd}{chr(39)}')
print(f'_fh_reset={chr(39)}{fh_reset}{chr(39)}')
print(f'_sd_reset={chr(39)}{sd_reset}{chr(39)}')
print(f'_sd_start={chr(39)}{sd_start}{chr(39)}')
" 2>/dev/null)"

# ── Tokens used in the current 7-day window ─────────────────────────────────
# Anthropic reports the weekly limit only as a percentage; the token count is
# summed from the local transcripts (~/.claude/projects/**/*.jsonl) since the
# window start (resets_at - 7d). Only claude-* models count, so local and
# proxied backends are excluded. Usage from other machines or claude.ai is not
# visible here. The scan takes ~0.3 s, so it runs in the background at most
# once a minute and the status line prints the cached result.
_tok7d_py='
import glob, json, os, sys
from datetime import datetime
start = int(sys.argv[1])
seen = {}
for f in glob.glob(os.path.expanduser("~/.claude/projects/**/*.jsonl"), recursive=True):
    if os.path.getmtime(f) < start:
        continue
    with open(f, "rb") as fh:
        for line in fh:
            if b"\"usage\"" not in line:
                continue
            try:
                d = json.loads(line)
                m = d["message"]
                if d.get("type") != "assistant" or not str(m.get("model", "")).startswith("claude-"):
                    continue
                t = datetime.fromisoformat(d["timestamp"].replace("Z", "+00:00")).timestamp()
            except (ValueError, KeyError, TypeError, AttributeError):
                continue
            if t < start:
                continue
            u = m.get("usage") or {}
            # streamed replies repeat the same message id: count each once
            seen[m.get("id") or d.get("uuid")] = (u.get("output_tokens") or 0,
                sum(u.get(k) or 0 for k in ("input_tokens", "output_tokens",
                    "cache_creation_input_tokens", "cache_read_input_tokens")))
print(start, sum(v[0] for v in seen.values()), sum(v[1] for v in seen.values()))
'
_tok7d=""
if [ -n "$_sd_start" ]; then
    cdir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
    cache="$cdir/tok7d"
    mkdir -p "$cdir"
    read -r c_start c_out c_all 2>/dev/null < "$cache"
    if [ "$c_start" != "$_sd_start" ] || [ -z "$(find "$cache" -mmin -1 2>/dev/null)" ]; then
        ( flock -n 9 || exit 0
          python3 -c "$_tok7d_py" "$_sd_start" > "$cache.tmp" && mv "$cache.tmp" "$cache"
        ) 9>"$cdir/tok7d.lock" >/dev/null 2>&1 &
    fi
    _hum() { awk -v n="$1" 'BEGIN{ split("k M G T", u); s=""; for (i=0; n>=1000 && i<4; i++) { n/=1000; s=u[i+1] }
                                   printf (n<10 && s!="") ? "%.1f%s" : "%.0f%s", n, s }'; }
    [ "$c_start" = "$_sd_start" ] && _tok7d="$(_hum "$c_all") tok (out $(_hum "$c_out"))"
fi

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
        [ -n "$_tok7d" ] && r+=" ${white}${_tok7d}${reset}"
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
