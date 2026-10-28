#!/usr/bin/env python3
import sys, json, os, time, datetime
try:
    d = json.load(sys.stdin)
except Exception:
    print("Claude"); sys.exit()

R = "\033[0m"
def c(n, s): return "\033[38;5;%dm%s%s" % (n, s, R)
GREEN, YELLOW, ORANGE, RED, DARK, GREY = 41, 220, 208, 196, 124, 245

def level(p, pace=None):
    # couleur selon le pourcentage absolu, aggravee par le rythme
    col = GREEN if p < 50 else YELLOW if p < 75 else ORANGE if p < 90 else RED
    if pace is not None and p >= 5:
        pc = GREEN if pace < 0.8 else YELLOW if pace < 1.1 else ORANGE if pace < 1.5 else RED
        col = {GREEN:0, YELLOW:1, ORANGE:2, RED:3}[pc] > {GREEN:0, YELLOW:1, ORANGE:2, RED:3}[col] and pc or col
    if p >= 100: col = DARK
    return col

snapshot = {"updated_at": time.time(), "windows": {}}

parts = []
mo = d.get("model") or {}
m = mo.get("display_name")
if m:
    key = ((mo.get("id") or "") + " " + m).lower()
    for name, mult, col in (("haiku", 1, GREEN), ("sonnet", 2, 226), ("opus", 4, ORANGE), ("fable", 10, 141), ("mythos", 10, 141)):
        if name in key:
            m = "%s (x%d)" % (m, mult)
            parts.append(c(col, m)); break
    else:
        parts.append(c(GREY, m))
    snapshot["model"] = m
cwd = (d.get("workspace") or {}).get("current_dir") or d.get("cwd")
if cwd: parts.append(c(GREY, os.path.basename(cwd.rstrip("/")) or cwd))

cw = (d.get("context_window") or {}).get("used_percentage")
if cw is not None:
    col = GREEN if cw < 50 else YELLOW if cw < 70 else ORANGE if cw < 85 else RED
    parts.append("Ctx " + c(col, "%d%%" % round(cw)))
    snapshot["context_used_percentage"] = cw

now = time.time()
rl = d.get("rate_limits") or {}
for key, label, span, fmt in (("five_hour", "5h", 5*3600, "%H:%M"), ("seven_day", "7j", 7*86400, "%d/%m %H:%M")):
    w = rl.get(key)
    if not w or w.get("used_percentage") is None: continue
    p = w["used_percentage"]
    r = w.get("resets_at")
    pace = None
    extra = ""
    if r:
        elapsed = min(max(1 - (r - now) / span, 0), 1) * 100
        if elapsed >= 5:
            pace = p / elapsed
            extra = " x%.1f" % pace
        extra += " ->%s" % datetime.datetime.fromtimestamp(r).strftime(fmt)
    col = level(p, pace)
    parts.append("%s " % label + c(col, "%d%%%s" % (round(p), extra)))
    snapshot["windows"][key] = {"label": label, "used_percentage": p, "resets_at": r, "pace": pace}
print(c(GREY, " | ").join(parts))

try:
    out_path = os.environ.get("QUOTA_STATUS_FILE") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "quota-status.json")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    tmp_path = out_path + ".tmp"
    with open(tmp_path, "w") as f:
        json.dump(snapshot, f)
    os.replace(tmp_path, out_path)
except Exception:
    pass
