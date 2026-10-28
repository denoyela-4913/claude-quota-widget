#!/bin/bash
# Demo du widget avec des donnees fictives (4 scenarios, change toutes les 8 s).
# Autre port (PORT+1), autre profil de navigateur et autre fichier d'etat : le vrai widget n'est pas touche.
# Touche "d" ou bouton pour basculer compacte/detaillee. Ctrl+C pour arreter (arret auto apres 20 min).
DIR="$(cd "$(dirname "$0")" && pwd)"
QUOTA_DEMO=1 exec "$DIR/launch.sh"
