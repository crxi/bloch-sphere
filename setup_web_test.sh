#!/usr/bin/env bash
# Spins up an ephemeral public URL for testing bloch_sphere.html on a phone
# (or any device that isn't this Mac). Stages just the HTML in a temp dir so
# the tunnel doesn't expose .git or anything else in the repo.
#
# Usage:  ./setup_web_test.sh
# Stop:   Ctrl+C in this terminal.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTML_FILE="$REPO_DIR/bloch_sphere.html"
PORT="${PORT:-8080}"
SERVE_DIR="$(mktemp -d -t bloch-mobile.XXXXXX)"
TUNNEL_LOG="$(mktemp -t bloch-tunnel.XXXXXX)"

if [[ ! -f "$HTML_FILE" ]]; then
  echo "ERROR: $HTML_FILE not found" >&2
  exit 1
fi

if ! command -v cloudflared >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Installing cloudflared via Homebrew..."
    brew install cloudflared
  else
    echo "ERROR: cloudflared not installed and Homebrew not available." >&2
    echo "Install Homebrew (https://brew.sh) and retry, or install cloudflared manually." >&2
    exit 1
  fi
fi

cleanup() {
  trap - EXIT INT TERM
  echo
  echo "Stopping..."
  [[ -n "${SERVER_PID:-}" ]] && kill "$SERVER_PID" 2>/dev/null || true
  [[ -n "${TUNNEL_PID:-}" ]] && kill "$TUNNEL_PID" 2>/dev/null || true
  rm -rf "$SERVE_DIR" "$TUNNEL_LOG"
}
trap cleanup EXIT INT TERM

# Symlink (not copy) so edits to bloch_sphere.html are picked up live —
# the user just hard-refreshes their browser to see changes.
ln -s "$HTML_FILE" "$SERVE_DIR/index.html"

if lsof -ti:"$PORT" >/dev/null 2>&1; then
  echo "Port $PORT is in use; killing previous process..."
  lsof -ti:"$PORT" | xargs kill 2>/dev/null || true
  sleep 1
fi

# SimpleHTTPRequestHandler with Cache-Control: no-store so phones don't
# cache the HTML and you can refresh after every edit.
( cd "$SERVE_DIR" && python3 -c "
from http.server import SimpleHTTPRequestHandler, HTTPServer
class H(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()
    def log_message(self, *a): pass
HTTPServer(('', $PORT), H).serve_forever()
" >/dev/null 2>&1 ) &
SERVER_PID=$!

cloudflared tunnel --url "http://localhost:$PORT" >"$TUNNEL_LOG" 2>&1 &
TUNNEL_PID=$!

URL=""
for _ in $(seq 1 60); do
  URL="$(grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' "$TUNNEL_LOG" | head -1 || true)"
  [[ -n "$URL" ]] && break
  sleep 0.5
done

if [[ -z "$URL" ]]; then
  echo "ERROR: cloudflared did not print a tunnel URL within 30s" >&2
  echo "Tunnel log:" >&2
  cat "$TUNNEL_LOG" >&2
  exit 1
fi

LAN_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "<unknown>")"

cat <<EOF

================================================================
  Bloch sphere — public test URL ready
================================================================

  Anywhere (phone, laptop, anyone you share the URL with):

      $URL

  Same Wi-Fi only (no firewall? skip the tunnel):

      http://$LAN_IP:$PORT/

  - The URL is ephemeral; a new one is generated each run.
  - Only bloch_sphere.html is exposed; .git and everything else
    in the repo stays local.
  - Stop the server + tunnel: press Ctrl+C here.

================================================================

EOF

wait "$TUNNEL_PID"
