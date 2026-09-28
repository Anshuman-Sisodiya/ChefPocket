import http from 'node:http';
import { createHash, timingSafeEqual } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { StringDecoder } from 'node:string_decoder';
import { ImportError, sourceURL, fetchCaption, generateRecipe, providersFromEnv } from './import.mjs';

export function createServer({ env = process.env, caption = fetchCaption, generate = generateRecipe } = {}) {
  const tokens = (env.IMPORT_ACCESS_TOKENS || '').split(',').map(t => t.trim()).filter(t => t.length >= 32).map(t => createHash('sha256').update(t).digest());
  if (!tokens.length) throw new Error('Set IMPORT_ACCESS_TOKENS to individually issued random tokens of at least 32 characters.');
  const quota = new Map(); const active = new Set();
  return http.createServer(async (req, res) => {
    res.setHeader('Content-Type', 'application/json'); res.setHeader('Cache-Control', 'no-store');
    const reply = (status, body) => { res.writeHead(status); res.end(JSON.stringify(body)); };
    if (req.url === '/health' && req.method === 'GET') return reply(200, { ok: true });
    if (req.url !== '/v1/import' || req.method !== 'POST') return reply(404, { error: { message: 'Not found.' } });
    const token = req.headers.authorization?.replace(/^Bearer /, '') || '';
    const digest = createHash('sha256').update(token).digest();
    if (!tokens.some(t => timingSafeEqual(t, digest))) return reply(401, { error: { message: 'Your import access token is missing or invalid.' } });
    const user = digest.toString('hex');
    if (active.has(user)) return reply(409, { error: { message: 'An import is already in progress.' } });
    const now = Date.now(); const recent = (quota.get(user) || []).filter(t => now - t < 3600_000);
    if (recent.length >= 20) { res.setHeader('Retry-After', '3600'); return reply(429, { error: { message: 'Hourly import limit reached. Try again later.' } }); }
    quota.set(user, [...recent, now]); active.add(user);
    try {
      let raw = ''; let size = 0; const decoder = new StringDecoder('utf8');
      for await (const chunk of req) { size += chunk.length; if (size > 131072) throw new ImportError(413, 'Paste up to 30,000 characters of recipe text.'); raw += decoder.write(chunk); }
      raw += decoder.end();
      let input;
      try { input = JSON.parse(raw); } catch { throw new ImportError(400, 'Invalid JSON request.'); }
      if (!input || typeof input !== 'object') throw new ImportError(400, 'Invalid import request.');
      const url = sourceURL(input.url).href;
      if (input.sourceText != null && (typeof input.sourceText !== 'string' || input.sourceText.length > 30000)) throw new ImportError(400, 'Source text must be at most 30,000 characters.');
      let text = input.sourceText?.trim();
      const suppliedText = !!text;
      if (!text) { try { text = await caption(url); } catch { text = ''; } }
      const providers = providersFromEnv(env);
      const host = new URL(url).hostname;
      const videoURL = !suppliedText && env.ENABLE_YOUTUBE_VIDEO === 'true' && ['youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be'].includes(host) && providers.some(p => p.kind === 'gemini') ? url : null;
      if ((!text || text.length < 40) && !videoURL) throw new ImportError(422, 'This video does not expose a recipe caption. Paste its ingredients and transcript to import it.');
      const recipe = await generate(text || '', url, providers, { videoURL });
      reply(200, { recipe });
    } catch (error) { reply(error instanceof ImportError ? error.status : 500, { error: { message: error instanceof ImportError ? error.message : 'Import failed. Please try again.' } }); }
    finally { active.delete(user); }
  });
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const server = createServer(); server.requestTimeout = 150_000;
  server.listen(Number(process.env.PORT || 8787), process.env.HOST || '127.0.0.1', () => console.log('ChefPocket import service listening'));
}
