#!/bin/bash
# Demo des rendus de la statusline avec des donnees fictives.
# Le snapshot est ecrit dans un fichier temporaire : les vraies donnees du widget ne sont pas touchees.
DIR="$(cd "$(dirname "$0")" && pwd)"
export QUOTA_STATUS_FILE="$(mktemp)"
trap 'rm -f "$QUOTA_STATUS_FILE" "$QUOTA_STATUS_FILE.tmp"' EXIT
now=$(date +%s)
t() { # nom id ctx 5h_pct 5h_reste_s 7j_pct
  echo "{\"model\":{\"display_name\":\"$1\",\"id\":\"$2\"},\"workspace\":{\"current_dir\":\"/a/DASHBOARD\"},\"context_window\":{\"used_percentage\":$3},\"rate_limits\":{\"five_hour\":{\"used_percentage\":$4,\"resets_at\":$((now+$5))},\"seven_day\":{\"used_percentage\":$6,\"resets_at\":$((now+300000))}}}" | python3 "$DIR/statusline.py"
}
echo "--- Tout va bien ---"
t "Haiku 4.5" claude-haiku-4-5 15 8 14400 10
t "Sonnet 5" claude-sonnet-5 25 12 14400 15
t "Opus 5.5" claude-opus-5-5 30 15 14400 20
t "Fable 5.1" claude-fable-5-1 20 10 14400 12
echo "--- Rythme un peu élevé ---"
t "Sonnet 5" claude-sonnet-5 55 22 14400 45
t "Opus 5.5" claude-opus-5-5 72 40 10800 55
echo "--- Surconsommation ---"
t "Opus 5.5" claude-opus-5-5 88 60 14400 78
t "Fable 5.1" claude-fable-5-1 92 95 3600 90
echo "--- Quota épuisé ---"
t "Sonnet 5" claude-sonnet-5 40 100 3600 60
