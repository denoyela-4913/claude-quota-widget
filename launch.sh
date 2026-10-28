#!/bin/bash
# Demarre le serveur (si besoin), ouvre la fenetre du navigateur, puis reste au premier plan
# tant que le serveur tourne (le wsl.exe cache du raccourci garde ainsi WSL vivant).
# Debug : DEBUG=1 dans config.env, ou QUOTA_DEBUG=1 dans l'environnement.
DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$DIR/data"
LOG="$DIR/data/launch.log"
# journal borne : on garde la fin au-dela de ~200 Ko
[ "$(stat -c %s "$LOG" 2>/dev/null || echo 0)" -gt 204800 ] && tail -c 100000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
log() { echo "$(date +%T) $*" >> "$LOG"; }
log "launch.sh demarre (user=$USER)"
source "$DIR/config.env" || { log "config.env illisible"; exit 1; }
export QUOTA_DEBUG="${QUOTA_DEBUG:-${DEBUG:-0}}"
if [ "$QUOTA_DEBUG" = 1 ]; then
  log "mode debug : trace activee"
  log "config : PORT=$PORT WINDOW_SIZE=$WINDOW_SIZE BROWSER_EXE=$BROWSER_EXE BROWSER_PROFILE=$BROWSER_PROFILE"
  exec 2>> "$LOG"; set -x
fi

up() { (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; }

if ! up; then
  log "demarrage serveur"
  python3 "$DIR/server.py" >> "$LOG" 2>&1 &
  SRV=$!
  for _ in $(seq 30); do up && break; sleep 0.3; done
fi

log "ouverture navigateur"
"$BROWSER_EXE" --user-data-dir="$BROWSER_PROFILE" --app="http://localhost:$PORT" \
  --window-size="$WINDOW_SIZE" --no-first-run --no-default-browser-check >> "$LOG" 2>&1 &
CH=$!
log "navigateur lance (pid $CH)"
# attendre que le navigateur ait ouvert (ou confie a l'instance existante) sa fenetre : sinon la session WSL se ferme avant
wait "$CH"; sleep 2
log "navigateur: fin du lancement"

if [ -n "$SRV" ]; then wait "$SRV"; fi
exit 0
