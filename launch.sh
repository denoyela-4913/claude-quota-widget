#!/bin/bash
# Demarre le serveur (si besoin), ouvre la fenetre du navigateur, puis reste au premier plan
# tant que le serveur tourne (le wsl.exe cache du raccourci garde ainsi WSL vivant).
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/config.env" || exit 1

up() { (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; }

if ! up; then
  python3 "$DIR/server.py" &
  SRV=$!
  for _ in $(seq 30); do up && break; sleep 0.3; done
fi

"$BROWSER_EXE" --user-data-dir="$BROWSER_PROFILE" --app="http://localhost:$PORT" \
  --window-size="$WINDOW_SIZE" --no-first-run --no-default-browser-check >/dev/null 2>&1 &

[ -n "$SRV" ] && wait "$SRV"
