#!/bin/bash
# Installeur : genere config.env (questions), cree le(s) raccourci(s) Bureau, branche la statusline Claude Code.
# Usage : ./install.sh [--yes] [--debug]
#   --yes    accepte toutes les valeurs par defaut
#   --debug  active le mode debug (journaux detailles + raccourci "Quota Claude (debug)")
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
YES=0; DEF_DEBUG=0
for a in "$@"; do case "$a" in --yes) YES=1;; --debug) DEF_DEBUG=1;; *) echo "option inconnue : $a" >&2; exit 2;; esac; done
CONF="$DIR/config.env"
SETTINGS="$HOME/.claude/settings.json"

ask() { # ask VAR "question" "defaut"
  local v
  if [ $YES = 1 ]; then v="$3"; else read -r -p "$2 [$3] : " v; v="${v:-$3}"; fi
  printf -v "$1" '%s' "$v"
}

# --- valeurs par defaut detectees ---
DEF_WIN_USER="$(basename "$(wslpath "$(powershell.exe -NoProfile -c '$env:USERPROFILE' | tr -d '\r\n')")")"
DEF_DESKTOP="$(wslpath "$(powershell.exe -NoProfile -c '[Environment]::GetFolderPath("Desktop")' | tr -d '\r\n')")"
DEF_BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
[ -f "$DEF_BROWSER" ] || DEF_BROWSER="/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"

echo "Compte Linux courant : $USER"
if [ -f "$CONF" ]; then echo "config.env existe deja : reponses precedentes reprises comme valeurs par defaut."; source "$CONF"
  DEF_WIN_USER="${WIN_USER:-$DEF_WIN_USER}"; DEF_DESKTOP="${DESKTOP_DIR:-$DEF_DESKTOP}"; DEF_BROWSER="${BROWSER_EXE:-$DEF_BROWSER}"
  [ $DEF_DEBUG = 1 ] || DEF_DEBUG="${DEBUG:-0}"; fi

ask WIN_USER "Dossier utilisateur Windows (C:\\Users\\<nom>)" "$DEF_WIN_USER"
ask DESKTOP_DIR "Dossier du Bureau (chemin WSL)" "$DEF_DESKTOP"
ask BROWSER_EXE "Navigateur Windows (chemin WSL)" "$DEF_BROWSER"
ask BROWSER_PROFILE "Profil dedie du navigateur (chemin Windows)" "${BROWSER_PROFILE:-C:\\Users\\$WIN_USER\\AppData\\Local\\ClaudeQuotaProfile}"
ask PORT "Port local" "${PORT:-8765}"
ask WINDOW_SIZE "Taille de fenetre (largeur,hauteur)" "${WINDOW_SIZE:-300,230}"
ask DEBUG "Mode debug (0/1)" "$DEF_DEBUG"

[ -f "$BROWSER_EXE" ] || { echo "Navigateur introuvable : $BROWSER_EXE" >&2; exit 1; }
[ -d "$DESKTOP_DIR" ] || { echo "Bureau introuvable : $DESKTOP_DIR" >&2; exit 1; }

{ for k in WIN_USER DESKTOP_DIR BROWSER_EXE BROWSER_PROFILE PORT WINDOW_SIZE DEBUG; do
    printf "%s='%s'\n" "$k" "${!k}"; done; } > "$CONF"
echo "-> config.env ecrit"

# --- raccourcis Bureau (.lnk) ---
mklnk() { # mklnk "nom" "arguments powershell"
  local lnk
  lnk="$(wslpath -w "$DESKTOP_DIR")\\$1.lnk"
  powershell.exe -NoProfile -c "
\$s=(New-Object -ComObject WScript.Shell).CreateShortcut('$lnk')
\$s.TargetPath='powershell.exe'
\$s.Arguments='${2//\'/\'\'}'
\$s.IconLocation='$(wslpath -w "$BROWSER_EXE"),0'
\$s.WindowStyle=7
\$s.Save()"
  echo "-> raccourci : $DESKTOP_DIR/$1.lnk"
}
mklnk "Quota Claude" "-NoProfile -WindowStyle Hidden -Command \"Start-Process wsl.exe -WindowStyle Hidden -ArgumentList '-e','bash','$DIR/launch.sh'\""
if [ "$DEBUG" = 1 ]; then
  mklnk "Quota Claude (debug)" "-NoProfile -NoExit -Command \"wsl.exe -l -v; wsl.exe -e env QUOTA_DEBUG=1 bash $DIR/launch.sh; Write-Host ('--- fin, code retour : ' + \$LASTEXITCODE)\""
else
  rm -f "$DESKTOP_DIR/Quota Claude (debug).lnk"
fi

# --- statusline Claude Code ---
mkdir -p "$DIR/data" "$HOME/.claude"
ls "$SETTINGS".bak-quota-* >/dev/null 2>&1 || { [ -f "$SETTINGS" ] && cp "$SETTINGS" "$SETTINGS.bak-quota-$(date +%Y%m%d%H%M%S)"; }
python3 - "$SETTINGS" "$DIR/statusline.py" <<'PY'
import json, sys, os
p, script = sys.argv[1:3]
d = json.load(open(p)) if os.path.exists(p) else {}
d["statusLine"] = {"type": "command", "command": "python3 " + script}
json.dump(d, open(p, "w"), indent=2, ensure_ascii=False)
PY
echo "-> statusLine de $SETTINGS pointe vers $DIR/statusline.py (sauvegarde .bak-quota-* creee)"
echo "Termine. Double-cliquez sur 'Quota Claude' sur le Bureau."
