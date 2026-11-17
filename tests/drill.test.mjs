import { test } from 'node:test'
import assert from 'node:assert/strict'
import { drillPool, mergeMisses } from '../web/score.js'
import { WORDS } from '../web/words.js'

test('drill keeps words with a weak key, most hits first', () => {
  const pool = drillPool(WORDS, ['q', 'z', 'x'], 5)
  assert.ok(pool.length >= 5)
  assert.ok(pool.every(w => /[qzx]/.test(w)))
  const hits = w => [...w].filter(c => 'qzx'.includes(c)).length
  assert.ok(hits(pool[0]) >= hits(pool[pool.length - 1]))
})

test('drill falls back to every word when the weak keys are too rare or unknown', () => {
  assert.equal(drillPool(WORDS, []), WORDS)
  assert.equal(drillPool(WORDS, [' ', ',']), WORDS)
  const few = ['cat', 'dog']
  assert.equal(drillPool(few, ['q'], 60), few)
})

test('misses fade by a tenth each run and add up', () => {
  assert.deepEqual(mergeMisses({ e: 10 }, { e: 1, t: 2 }), { e: 10, t: 2 })
  assert.deepEqual(mergeMisses(null, { a: 1 }), { a: 1 })
})

import { weakKeys, seenKeys } from '../web/score.js'
test('weak keys rank by miss rate, letters only', () => {
  const misses = { e: 6, q: 2, ' ': 9, ',': 4 }, seen = { e: 300, q: 3 }
  assert.deepEqual(weakKeys(misses, seen), ['q', 'e'])
})
test('seen counts the letters of the words typed', () => {
  assert.deepEqual(seenKeys(['ab', 'a', 'zz'], 2), { a: 2, b: 1 })
})
