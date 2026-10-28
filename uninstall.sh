#!/bin/bash
# Desinstalle : arrete le serveur, supprime le raccourci, restaure la derniere sauvegarde de settings.json.
DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$DIR/config.env" ] && source "$DIR/config.env"
pkill -f "[s]erver.py" -P 1 2>/dev/null; pkill -f "$DIR/[s]erver.py" 2>/dev/null
[ -n "$DESKTOP_DIR" ] && rm -f "$DESKTOP_DIR/Quota Claude (debug).lnk" "$DESKTOP_DIR/Quota Claude.lnk" && echo "raccourci supprime"
B="$(ls -t "$HOME"/.claude/settings.json.bak-quota-* 2>/dev/null | tail -1)"
[ -n "$B" ] && cp "$B" "$HOME/.claude/settings.json" && echo "settings.json restaure depuis $B"
echo "Pour tout effacer : supprimez ce dossier."
