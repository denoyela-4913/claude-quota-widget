// Bascule compacte <-> detaillee : bouton + touche "d". Redimensionne et repositionne la fenetre ;
// la vue courante et la position de chaque vue sont memorisees cote serveur (data/state.json).
// Couleur du modele, comme la statusline (statusline.py) : haiku vert, sonnet jaune, opus orange, fable/mythos violet, autre gris.
// dark=true : teintes du terminal (fond sombre) ; sinon teintes plus sombres si le theme systeme est clair.
window.modelColor = function (model, dark) {
  const k = String(model || "").toLowerCase();
  const light = !dark && window.matchMedia && matchMedia("(prefers-color-scheme: light)").matches;
  const P = light ? { haiku: "#00a844", sonnet: "#a39600", opus: "#d96c00", fable: "#7a4fd6", grey: "#6b6b6b" }
                  : { haiku: "#00d75f", sonnet: "#ffff00", opus: "#ff8700", fable: "#af87ff", grey: "#8a8a8a" };
  return k.includes("haiku") ? P.haiku : k.includes("sonnet") ? P.sonnet : k.includes("opus") ? P.opus
       : (k.includes("fable") || k.includes("mythos")) ? P.fable : P.grey;
};

// Couleur du contexte, memes paliers que la statusline : vert < 50 %, jaune < 70 %, orange < 85 %, rouge au-dela.
window.ctxColor = function (p) {
  return p < 50 ? "#3fb950" : p < 70 ? "#d29922" : p < 85 ? "#db6d28" : "#f85149";
};

(function () {
  const VIEW = document.documentElement.dataset.view;           // "compact" | "detail"
  const OTHER = VIEW === "compact" ? "detail" : "compact";
  // screenX/Y valent 0 (et outerWidth 0) juste apres une navigation : on ignore ces lectures
  const curPos = () => (window.outerWidth > 0 && (window.screenX !== 0 || window.screenY !== 0) ? [window.screenX, window.screenY] : null);
  const post = (patch) => fetch("/state", { method: "POST", body: JSON.stringify(patch) }).catch(() => {});

  // --- bouton ---
  const b = document.createElement("button");
  b.textContent = VIEW === "compact" ? "⤢" : "⤡";      // ⤢ agrandir / ⤡ reduire
  b.title = (VIEW === "compact" ? "Vue détaillée" : "Vue compacte") + " (touche d)";
  b.style.cssText = "position:fixed;top:4px;right:6px;z-index:9;border:0;background:transparent;color:inherit;" +
                    "opacity:.45;font-size:16px;line-height:1;cursor:pointer;padding:2px 4px";
  b.onmouseenter = () => (b.style.opacity = 1);
  b.onmouseleave = () => (b.style.opacity = .45);
  document.addEventListener("DOMContentLoaded", () => document.body.append(b));

  function toggle() {
    const pos = curPos();
    post({ view: OTHER, pos: pos ? { [VIEW]: pos } : {} })
      .finally(() => (location.href = OTHER === "detail" ? "/detail" : "/"));
  }
  b.onclick = toggle;
  document.addEventListener("keydown", (e) => {
    if ((e.key === "d" || e.key === "D") && !e.ctrlKey && !e.metaKey && !e.altKey) toggle();
  });

  // --- taille / position de cette vue ---
  (async () => {
    try {
      const [cfg, st] = await Promise.all([fetch("/config.json").then((r) => r.json()), fetch("/state.json").then((r) => r.json())]);
      const [w, h] = cfg[VIEW];
      if (window.outerWidth !== w || window.outerHeight !== h) window.resizeTo(w, h);
      const p = (st.pos || {})[VIEW];
      if (p && (window.screenX !== p[0] || window.screenY !== p[1])) window.moveTo(p[0], p[1]);
    } catch (e) {}
    // memorise la position quand l'utilisateur deplace la fenetre
    let last = curPos();
    setInterval(() => {
      const cur = curPos();
      if (cur && (!last || cur[0] !== last[0] || cur[1] !== last[1])) { last = cur; post({ pos: { [VIEW]: cur } }); }
    }, 2000);
  })();
})();
