// Hero scene, after Cartons. The keyboard under the title types real quotes from the test, cycling 50, 90, 120 and
// 200 wpm; now and then a neighbouring key flashes blue, the slip is fixed, and the five keys missed most that run keep
// a blue ring, the way the result screen shows them. Loose keycaps drift at three depths. Every layer eases toward the
// scroll position at its own speed, and the scene leans away from the pointer on desktop. Reduced motion gets a still scene.
import { QUOTES } from './words.js';
const still = matchMedia('(prefers-reduced-motion: reduce)').matches;
const el = (t, c, x) => { const e = document.createElement(t); if (c) e.className = c; if (x != null) e.textContent = x; return e; };
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

const ROWS = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
const NEAR = {}; // keys next to each other on the board, for believable slips
ROWS.forEach((r, i) => [...r].forEach((ch, j) => {
  NEAR[ch] = [r[j - 1], r[j + 1], ROWS[i - 1]?.[j], ROWS[i - 1]?.[j + 1], ROWS[i + 1]?.[j], ROWS[i + 1]?.[j - 1]].filter(Boolean);
}));

const ground = document.querySelector('.ground'), board = document.getElementById('kboard');
const keys = {};
if (board) {
  const kb = board.appendChild(el('div', 'kb'));
  for (const r of ROWS) { const row = kb.appendChild(el('div', 'kb-row')); for (const ch of r) keys[ch] = row.appendChild(el('span', 'key', ch)); }
  keys[' '] = kb.appendChild(el('div', 'kb-row')).appendChild(el('span', 'key space'));
  if (still) { ['e', 't', 'a', 'h', 'n'].forEach((k) => keys[k].classList.add('worst')); }
  else queueMicrotask(demo); // after the module has run, so the constants below exist
}

// The demo: each run types a line of a real quote at the next speed (50, 90, 120, 200 wpm), the typed text shows under
// the buttons, and when the run ends the result card further down shows what it scored. Time is counted from the
// scheduled waits, not the wall clock, so a throttled tab can't skew the number. It pauses while the page is hidden
// or scrolled away from both the hero and the card.
const SPEEDS = [50, 90, 120, 200];
const clip = (q, n = 64) => { if (q.length <= n) return q; const c = q.lastIndexOf(' ', n); return q.slice(0, c > 20 ? c : n); };
let onscreen = true;
const watched = [document.querySelector('.lp-hero'), document.getElementById('test')].filter(Boolean);
if ('IntersectionObserver' in window && watched.length) {
  const seen = new Map();
  const io = new IntersectionObserver((es) => { es.forEach((e) => seen.set(e.target, e.isIntersecting)); onscreen = [...seen.values()].some(Boolean); });
  watched.forEach((w) => io.observe(w));
}
const awake = async () => { while (document.hidden || !onscreen) await wait(400); };

async function demo() {
  const line = document.getElementById('dLine'), pace = document.getElementById('dWpm');
  const show = (typed, bad = '') => { if (!line) return; const t = typed.slice(-46); line.textContent = t; if (bad) line.appendChild(el('i', '', bad)); };
  await wait(700);
  for (let run = 0, q = Math.floor(Math.random() * QUOTES.length); ; run++, q++) {
    const wpm = SPEEDS[run % SPEEDS.length], beat = 12000 / wpm; // ms per character at this speed
    const text = clip(QUOTES[q % QUOTES.length].toLowerCase());
    const misses = {}, stamps = [];
    let t = 0, slips = 0, typed = '';
    const pass = async (ms) => { t += ms; await wait(ms); };
    if (pace) pace.textContent = wpm;
    show('');
    for (const ch of text) {
      await awake();
      const k = keys[ch], near = NEAR[ch];
      if (k && near && Math.random() < .02 + wpm / 6000) { // a slip, likelier when fast: the wrong key goes blue, then backspace
        const bad = keys[near[Math.floor(Math.random() * near.length)]];
        bad.classList.add('miss'); show(typed, bad.textContent); await pass(Math.max(160, beat * 1.6));
        bad.classList.remove('miss'); show(typed); await pass(Math.max(90, beat));
        misses[ch] = (misses[ch] || 0) + 1; slips++; ring(misses);
      }
      const down = Math.min(70, beat * .45);
      if (k) k.classList.add('down');
      typed += ch; show(typed); await pass(down);
      if (k) k.classList.remove('down');
      await pass(Math.max(8, beat * (.55 + Math.random() * .8) - down));
      stamps.push(t);
    }
    score(text.length, slips, t, stamps, misses, wpm);
    await pass(1600);
    ring({});
  }
}
function ring(misses) {
  const worst = Object.entries(misses).sort((a, b) => b[1] - a[1]).slice(0, 5).map(([k]) => k);
  for (const k in keys) keys[k].classList.toggle('worst', worst.includes(k));
}

