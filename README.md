# Quota Claude widget

Petite fenêtre (Chrome/Edge en mode `--app`, profil dédié) qui affiche les quotas 5h / 7j de Claude Code.

- `statusline.py` : statusline de Claude Code ; affiche la barre et écrit `data/quota-status.json`.
- `server.py` + `index.html` : page locale (127.0.0.1:PORT) rafraîchie toutes les 5 s.
- `launch.sh` : démarre le serveur et ouvre la fenêtre.
- `install.sh` : pose des questions (défauts = comptes Linux/Windows courants), écrit `config.env`
  (non versionné, voir `config.template.env`), crée le raccourci Bureau, branche `statusLine` dans `~/.claude/settings.json`.
- `uninstall.sh` : retire le raccourci, restaure `settings.json`.

## Installation (WSL)
    ./install.sh        # ou ./install.sh --yes pour accepter les défauts
Le dossier ne doit plus être déplacé après installation (les chemins sont absolus ; relancer `install.sh` sinon).
