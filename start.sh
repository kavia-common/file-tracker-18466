#!/usr/bin/env bash
# Start script for file-tracker-18466
# This script attempts to start the service in a consistent way across environments
# by detecting common runtimes (Node.js or Python). If neither is available,
# it will print usage guidance for the shell tools that ship with this repo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_banner() {
  echo "==============================================="
  echo " file-tracker-18466 - Startup"
  echo "==============================================="
}

print_help() {
  cat <<'EOF'
file-tracker-18466 provides command-line scripts to manage a file tracking
SQLite database:

Available scripts (from scripts/):
  - ce_createDb.sh <db.sqlite>
  - ce_addFile.sh <db.sqlite> <path/to/file...>
  - ce_mvFile.sh <db.sqlite> <from> <to>
  - ce_addDir.sh <db.sqlite> <path/to/dir>
  - ce_history.sh <db.sqlite> <path/to/file>

Quick example:
  ./scripts/ce_createDb.sh test.sqlite
  touch 1.txt && ./scripts/ce_addFile.sh test.sqlite 1.txt
  ./scripts/ce_mvFile.sh test.sqlite 1.txt 2.txt
  ./scripts/ce_history.sh test.sqlite 2.txt

Dev helper server (optional):
  If Python is installed, this start script will run a small static help server
  on port 8000 to expose this README and scripts listing for preview systems.

Manual usage:
  bash start.sh
EOF
}

start_python_help_server() {
  # Start a simple HTTP server to present README and scripts listing
  # Prefer Python3 if available; fallback to Python2's SimpleHTTPServer.
  local host="${HOST:-0.0.0.0}"
  local port="${PORT:-8000}"
  echo "Starting simple help server at http://${host}:${port}"
  echo "Serving directory: ${SCRIPT_DIR}"
  # Use a temporary index if no index.html exists to give a friendly landing page
  local index="${SCRIPT_DIR}/.ft_index.html"
  cat > "${index}" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<title>file-tracker-18466</title>
<style>
  body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; padding: 2rem; line-height: 1.5; }
  code, pre { background: #f6f8fa; padding: 0.2rem 0.4rem; border-radius: 4px; }
  .card { border: 1px solid #e5e7eb; border-radius: 8px; padding: 1rem; margin-top: 1rem;}
</style>
</head>
<body>
  <h1>file-tracker-18466</h1>
  <p>This repository provides shell utilities for tracking files in an SQLite database.</p>
  <div class="card">
    <h2>Quick Start</h2>
    <pre>./scripts/ce_createDb.sh test.sqlite
touch 1.txt && ./scripts/ce_addFile.sh test.sqlite 1.txt
./scripts/ce_mvFile.sh test.sqlite 1.txt 2.txt
./scripts/ce_history.sh test.sqlite 2.txt</pre>
  </div>
  <div class="card">
    <h2>Repo Files</h2>
    <ul>
      <li><a href="/README.md">README.md</a></li>
      <li><a href="/scripts/">scripts/</a></li>
      <li><a href="/t/">t/</a></li>
    </ul>
  </div>
</body>
</html>
HTML

  # Serve the directory; ensure index is used; trap to remove temp file
  trap 'rm -f "${index}"' EXIT
  # Python http.server doesn't allow specifying index file directly; ensure the
  # temp index uses the conventional name.
  mv -f "${index}" "${SCRIPT_DIR}/index.html"
  trap 'rm -f "${SCRIPT_DIR}/index.html"' EXIT

  # Start server
  if command -v python3 >/dev/null 2>&1; then
    HOST="${host}" PORT="${port}" python3 - <<'PY'
import http.server, socketserver, os, sys
host = os.environ.get("HOST","0.0.0.0")
port = int(os.environ.get("PORT","8000"))
os.chdir(os.path.dirname(__file__) or ".")
class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write("[http] " + fmt % args + "\n")
with socketserver.TCPServer((host, port), QuietHandler) as httpd:
    print(f"HTTP server running on http://{host}:{port}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
PY
  else
    HOST="${host}" PORT="${port}" python - <<'PY'
import SimpleHTTPServer, SocketServer, os, sys
host = os.environ.get("HOST","0.0.0.0")
port = int(os.environ.get("PORT","8000"))
os.chdir(os.path.dirname(__file__) or ".")
class QuietHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write("[http] " + (fmt % args) + "\n")
httpd = SocketServer.TCPServer((host, port), QuietHandler)
print("HTTP server running on http://%s:%s" % (host, port))
try:
    httpd.serve_forever()
except KeyboardInterrupt:
    pass
PY
  fi
}

main() {
  print_banner

  # If package.json exists, assume Node app and prefer npm start
  if [ -f "${SCRIPT_DIR}/package.json" ]; then
    if command -v npm >/dev/null 2>&1; then
      echo "Detected Node.js project. Running: npm start"
      exec npm start
    elif command -v node >/dev/null 2>&1; then
      # Try common entry points
      for entry in server.js app.js index.js; do
        if [ -f "${SCRIPT_DIR}/${entry}" ]; then
          echo "Detected Node.js entry ${entry}. Running: node ${entry}"
          exec node "${entry}"
        fi
      done
    fi
  fi

  # If there is a recognizable Python entrypoint, use it
  if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
    # Look for common backends
    if [ -f "${SCRIPT_DIR}/main.py" ]; then
      echo "Detected Python entry main.py. Running it."
      if command -v python3 >/dev/null 2>&1; then
        exec python3 "${SCRIPT_DIR}/main.py"
      else
        exec python "${SCRIPT_DIR}/main.py"
      fi
    fi
  fi

  # Fallback: run a simple static help server if Python is available
  if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
    start_python_help_server
    exit 0
  fi

  # Last resort: print usage only
  echo "No Node.js or Python runtime detected. Showing usage:"
  echo
  print_help
}

main "$@"
