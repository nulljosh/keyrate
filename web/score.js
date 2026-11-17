// Pure scoring. Words = every 5 chars typed (incl. spaces), the 10fastfingers/Monkeytype convention.
export function stats(typed, target, seconds) {
  let correct = 0, wrong = 0, correctWords = 0
  typed.forEach((w, i) => {
    const t = target[i] ?? ''
    if (w === t) correctWords++
    for (let c = 0; c < w.length; c++) (w[c] === t[c] ? correct++ : wrong++)
    if (i < typed.length - 1) (w === t ? correct++ : wrong++) // the space after a word counts
  })
  const min = Math.max(seconds, 0.001) / 60
  const total = correct + wrong
  return {
    wpm: Math.round(correct / 5 / min),
    raw: Math.round(total / 5 / min),
    accuracy: total ? Math.round((correct / total) * 100) : 100,
    correct, wrong, correctWords,
  }
}

// Consistency, Monkeytype's way: how even the keystrokes per second were, 0 to 100. cv is the spread over the
// mean, and the tanh series bends it so 100 is perfectly even and a ragged run drops fast.
export function consistency(perSecond) {
  if (perSecond.length < 2) return 100
  const mean = perSecond.reduce((a, b) => a + b, 0) / perSecond.length
  if (!mean) return 0
  const cv = Math.sqrt(perSecond.reduce((a, b) => a + (b - mean) ** 2, 0) / perSecond.length) / mean
  return Math.round(100 * (1 - Math.tanh(cv + cv ** 3 / 3 + cv ** 5 / 5)))
}

// The key a keystroke should have been, or null if it was right. c is the position in the typed word w, and
// c === w.length is the space after it: an extra letter should have been the space, an early space the next letter.
export function missedKey(w, t, c) {
  if (c < w.length) return w[c] === t[c] ? null : (t[c] ?? ' ').toLowerCase()
  return c < t.length ? t[c].toLowerCase() : null
}

// The five keys a run missed most, worst first, ties in key order, as [key, misses] pairs.
export function topMisses(misses) {
  return Object.entries(misses).sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : 1)).slice(0, 5)
}

// The line under the keyboard on the result.
export function missedLine(top) {
  return top.length ? 'missed most: ' + top.map(([k, n]) => `${k === ' ' ? 'space' : k} ${n}`).join(' · ') : 'no keys missed'
}

// The keyboard the result draws, a space bar under three letter rows.
export const KEY_ROWS = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm', ' ']

// Drill: the words that hit your weak keys hardest. Keeps the words holding at least one weak key, most weak letters
// first, and falls back to the whole list when that leaves fewer than `min` (too few to stay random).
export function drillPool(words, weak, min = 60) {
  const set = new Set(weak.filter(k => /^[a-z]$/.test(k)))
  if (!set.size) return words
  // ranked by the share of the word that is weak letters, so short words count as much as long ones
  const ranked = words.map(w => [w, [...w].reduce((n, c) => n + set.has(c), 0) / w.length]).filter(([, r]) => r > 0).sort((a, b) => b[1] - a[1])
  return ranked.length >= min ? ranked.slice(0, Math.max(min, Math.ceil(ranked.length / 2))).map(([w]) => w) : words
}

// The letters you miss most often for how often you type them, smoothed so one slip on a rare key does not top the
// list. `misses` and `seen` are per-key counts saved across runs. Letters only: space and marks are not drillable.
export function weakKeys(misses = {}, seen = {}, n = 5) {
  return Object.keys(misses).filter(k => /^[a-z]$/.test(k) && misses[k] > 0)
    .map(k => [k, (misses[k] + 0.5) / ((seen[k] || 0) + 10)]).sort((a, b) => b[1] - a[1]).slice(0, n).map(([k]) => k)
}

// How often each letter came up in the words typed this run, the denominator for weakKeys.
export function seenKeys(target, typedCount) {
  const out = {}
  for (const w of target.slice(0, typedCount)) for (const c of w.toLowerCase()) out[c] = (out[c] || 0) + 1
  return out
}

// Misses across runs: each run adds its counts and older ones fade by a tenth, so the drill follows how you type now.
export function mergeMisses(saved, run) {
  const out = {}
  for (const [k, v] of Object.entries(saved || {})) out[k] = v * 0.9
  for (const [k, v] of Object.entries(run || {})) out[k] = (out[k] || 0) + v
  return out
}
