#!/usr/bin/env bash
# Install LSP servers and linters used by the vim setup.
# Safe to re-run — each step is idempotent.
#
# Tools installed:
#   fortls                 — Fortran LSP           (pipx, user scope)
#   basedpyright           — Python LSP/typechecker (pipx, user scope)
#   bash-language-server   — Bash LSP              (npm, nvm scope, no sudo)
#   texlab                 — LaTeX LSP             (GitHub release, ~/.local/bin)
#   shellcheck             — Bash linter (ALE)     (apt, requires sudo)
#
# ruff and gfortran are assumed already installed.

set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

install_pipx() {
   local pkg=$1
   if have "$pkg"; then
      log "$pkg already installed: $(command -v "$pkg")"
   else
      log "Installing $pkg via pipx..."
      pipx install "$pkg"
   fi
}

install_npm_global() {
   local pkg=$1 bin=$2
   if have "$bin"; then
      log "$bin already installed: $(command -v "$bin")"
   else
      log "Installing $pkg via npm (nvm scope, no sudo)..."
      npm install -g "$pkg"
   fi
}

install_apt() {
   local pkg=$1 bin=${2:-$1}
   if have "$bin"; then
      log "$bin already installed: $(command -v "$bin")"
   else
      log "Installing $pkg via apt (needs sudo)..."
      sudo apt-get install -y "$pkg"
   fi
}

# texlab is not packaged in Ubuntu 24.04; fetch the upstream static binary.
install_texlab_release() {
   if have texlab; then
      log "texlab already installed: $(command -v texlab)"
      return
   fi
   local arch tarball url tmpdir
   arch=$(uname -m)
   if [[ $arch != "x86_64" ]]; then
      warn "texlab: unsupported arch $arch — install manually"
      return 1
   fi
   mkdir -p "$HOME/.local/bin"
   tmpdir=$(mktemp -d)
   trap 'rm -rf "$tmpdir"' RETURN
   url=$(curl -sSfL https://api.github.com/repos/latex-lsp/texlab/releases/latest \
      | grep browser_download_url \
      | grep x86_64-linux \
      | head -1 \
      | cut -d'"' -f4)
   if [[ -z $url ]]; then
      warn "texlab: could not resolve release URL"
      return 1
   fi
   log "Fetching texlab from $url"
   curl -sSfL "$url" -o "$tmpdir/texlab.tar.gz"
   tar -xzf "$tmpdir/texlab.tar.gz" -C "$tmpdir"
   install -m 0755 "$tmpdir/texlab" "$HOME/.local/bin/texlab"
   log "texlab installed to $HOME/.local/bin/texlab"
}

# Preflight
have pipx || { warn "pipx not found — install with 'sudo apt install pipx'"; exit 1; }
have npm  || { warn "npm not found — ensure nvm is active"; exit 1; }
have apt-get || { warn "apt-get not found — non-Debian system, adapt manually"; exit 1; }

install_pipx         fortls
install_pipx         basedpyright
install_npm_global   bash-language-server bash-language-server
install_texlab_release
install_apt          shellcheck

log "Done. Verify with:"
for b in fortls basedpyright bash-language-server texlab shellcheck; do
   printf '  %-24s %s\n' "$b" "$(command -v "$b" 2>/dev/null || echo 'MISSING')"
done
