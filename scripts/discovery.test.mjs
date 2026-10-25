import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { origin, guides } from '../content/discovery.mjs';
const root = new URL('../',import.meta.url);
const read = path => readFile(new URL(path,root),'utf8');

test('homepage is readable before JavaScript and links to each guide', async () => {
 const html = await read('index.html');
 assert.match(html, /<h1[^>]*>Your ingredients/);
 assert.equal((html.match(/<h1\b/g)||[]).length, 1);
 assert.match(html, /id="root"><div class="landing-page"/);
 for (const guide of guides) assert.ok(html.includes(`/guides/${guide.slug}.html`));
 assert.match(html, /href="\/\?view=KITCHEN"/);
});
test('every guide has unique canonical metadata and valid JSON-LD', async () => {
 const titles = new Set();
 for (const guide of guides) {
  const html = await read(`public/guides/${guide.slug}.html`);
  assert.ok(html.includes(`<link rel="canonical" href="${origin}/guides/${guide.slug}.html">`));
  assert.equal((html.match(/<h1\b/g)||[]).length, 1);
  const title = html.match(/<title>(.*?)<\/title>/)[1];
  assert.ok(!titles.has(title)); titles.add(title);
  const schema = JSON.parse(html.match(/<script type="application\/ld\+json">(.*?)<\/script>/)[1]);
  assert.equal(schema.url, `${origin}/guides/${guide.slug}.html`);
  assert.equal(schema.breadcrumb.itemListElement[1].item, schema.url);
  for (const [,body] of guide.sections) assert.ok(html.includes(body));
 }
});
test('sitemap and robots expose the public pages, not account or billing state', async () => {
 const sitemap = await read('public/sitemap.xml');
 const robots = await read('public/robots.txt');
 assert.ok(robots.includes(`Sitemap: ${origin}/sitemap.xml`));
 assert.ok(!sitemap.includes('?view=')); assert.ok(!sitemap.includes('/billing/'));
 for (const guide of guides) assert.ok(sitemap.includes(`${origin}/guides/${guide.slug}.html`));
});
test('all local static guide links resolve to files or supported application routes', async () => {
 for (const guide of guides) {
  const html = await read(`public/guides/${guide.slug}.html`);
  for (const [,href] of html.matchAll(/href="(\/[^"?#]*)/g)) {
   if (href === '/') continue;
   const path = href.endsWith('.html') || href.endsWith('.css') ? href : href+'.html';
   assert.ok((await read('public'+path)).length > 0, href);
  }
 }
});

test('worked examples expose real dish details and actionable pantry links', async () => {
 const html = await read('public/pantry-examples.html');
 assert.match(html, /Tomato Scrambled Eggs/);
 assert.match(html, /Core ingredients still missing/);
 assert.match(html, /view=KITCHEN&amp;starter=eggs-tomatoes/);
 assert.match(await read('public/sitemap.xml'), /pantry-examples.html/);
 assert.match(await read('index.html'), /href="\/pantry-examples.html"/);
});
