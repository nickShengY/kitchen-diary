import { beforeEach, describe, expect, it } from 'vitest';
import { getSharedPosts, removeSharedPost, shareRecipeToCommunity } from '../../services/communityStore';
import { RecipeStep } from '../../types';

const STORAGE_KEY = 'kitchendiary.sharedPosts.v1';

const sampleSteps: RecipeStep[] = [
  {
    id: 'step-1',
    station: 'prep',
    ingredients: [{ id: 'tomato', amount: '1', unit: 'pc' }],
    toolId: 'knife',
    actionId: 'chop',
  },
];

describe('communityStore', () => {
  beforeEach(() => {
    window.localStorage.clear();
  });

  it('shares a recipe and reads it back', () => {
    const post = shareRecipeToCommunity({
      title: 'Tomato Salad',
      description: 'Fresh and quick.',
      tags: ['Healthy'],
      steps: sampleSteps,
    });

    const posts = getSharedPosts();
    expect(posts).toHaveLength(1);
    expect(posts[0].id).toBe(post.id);
    expect(posts[0].title).toBe('Tomato Salad');
    expect(posts[0].imageUrl).toMatch(/^data:image\/svg\+xml/);
  });

  it('removes a shared post', () => {
    const post = shareRecipeToCommunity({
      title: 'Soup',
      description: '',
      tags: [],
      steps: sampleSteps,
    });
    removeSharedPost(post.id);
    expect(getSharedPosts()).toHaveLength(0);
  });

  it('normalizes tampered or legacy posts instead of crashing', () => {
    window.localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify([
        { id: 'legacy-1', title: 'Legacy post' }, // missing every optional field
        { id: 42, title: 'bad id' },
        'not-an-object',
        null,
      ]),
    );

    const posts = getSharedPosts();
    expect(posts).toHaveLength(1);
    const post = posts[0];
    expect(post.description).toBe('');
    expect(post.tags).toEqual([]);
    expect(post.steps).toEqual([]);
    expect(post.createdAt).toBe(0);
    // These derived reads are exactly what the Community feed does.
    expect(() => post.description.toLowerCase()).not.toThrow();
    expect(() => post.tags.includes('Dinner')).not.toThrow();
  });

  it('drops unsafe image URLs from stored posts', () => {
    window.localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify([
        { id: 'p1', title: 'ok https', imageUrl: 'https://example.com/pic.jpg' },
        { id: 'p2', title: 'ok data', imageUrl: 'data:image/png;base64,AAAA' },
        { id: 'p3', title: 'bad scheme', imageUrl: 'javascript:alert(1)' },
        { id: 'p4', title: 'bad http', imageUrl: 'http://example.com/pic.jpg' },
      ]),
    );

    const byId = new Map(getSharedPosts().map((post) => [post.id, post]));
    expect(byId.get('p1')?.imageUrl).toBe('https://example.com/pic.jpg');
    expect(byId.get('p2')?.imageUrl).toBe('data:image/png;base64,AAAA');
    expect(byId.get('p3')?.imageUrl).toBeUndefined();
    expect(byId.get('p4')?.imageUrl).toBeUndefined();
  });
});
