import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const rules = readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8');

describe('Firestore account-data rules', () => {
  it('denies signed-in access while account deletion is in progress', () => {
    expect(rules).toContain('!exists(/databases/$(database)/documents/accountDeletions/$(request.auth.uid))');
  });
  it('restricts public profiles to a fixed public field allowlist', () => {
    const publicRules = rules.split('match /public_profiles/{uid} {')[1]?.split('// These documents')[0];
    expect(publicRules).toBeTruthy();
    const fields = publicRules.match(/data\.keys\(\)\.hasOnly\(\[([\s\S]*?)\]\)/)?.[1]
      .match(/'([^']+)'/g)?.map((field) => field.slice(1, -1));
    expect(fields).toEqual(['displayName', 'photoUrl', 'bio', 'avatarEmoji',
      'followers', 'following', 'recipesCount', 'likesReceived', 'badges']);
    expect(publicRules).toContain('allow read: if true;');
    expect(publicRules).toContain('uid == request.auth.uid && validPublicProfile()');
    expect(publicRules).toContain('allow update: if validPublicProfile()');
  });

  it('limits cross-account follower edits to the acting user only', () => {
    expect(rules).toContain("affectedKeys().hasOnly(['followers'])");
    expect(rules).toContain('after.difference(before).hasOnly([request.auth.uid])');
    expect(rules).toContain('before.difference(after).hasOnly([request.auth.uid])');
  });
  it('keeps full user profiles owner-only because they contain private fields', () => {
    expect(rules).toMatch(
      /match \/users\/\{uid\} \{\s*allow read: if signedIn\(\) && uid == request\.auth\.uid;/,
    );
    expect(rules).not.toMatch(/allow read: if signedIn\(\);/);
  });

  it('allows public recipe reads and author-only private recipe reads', () => {
    expect(rules).toMatch(
      /match \/recipes\/\{recipeId\} \{\s*allow read: if resource\.data\.isPublic == true \|\| isOwner\('authorId'\);/,
    );
    expect(rules).toMatch(
      /function isOwner\(field\) \{\s*return signedIn\(\) && resource\.data\[field\] == request\.auth\.uid;/,
    );
    expect(rules).not.toMatch(/resource\.data\.isPublic == true \|\| signedIn\(\)/);
  });

  it('keeps pantry state private to its authenticated owner', () => {
    expect(rules).toMatch(
      /match \/pantry\/\{documentId\} \{\s*allow read, write: if signedIn\(\) && uid == request\.auth\.uid;/,
    );
  });

  it('keeps recipe drafts private to their authenticated owner', () => {
    expect(rules).toMatch(
      /match \/recipeDrafts\/\{documentId\} \{\s*allow read, write: if signedIn\(\) && uid == request\.auth\.uid;/,
    );
  });

  it('retains the deny-by-default catch-all', () => {
    expect(rules).toMatch(/match \/\{document=\*\*\} \{\s*allow read, write: if false;/);
  });
});
