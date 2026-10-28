# Quota Claude widget

Petite fenêtre (Chrome/Edge en mode `--app`, profil dédié) qui affiche les quotas 5h / 7j de Claude Code.

- `statusline.py` : statusline de Claude Code ; affiche la barre et écrit `data/quota-status.json`.
- `server.py` + `index.html` (vue compacte) + `detail.html` (vue détaillée, `/detail`, 490×490 par défaut) : pages locales (127.0.0.1:PORT) rafraîchies automatiquement.
- `demo-widget.sh` : lance le widget avec des données fictives (4 scénarios, change toutes les 8 s), sur le port PORT+1, avec son propre profil de navigateur et son propre état (`data/state-demo.json`) ; le vrai widget n'est pas touché. Ctrl+C pour arrêter (arrêt automatique après 20 min).
- `demo.sh` : affiche les rendus de la statusline avec des données fictives (sans toucher aux vraies données).
- `launch.sh` : démarre le serveur et ouvre la fenêtre.
- `install.sh` : pose des questions (défauts = comptes Linux/Windows courants), écrit `config.env`
  (non versionné, voir `config.template.env`), crée le raccourci Bureau, branche `statusLine` dans `~/.claude/settings.json`.
- `uninstall.sh` : retire le raccourci, restaure `settings.json`.

## Installation (WSL)
    ./install.sh        # ou ./install.sh --yes pour accepter les défauts
Le dossier ne doit plus être déplacé après installation (les chemins sont absolus ; relancer `install.sh` sinon).

## Couleurs
Vue compacte et vue détaillée utilisent la même règle (`levelColor`) : le pire du palier de pourcentage (50/75/90 %) et du palier de rythme
(0,8 / 1,1 / 1,5), violet à 100 %. Si vous modifiez l'une, modifiez l'autre.

## Bascule compacte / détaillée
Bouton ⤢ / ⤡ en haut à droite de la fenêtre, ou touche `d`. La fenêtre est redimensionnée (`WINDOW_SIZE` / `WINDOW_SIZE_DETAIL`)
et déplacée à la dernière position connue de la vue choisie. La dernière vue et la position de chaque vue sont mémorisées par
le serveur dans `data/state.json` (non versionné) ; `launch.sh` rouvre la dernière vue avec sa taille et sa position.
Limite : la position lue par la page (`window.screenX/Y`) est à quelques pixels près et ignorée quand le navigateur renvoie 0,0.

## Mode debug
`./install.sh --debug` (ou `DEBUG='1'` dans `config.env`) crée en plus le raccourci « Quota Claude (debug) » : fenêtre PowerShell
visible, trace détaillée dans `data/launch.log`, requêtes HTTP dans `data/server.log`. Le raccourci normal reste silencieux
(journal des étapes seulement). Ponctuellement : `QUOTA_DEBUG=1 ./launch.sh`.
Note : `server.log` n'est alimenté que si le serveur est démarré par le raccourci de debug (arrêtez-le avant si un lancement normal l'a déjà démarré).
