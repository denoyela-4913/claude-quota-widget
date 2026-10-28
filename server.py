#!/usr/bin/env python3
"""Sert la page quota Claude + le JSON ecrit par statusline.py (127.0.0.1:<PORT>)."""
import http.server, os

HERE = os.path.dirname(os.path.abspath(__file__))
JSON = os.path.join(HERE, "data", "quota-status.json")

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
DEBUG = os.environ.get("QUOTA_DEBUG", CONF.get("DEBUG", "0")) == "1"
LOG = os.path.join(HERE, "data", "server.log")

class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/quota.json"):
            try:
                body, ctype = open(JSON, "rb").read(), "application/json"
            except OSError:
                body, ctype = b"{}", "application/json"
        else:
            body, ctype = open(os.path.join(HERE, "index.html"), "rb").read(), "text/html; charset=utf-8"
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, fmt, *a):
        if DEBUG:
            with open(LOG, "a") as f:
                f.write("%s %s\n" % (self.log_date_time_string(), fmt % a))

http.server.ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
