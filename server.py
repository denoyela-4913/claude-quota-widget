#!/usr/bin/env python3
"""Sert les pages quota Claude (compacte / detaillee), le JSON ecrit par statusline.py
et l'etat de la fenetre (vue courante + position de chaque vue) sur 127.0.0.1:<PORT>."""
import http.server, json, os, threading

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "data")
JSON = os.path.join(DATA, "quota-status.json")
STATE = os.path.join(DATA, "state.json")
LOG = os.path.join(DATA, "server.log")

def conf():
    c = {}
    try:
        for line in open(os.path.join(HERE, "config.env")):
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                c[k.strip()] = v.strip().strip("'\"")
    except OSError:
        pass
    return c

CONF = conf()
PORT = int(CONF.get("PORT", 8765))
DEBUG = os.environ.get("QUOTA_DEBUG") == "1"

def size(key, default):
    try:
        w, h = CONF.get(key, default).split(",")
        return [int(w), int(h)]
    except ValueError:
        return [int(x) for x in default.split(",")]

SIZES = {"compact": size("WINDOW_SIZE", "300,230"), "detail": size("WINDOW_SIZE_DETAIL", "490,490")}
PAGES = {"/": ("index.html", "text/html; charset=utf-8"), "/detail": ("detail.html", "text/html; charset=utf-8"),
         "/common.js": ("common.js", "application/javascript; charset=utf-8")}
LOCK = threading.Lock()

def read_state():
    try:
        return json.load(open(STATE))
    except (OSError, ValueError):
        return {"view": "compact", "pos": {}}

def merge_state(patch):
    with LOCK:
        st = read_state()
        if patch.get("view") in SIZES:
            st["view"] = patch["view"]
        for v, p in (patch.get("pos") or {}).items():
            if v in SIZES and isinstance(p, list) and len(p) == 2 and all(isinstance(n, int) for n in p):
                st.setdefault("pos", {})[v] = p
        os.makedirs(DATA, exist_ok=True)
        tmp = STATE + ".tmp"
        json.dump(st, open(tmp, "w"))
        os.replace(tmp, STATE)
        return st

class H(http.server.BaseHTTPRequestHandler):
    def send(self, body, ctype):
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/quota.json":
            try:
                self.send(open(JSON, "rb").read(), "application/json")
            except OSError:
                self.send(b"{}", "application/json")
        elif path == "/state.json":
            self.send(json.dumps(read_state()).encode(), "application/json")
        elif path == "/config.json":
            self.send(json.dumps(SIZES).encode(), "application/json")
        else:
            name, ctype = PAGES.get(path, PAGES["/"])
            self.send(open(os.path.join(HERE, name), "rb").read(), ctype)

    def do_POST(self):
        if self.path.split("?")[0] != "/state":
            self.send_error(404)
            return
        try:
            patch = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        except ValueError:
            patch = {}
        self.send(json.dumps(merge_state(patch)).encode(), "application/json")

    def log_message(self, fmt, *a):
        if DEBUG:
            with open(LOG, "a") as f:
                f.write("%s %s\n" % (self.log_date_time_string(), fmt % a))

http.server.ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
