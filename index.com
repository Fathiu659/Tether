<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Tether</title>
<link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:wght@600;800&family=Figtree:wght@400;600&display=swap" rel="stylesheet">
<style>
:root{--bg:#f2f0fa;--card:#fff;--ink:#1d1a3b;--mute:#6c6890;--line:#e0dcf2;--accent:#3a4bdc;--on:#fff;--follow:#0c8f8f;color-scheme:light;box-sizing:border-box;padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#15132b;--card:#201d3d;--ink:#eeecff;--mute:#a09cc8;--line:#33305a;--accent:#8b97ff;--on:#15132b;--follow:#4fd1c5;color-scheme:dark}}
*{box-sizing:border-box}
html{scroll-padding-top:env(safe-area-inset-top,0px)}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.5 Figtree,system-ui,sans-serif}
#app{max-width:560px;margin:0 auto;padding:16px}
h1,.logo{font-family:"Bricolage Grotesque",system-ui,sans-serif;font-weight:800;letter-spacing:-.02em;margin:0}
.top{display:flex;justify-content:space-between;align-items:center;margin-bottom:16px}
.logo{font-size:28px}
.box{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:14px;margin-bottom:12px}
textarea,input{width:100%;font:inherit;color:var(--ink);background:var(--bg);border:1px solid var(--line);border-radius:10px;padding:10px}
textarea{resize:vertical;min-height:72px}
button{font:inherit;font-weight:600;cursor:pointer;border-radius:999px;border:1px solid var(--accent);background:transparent;color:var(--accent);padding:6px 14px}
button.main{background:var(--accent);color:var(--on)}
button.fol{border-color:var(--follow);color:var(--follow)}
button.fol.on{background:var(--follow);color:var(--on)}
button:focus-visible,textarea:focus-visible,input:focus-visible{outline:3px solid var(--accent);outline-offset:2px}
.row{display:flex;gap:10px;align-items:center}
.sp{justify-content:space-between;margin-top:8px}
.av{flex:none;width:40px;height:40px;border-radius:50%;display:grid;place-items:center;color:#fff;font-weight:800}
.name{font-weight:600}.mute{color:var(--mute);font-size:14px}
.tabs{display:flex;gap:8px;margin:16px 0 12px}
.tabs button.act{background:var(--accent);color:var(--on)}
.post p{margin:8px 0 10px;white-space:pre-wrap;overflow-wrap:anywhere}
.people{display:flex;gap:10px;overflow-x:auto;padding-bottom:4px}
.person{flex:none;width:112px;text-align:center}
.person .av{margin:0 auto 6px}
.person button{margin-top:6px}
.empty{text-align:center;color:var(--mute);padding:24px 8px}
</style>
</head>
<body>
<main id="app"></main>
<script>
var KEY = 'tether-v1';
var S = null;
try { S = JSON.parse(localStorage.getItem(KEY)); } catch (e) { S = null; }
function seed() {
  var n = Date.now(), m = 60000;
  return { me: '', tab: 'all', follows: [], posts: [
    { id: 1, user: 'Maya', t: n - 12 * m, text: 'Found a tiny bakery that opens at 6am. Worth the early alarm.', likes: ['Dev'] },
    { id: 2, user: 'Dev', t: n - 95 * m, text: 'Finally finished my first 10k. Legs say no, heart says yes.', likes: ['Maya', 'Lena'] },
    { id: 3, user: 'Lena', t: n - 400 * m, text: 'Anyone have book recommendations? Something I can’t put down.', likes: [] },
    { id: 4, user: 'Tomás', t: n - 1600 * m, text: 'Rainy Sunday, soup on the stove, good music on.', likes: ['Maya'] }
  ] };
}
if (!S || !S.posts) S = seed();
function save() { try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) {} }
function el(tag, cls, txt) { var e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; }
function avatar(name) {
  var a = el('span', 'av', name.charAt(0).toUpperCase()), h = 0;
  for (var i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) % 360;
  a.style.background = 'hsl(' + h + ' 50% 42%)';
  return a;
}
function ago(t) {
  var m = Math.floor((Date.now() - t) / 60000);
  return m < 1 ? 'now' : m < 60 ? m + 'm' : m < 1440 ? Math.floor(m / 60) + 'h' : Math.floor(m / 1440) + 'd';
}
function toggleFollow(u) {
  var i = S.follows.indexOf(u);
  if (i < 0) S.follows.push(u); else S.follows.splice(i, 1);
  save(); render();
}
function followBtn(u) {
  var on = S.follows.indexOf(u) >= 0;
  var b = el('button', 'fol' + (on ? ' on' : ''), on ? 'Following' : 'Follow');
  b.onclick = function () { toggleFollow(u); };
  return b;
}
function join(root) {
  var box = el('div', 'box');
  box.appendChild(el('h1', '', 'Tether'));
  box.appendChild(el('p', 'mute', 'Share what’s happening and follow people you like. Pick a name to start.'));
  var inp = el('input'); inp.placeholder = 'Your name'; inp.maxLength = 20; inp.setAttribute('aria-label', 'Your name');
  var b = el('button', 'main', 'Join Tether'); b.style.marginTop = '10px';
  b.onclick = function () {
    var v = inp.value.trim();
    if (v.length < 2) { inp.placeholder = 'Enter at least 2 characters'; inp.value = ''; inp.focus(); return; }
    S.me = v; save(); render();
  };
  box.appendChild(inp); box.appendChild(b); root.appendChild(box);
}
function render() {
  var root = document.getElementById('app');
  root.replaceChildren();
  if (!S.me) { join(root); return; }
  var top = el('div', 'top');
  top.appendChild(el('span', 'logo', 'Tether'));
  var out = el('button', '', 'Reset');
  out.onclick = function () { if (confirm('Clear everything and start over?')) { S = seed(); save(); render(); } };
  var who = el('div', 'row'); who.appendChild(el('span', 'mute', S.me)); who.appendChild(out);
  top.appendChild(who); root.appendChild(top);

  var comp = el('div', 'box');
  var ta = el('textarea'); ta.maxLength = 280; ta.placeholder = 'What’s on your mind?'; ta.setAttribute('aria-label', 'Write a post');
  var cnt = el('span', 'mute', '280'); ta.oninput = function () { cnt.textContent = 280 - ta.value.length; };
  var pb = el('button', 'main', 'Post');
  pb.onclick = function () {
    var v = ta.value.trim(); if (!v) { ta.focus(); return; }
    S.posts.unshift({ id: Date.now(), user: S.me, t: Date.now(), text: v, likes: [] });
    save(); render();
  };
  var r = el('div', 'row sp'); r.appendChild(cnt); r.appendChild(pb);
  comp.appendChild(ta); comp.appendChild(r); root.appendChild(comp);

  var names = [];
  S.posts.forEach(function (p) { if (p.user !== S.me && names.indexOf(p.user) < 0) names.push(p.user); });
  var sug = names.filter(function (n) { return S.follows.indexOf(n) < 0; });
  if (sug.length) {
    var pb2 = el('div', 'box'); pb2.appendChild(el('div', 'name', 'People to follow'));
    var pl = el('div', 'people'); pl.style.marginTop = '10px';
    sug.forEach(function (n) {
      var c = el('div', 'person'); c.appendChild(avatar(n)); c.appendChild(el('div', 'name', n)); c.appendChild(followBtn(n)); pl.appendChild(c);
    });
    pb2.appendChild(pl); root.appendChild(pb2);
  }

  var tabs = el('div', 'tabs');
  [['all', 'Everyone'], ['following', 'Following']].forEach(function (t) {
    var b = el('button', S.tab === t[0] ? 'act' : '', t[1]);
    b.onclick = function () { S.tab = t[0]; save(); render(); };
    tabs.appendChild(b);
  });
  root.appendChild(tabs);

  var list = S.posts.filter(function (p) { return S.tab === 'all' || p.user === S.me || S.follows.indexOf(p.user) >= 0; });
  if (!list.length) root.appendChild(el('div', 'empty', 'Nothing here yet. Follow someone or write the first post.'));
  list.forEach(function (p) {
    var c = el('article', 'box post'), h = el('div', 'row');
    h.appendChild(avatar(p.user));
    var meta = el('div'); meta.style.flex = '1';
    meta.appendChild(el('div', 'name', p.user)); meta.appendChild(el('div', 'mute', ago(p.t)));
    h.appendChild(meta);
    if (p.user !== S.me) h.appendChild(followBtn(p.user));
    c.appendChild(h); c.appendChild(el('p', '', p.text));
    var liked = p.likes.indexOf(S.me) >= 0;
    var lb = el('button', liked ? 'main' : '', (liked ? 'Liked' : 'Like') + ' · ' + p.likes.length);
    lb.onclick = function () {
      var i = p.likes.indexOf(S.me);
      if (i < 0) p.likes.push(S.me); else p.likes.splice(i, 1);
      save(); render();
    };
    c.appendChild(lb); root.appendChild(c);
  });
}
render();
</script>
</body>
</html>