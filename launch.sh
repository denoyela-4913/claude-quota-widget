#!/bin/bash
# Demarre le serveur (si besoin), ouvre la fenetre du navigateur, puis reste au premier plan
# tant que le serveur tourne (le wsl.exe cache du raccourci garde ainsi WSL vivant).
# Debug : uniquement avec QUOTA_DEBUG=1 dans l'environnement (le raccourci "debug" le positionne).
DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$DIR/data"
LOG="$DIR/data/launch.log"
# journal borne : on garde la fin au-dela de ~200 Ko
[ "$(stat -c %s "$LOG" 2>/dev/null || echo 0)" -gt 204800 ] && tail -c 100000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
log() { echo "$(date +%T) $*" >> "$LOG"; }
log "launch.sh demarre (user=$USER)"
source "$DIR/config.env" || { log "config.env illisible"; exit 1; }
export QUOTA_DEBUG="${QUOTA_DEBUG:-0}"
if [ "$QUOTA_DEMO" = 1 ]; then   # demo : autre port, autre profil, autre fichier d'etat, serveur en donnees fictives
  PORT=$((PORT + 1)); BROWSER_PROFILE="${BROWSER_PROFILE}Demo"; STATE="$DIR/data/state-demo.json"
  export QUOTA_DEMO QUOTA_PORT=$PORT; log "mode demo (port $PORT)"
else
  STATE="$DIR/data/state.json"
fi
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
  trap 'kill "$SRV" 2>/dev/null' EXIT   # Ctrl+C / fin : on arrete le serveur qu'on a demarre
  for _ in $(seq 30); do up && break; sleep 0.3; done
fi

# derniere vue utilisee (compact|detail) et sa position, memorisees par le serveur dans data/state.json (state-demo.json en demo)
read -r VIEW PX PY < <(python3 - "$STATE" <<'PY'
import json, sys
try:
    st = json.load(open(sys.argv[1]))
    v = st.get("view") if st.get("view") in ("compact", "detail") else "compact"
    p = (st.get("pos") or {}).get(v) or ["-", "-"]
except Exception:
    v, p = "compact", ["-", "-"]
print(v, p[0], p[1])
PY
)
if [ "$VIEW" = detail ]; then URL="http://localhost:$PORT/detail"; SIZE="$WINDOW_SIZE_DETAIL"; else URL="http://localhost:$PORT/"; SIZE="$WINDOW_SIZE"; fi
POS=(); [ "$PX" != "-" ] && POS=(--window-position="$PX,$PY")
log "ouverture navigateur (vue $VIEW, taille $SIZE, position ${PX:--},${PY:--})"
"$BROWSER_EXE" --user-data-dir="$BROWSER_PROFILE" --app="$URL" \
  --window-size="$SIZE" "${POS[@]}" --no-first-run --no-default-browser-check >> "$LOG" 2>&1 &
CH=$!
log "navigateur lance (pid $CH)"
# attendre que le navigateur ait ouvert (ou confie a l'instance existante) sa fenetre : sinon la session WSL se ferme avant
wait "$CH"; sleep 2
log "navigateur: fin du lancement"

if [ -n "$SRV" ]; then wait "$SRV"; fi
exit 0
