import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { origin, title, description, guides, guideLinks, landingHtml, structuredData, escapeHtml } from '../content/discovery.mjs';
const root = new URL('../', import.meta.url);
const json = value => JSON.stringify(value).replaceAll('<', '\\u003c');
const metadata = (pageTitle, summary, url) => `<title>${escapeHtml(pageTitle)}</title>
<meta name="description" content="${escapeHtml(summary)}">
<link rel="canonical" href="${url}">
<meta name="robots" content="index,follow,max-image-preview:large">
<meta property="og:type" content="website"><meta property="og:site_name" content="Kitchen Diary">
<meta property="og:title" content="${escapeHtml(pageTitle)}"><meta property="og:description" content="${escapeHtml(summary)}"><meta property="og:url" content="${url}">
<meta property="og:image" content="${origin}/images/kitchen-editorial-hero.png"><meta property="og:image:alt" content="A warm bowl of pasta ready to share">
<meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="${escapeHtml(pageTitle)}"><meta name="twitter:description" content="${escapeHtml(summary)}"><meta name="twitter:image" content="${origin}/images/kitchen-editorial-hero.png">`;
let index = await readFile(new URL('index.html', root), 'utf8');
index = index.replace(/<!-- discovery-head:start -->[\s\S]*?<!-- discovery-head:end -->/, `<!-- discovery-head:start -->\n${metadata(title, description, origin+'/')}\n<script type="application/ld+json">${json(structuredData)}</script>\n<!-- discovery-head:end -->`);
index = index.replace(/<!-- discovery-body:start -->[\s\S]*?<!-- discovery-body:end -->/, `<!-- discovery-body:start --><div id="root">${landingHtml}</div><!-- discovery-body:end -->`);
await writeFile(new URL('index.html', root), index);
await mkdir(new URL('public/guides/', root), {recursive:true});
for (const guide of guides) {
 const url = `${origin}/guides/${guide.slug}.html`;
 const schema = {'@context':'https://schema.org','@type':'WebPage',name:guide.title,description:guide.description,url,inLanguage:'en',isPartOf:{'@id':origin+'/#website'},breadcrumb:{'@type':'BreadcrumbList',itemListElement:[{'@type':'ListItem',position:1,name:'Kitchen Diary',item:origin+'/'},{'@type':'ListItem',position:2,name:guide.title,item:url}]}};
 await writeFile(new URL(`public/guides/${guide.slug}.html`,root), `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">${metadata(guide.title+' | Kitchen Diary',guide.description,url)}<link rel="stylesheet" href="/discovery.css"><script type="application/ld+json">${json(schema)}</script></head><body><div class="guide-shell"><header><a href="/">Kitchen Diary</a><nav aria-label="Main"><a href="/?view=KITCHEN">Your pantry</a><a href="/?view=BUILDER">Recipe builder</a></nav></header><main><p class="eyebrow">Kitchen Diary guides</p><h1>${guide.title}</h1><p class="intro">${guide.description}</p>${guide.sections.map(([heading,body])=>`<section><h2>${heading}</h2><p>${body}</p></section>`).join('')}<p><a class="cta" href="/?view=KITCHEN">Explore your pantry →</a></p><aside aria-label="Related guides"><h2>Keep exploring</h2><ul>${guideLinks}</ul></aside></main><footer><a href="/">Home</a><a href="/support">Support</a><a href="/privacy">Privacy</a></footer></div></body></html>`);
}
await writeFile(new URL('public/robots.txt',root), `User-agent: *\nAllow: /\nDisallow: /api/\nDisallow: /billing/\n\nSitemap: ${origin}/sitemap.xml\n`);
await writeFile(new URL('public/sitemap.xml',root), `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${['/',...guides.map(g=>'/guides/'+g.slug+'.html'),'/support','/privacy','/terms','/account-deletion'].map(path=>`<url><loc>${origin}${path}</loc></url>`).join('')}</urlset>\n`);
console.log(`Generated crawlable homepage and ${guides.length} guides.`);