// The result card: same convention as the test (five characters a word), accuracy counts each fixed slip.
function score(chars, slips, ms, stamps, misses, target) {
  const card = document.querySelector('.shot'); if (!card) return;
  const wpm = Math.round(chars / 5 / (ms / 60000)), acc = Math.round((chars / (chars + slips)) * 100);
  const N = 16, w = ms / N, pts = Array.from({ length: N }, (_, i) => stamps.filter((s) => s > i * w && s <= (i + 1) * w).length / 5 / (w / 60000));
  const sm = pts.map((_, i) => (pts[Math.max(0, i - 1)] + pts[i] + pts[Math.min(N - 1, i + 1)]) / 3);
  const lo = Math.min(...sm), hi = Math.max(...sm);
  const poly = sm.map((v, i) => `${Math.round((i * 300) / (N - 1))},${(52 - ((v - lo) / (hi - lo || 1)) * 42).toFixed(1)}`).join(' ');
  const worst = Object.entries(misses).sort((a, b) => b[1] - a[1]).slice(0, 5).map(([k]) => k);
  card.classList.add('swap');
  setTimeout(() => {
    card.querySelector('.shot-num').firstChild.textContent = wpm;
    card.querySelector('.shot-num span').textContent = acc + '%';
    card.querySelector('.shot-line polyline').setAttribute('points', poly);
    card.querySelectorAll('.shot-kb span').forEach((s) => s.classList.toggle('lit', worst.includes(s.textContent)));
    const cap = card.querySelector('.shot-cap'); if (cap) cap.textContent = `The keyboard up top, typing at ${target} wpm.`;
    card.setAttribute('aria-label', `A sample result: ${wpm} words per minute, ${acc} percent accuracy` + (worst.length ? `, the keys ${worst.join(', ')} missed most` : ', no keys missed'));
    card.classList.remove('swap');
  }, 220);
}

// Loose keycaps at three depths; the middle stays clear for the title.
const sky = document.getElementById('ksky');
const layers = [];
if (sky) {
  let seed = 7;
  const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  const few = innerWidth < 600;
  const letters = 'qwertyuiopasdfghjklzxcvbnm';
  const depths = [
    { cls: 'far', n: 12, size: 22, lag: .7, o: .45, tilt: 10, spin: .02 },
    { cls: 'mid', n: 9, size: 38, lag: .35, o: .7, tilt: 20, spin: .05 },
    { cls: 'near', n: 6, size: 68, lag: -.35, o: .95, tilt: 36, spin: .1 },
  ];
  for (const d of depths) {
    const layer = sky.appendChild(el('div', 'layer ' + d.cls));
    const n = few ? (d.cls === 'near' ? 0 : Math.ceil(d.n / 2)) : d.n;
    for (let i = 0; i < n; i++) {
      // stratified: alternate sides, each cap in its own slice of height, jittered, so none pile up
      const side = i % 2, slot = Math.floor(i / 2), slots = Math.ceil(n / 2);
      const band = d.cls === 'far' ? 24 : 13; // big caps keep to the edges, clear of the headline
      const x = side ? 98 - band + rnd() * band - 4 : 2 + rnd() * band;
      const y = 4 + (slot + .15 + rnd() * .7) * (78 / slots);
      const red = d.cls !== 'far' && rnd() < .2;
      const c = layer.appendChild(el('span', 'cap' + (red ? ' red' : ''), letters[(i * 11 + layers.length * 5 + 3) % letters.length]));
      c.style.cssText = `left:${x.toFixed(1)}%;top:${y.toFixed(1)}%;--s:${d.size}px;opacity:${d.o};` +
        `animation-duration:${(5 + rnd() * 5).toFixed(1)}s;animation-delay:${(-rnd() * 10).toFixed(1)}s;--r:${Math.round(rnd() * 40 - 20)}deg`;
      c.dataset.spin = ((rnd() < .5 ? -1 : 1) * d.spin * (.6 + rnd() * .8)).toFixed(3);
    }
    layers.push({ layer, lag: d.lag, tilt: d.tilt, caps: [...layer.children] });
  }
}

// Parallax, eased toward the target each frame so a flick of the wheel glides. The copy lifts and fades.
const copy = document.querySelector('.lp-hero .hero-copy');
if (!still) {
  const now = { y: scrollY, px: 0, py: 0 }, goal = { y: scrollY, px: 0, py: 0 };
  let running = false;
  const frame = () => {
    let moving = false;
    for (const k in now) {
      const d = goal[k] - now[k];
      now[k] = Math.abs(d) < .05 ? goal[k] : now[k] + d * .12;
      if (now[k] !== goal[k]) moving = true;
    }
    const y = now.y;
    if (y < innerHeight * 1.4) {
      if (ground) ground.style.transform = `translate3d(${(now.px * 8).toFixed(2)}px,${(y * .55 + now.py * 5).toFixed(2)}px,0)`;
      for (const { layer, lag, tilt, caps } of layers) {
        layer.style.transform = `translate3d(${(now.px * tilt).toFixed(2)}px,${(y * lag + now.py * tilt * .6).toFixed(2)}px,0)`;
        for (const c of caps) c.style.rotate = `${(y * c.dataset.spin).toFixed(2)}deg`;
      }
      if (copy) { copy.style.transform = `translate3d(0,${(y * .2).toFixed(2)}px,0)`; copy.style.opacity = Math.max(0, 1 - y / (innerHeight * .7)); }
    }
    running = moving;
    if (moving) requestAnimationFrame(frame);
  };
  const kick = () => { if (!running) { running = true; requestAnimationFrame(frame); } };
  addEventListener('scroll', () => { goal.y = scrollY; kick(); }, { passive: true });
  if (matchMedia('(pointer: fine)').matches) addEventListener('pointermove', (e) => {
    goal.px = -(e.clientX / innerWidth - .5) * 2; goal.py = -(e.clientY / innerHeight - .5) * 2; kick();
  }, { passive: true });
}
