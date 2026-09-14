import { describe, expect, it } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

describe('production product branding', () => {
  it('uses only Kitchen Diary across web copy and metadata', () => {
    const retired = new RegExp('cook' + 'toon', 'i');
    const files = ['index.html', 'metadata.json', 'package.json', 'package-lock.json', 'README.md'];
    const walk = (directory: string) => {
      for (const entry of readdirSync(directory, { withFileTypes: true })) {
        const path = join(directory, entry.name);
        if (entry.isDirectory()) walk(path);
        else if (/\.(tsx?|html|json)$/.test(entry.name)) files.push(path);
      }
    };
    walk('components');
    walk('public');
    for (const file of files) expect(readFileSync(file, 'utf8'), file).not.toMatch(retired);
    expect(readFileSync('components/Profile.tsx', 'utf8')).toContain('Kitchen Diary');
    expect(readFileSync('index.html', 'utf8')).toContain('<title>Kitchen Diary</title>');
  });
});
