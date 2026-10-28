#!/usr/bin/env python3
"""Sert la page quota Claude + le JSON ecrit par statusline.py (127.0.0.1:<PORT>)."""
import http.server, os

HERE = os.path.dirname(os.path.abspath(__file__))
JSON = os.path.join(HERE, "data", "quota-status.json")

def port():
    try:
        for line in open(os.path.join(HERE, "config.env")):
            if line.startswith("PORT="):
                return int(line.split("=", 1)[1].strip().strip("'\""))
    except (OSError, ValueError):
        pass
    return 8765

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
    def log_message(self, *a): pass

http.server.ThreadingHTTPServer(("127.0.0.1", port()), H).serve_forever()
