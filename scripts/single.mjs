// Bundles the test (web/app/index.html and its modules) into one self-contained HTML file for places that serve a
// single file with no internet: joshuatree on the Pi (tools/gen/gen_app.sh embeds it in the kernel).
// node scripts/single.mjs [out]   (default dist/keyrate.html)
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const web = join(dirname(fileURLToPath(import.meta.url)), '..', 'web')
const out = process.argv[2] || join(web, '..', 'dist', 'keyrate.html')
const read = (f) => readFileSync(join(web, f), 'utf8')
// a module's body with its imports dropped and `export` stripped, so the files can share one script scope
const body = (f) => read(f).replace(/^import .*$/gm, '').replace(/^export (?=(const|function|class|let) )/gm, '')

let html = read('app/index.html')
const modules = ['words.js', 'score.js', 'session.js'].map((f) => `// ${f}\n${body(f)}`).join('\n')
html = html.replace(/<script type="module">\n(import .*\n)+/, () => `<script type="module">\n${modules}\n// app\n`)
// the palette inline, plus the token names the shared jaybulb.com stylesheet would have defined
const tokens = ':root{--bg:var(--color-bg);--bg2:var(--color-bg2);--text:var(--color-text);--text2:var(--color-secondary);--border:var(--color-hairline);--font-body:-apple-system,BlinkMacSystemFont,"Helvetica Neue",Arial,sans-serif}'
html = html.replace(/<link rel="stylesheet" href="https:\/\/jaybulb\.com\/tokens\.css">\n?/, '')
html = html.replace(/<link rel="stylesheet" href="\/palette\.css[^"]*">/, () => `<style>${tokens}\n${read('palette.css')}</style>`)
html = html.replace(/<link rel="stylesheet" href="\/fonts\/fonts\.css">\n?/, '')
// links to pages this file doesn't come with: home, account, the canonical and the icon
html = html.replace(/<a class="corner[^\n]*\n/g, '').replace(/<script>\/\* signed in on this browser[^\n]*\n/, '')
html = html.replace(/<link rel="(canonical|icon)"[^>]*>\n?/g, '')
if (/from '\.\.?\//.test(html) || /https?:\/\/jaybulb/.test(html)) throw new Error('single.mjs: an import or remote file is left')
mkdirSync(dirname(out), { recursive: true })
writeFileSync(out, html)
console.log(`${out} ${(html.length / 1024).toFixed(1)} KB`)
