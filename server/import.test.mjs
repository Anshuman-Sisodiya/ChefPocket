import test from 'node:test';
import assert from 'node:assert/strict';
import { sourceURL, captionFromHTML, fetchCaption, validateRecipe, generateRecipe } from './import.mjs';
import { createServer } from './server.mjs';

const url = 'https://www.youtube.com/watch?v=AbCd1234567';
const recipe = { title: 'Rice', category: 'Rice & Biryani', cuisine: 'Indian Regional', diet: 'Veg', servings: 2, prepTimeMinutes: 20, calories: 180, proteinGrams: 3, ingredients: [{ name: 'Rice', amount: 100, unit: 'g' }], instructions: ['Boil rice in water until tender.'] };
test('allowlist rejects local addresses, credentials, ports and lookalike domains', () => {
  for (const bad of ['http://youtube.com/a', 'https://127.0.0.1/a', 'https://youtube.com.evil.test/a', 'https://user@youtube.com/a', 'https://youtube.com:8443/a', 'file:///tmp/a']) assert.throws(() => sourceURL(bad));
  assert.equal(sourceURL(url).href, url);
});
test('captions handle metadata attribute order and YouTube JSON escaping', () => {
  assert.equal(captionFromHTML('<meta content="Rice &amp; beans" property="og:description">'), 'Rice & beans');
  assert.equal(captionFromHTML('"shortDescription":"100g rice\\nBoil it"'), '100g rice\nBoil it');
});
test('redirects are revalidated before another fetch', async () => {
  let calls = 0;
  await assert.rejects(fetchCaption(url, async () => { calls++; return new Response('', { status: 302, headers: { location: 'https://127.0.0.1/private' } }); }));
  assert.equal(calls, 1);
});
test('invalid recipe data is rejected, including null and fabricated placeholders', () => {
  for (const bad of [null, {}, { error: 'insufficient_source' }, { ...recipe, ingredients: [] }, { ...recipe, servings: 0 }, { ...recipe, ingredients: [{ name: 'Rice', amount: -1, unit: 'g' }] }]) assert.throws(() => validateRecipe(bad, url));
  const valid = validateRecipe(recipe, url);
  assert.equal(valid.servings, 2); assert.equal(valid.sourceURL, url); assert.ok(valid.ingredients[0].id);
});
test('bounded overload retry then cross-provider fallback', async () => {
  const calls = []; const delays = [];
  const result = await generateRecipe('source', url, [{ kind: 'gemini', key: 'test', model: 'configured' }, { kind: 'anthropic', key: 'test', model: 'configured' }], {
    sleep: async ms => delays.push(ms), fetcher: async (endpoint, request) => {
      calls.push(endpoint);
      assert.ok(!endpoint.includes('key='));
      if (endpoint.includes('googleapis')) return new Response('', { status: 503 });
      assert.equal(request.headers['anthropic-version'], '2023-06-01');
      return Response.json({ content: [{ type: 'text', text: JSON.stringify(recipe) }] });
    }
  });
  assert.equal(calls.length, 3); assert.equal(delays.length, 1); assert.equal(result.title, 'Rice');
});
test('long Retry-After skips provider without retrying early', async () => {
  let calls = 0;
  await assert.rejects(generateRecipe('source', url, [{ kind: 'gemini', key: 'test', model: 'configured' }], { sleep: async () => assert.fail('must not retry'), fetcher: async () => { calls++; return new Response('', { status: 429, headers: { 'Retry-After': '60' } }); } }), { status: 503 });
  assert.equal(calls, 1);
});
test('empty candidates produce a clear failure', async () => {
  await assert.rejects(generateRecipe('source', url, [{ kind: 'gemini', key: 'test', model: 'configured' }], { fetcher: async () => Response.json({ candidates: [] }) }), { status: 503 });
});
test('YouTube video input is sent as media, never as a bare URL prompt', async () => {
  let body;
  const result = await generateRecipe('', url, [{ kind: 'gemini', key: 'test', model: 'configured' }], { videoURL: url, fetcher: async (_, request) => {
    body = JSON.parse(request.body);
    return Response.json({ candidates: [{ content: { parts: [{ text: JSON.stringify(recipe) }] } }] });
  } });
  assert.equal(body.contents[0].parts[1].fileData.fileUri, url);
  assert.equal(body.contents[0].parts[1].fileData.mimeType, 'video/mp4');
  assert.equal(result.title, 'Rice');
});
test('HTTP service authenticates, validates, rate limits and returns the shared recipe contract', async t => {
  const token = 'test-token-with-at-least-32-characters';
  let generations = 0;
  const server = createServer({ env: { IMPORT_ACCESS_TOKENS: token }, caption: async () => '', generate: async (_, source) => { generations++; return validateRecipe(recipe, source); } });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const endpoint = `http://127.0.0.1:${server.address().port}/v1/import`;
  const post = (body, auth = token) => fetch(endpoint, { method: 'POST', headers: { Authorization: `Bearer ${auth}` }, body: JSON.stringify(body) });
  assert.equal((await post({ url }, 'wrong')).status, 401);
  assert.equal((await post({ url })).status, 422);
  assert.equal(generations, 0);
  const response = await post({ url, sourceText: '100g rice and 300ml water. Bring to a boil, cover and simmer for 15 minutes.' });
  assert.equal(response.status, 200); assert.equal((await response.json()).recipe.title, 'Rice');
  for (let i = 0; i < 18; i++) await post({ url });
  assert.equal((await post({ url })).status, 429);
});
