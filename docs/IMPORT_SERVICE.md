# Recipe import service

The mobile apps now call one HTTPS endpoint. Provider credentials and model selection live on the server. The old client Gemini model lists are no longer used.

## Run locally

1. Install Node.js 22 or newer.
2. In `server`, copy `.env.example` to `.env`.
3. Configure at least one provider's API key and exact model ID supported by that account: `GEMINI_API_KEY` / `GEMINI_MODEL`, or `ANTHROPIC_API_KEY` / `ANTHROPIC_MODEL`. Model IDs are intentionally not guessed or hardcoded.
4. Generate an individual random access token for each tester, for example with `node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))"`. Put the tokens in the comma-separated `IMPORT_ACCESS_TOKENS` setting. These are ChefPocket access tokens, **not provider API keys**.
5. Run `npm test`, then `npm start`.

The service binds to `127.0.0.1:8787` by default. `GET /health` reports liveness. Put it behind an HTTPS reverse proxy for use from phones; both apps reject cleartext endpoints. Set `HOST=0.0.0.0` only when required by your deployment environment. Keep `.env` out of Git. No hosting, credentials, provider purchases, or public deployment have been configured by this change.

In iOS **AI Import → Import service**, or Android **Settings → Import service**, enter the full `https://your-host/v1/import` URL and the tester's access token. The token is stored in iOS Keychain or encrypted with Android Keystore. Existing Gemini keys in old profiles are retained for compatibility but are not used by imports.

## Supported sources

- Pasted captions/transcripts containing ingredient quantities and cooking steps work with either provider.
- Public YouTube and Instagram captions are read when available. Redirects are limited to explicitly allowed hosts; response size and request duration are bounded.
- With `ENABLE_YOUTUBE_VIDEO=true` and a compatible Gemini model configured, a public YouTube link without pasted text is attached as actual video input. It is not merely placed in a text prompt. Google controls model support, media availability, and quota.
- Claude can use the available caption if Gemini is overloaded. Claude cannot read YouTube media through this adapter; a video with no usable caption cannot fall back to Claude without a pasted transcript.
- Private/login-gated Instagram posts, unavailable videos, and videos with insufficient recipe detail require pasted source text. There is no Instagram video downloader or general transcription service in this implementation.
- Responses are validated before saving. Ingredients, instructions, servings, category, and numeric ranges must be valid. Nutritional values are estimates. AI can still make mistakes; review imported recipes.

## Request and response

`POST /v1/import` with `Authorization: Bearer <individual-token>` and a JSON body:

```json
{"url":"https://www.youtube.com/watch?v=...","sourceText":"Optional recipe caption or transcript"}
```

Success returns `{"recipe": {...}}` with the shared mobile recipe schema. Errors return `{"error":{"message":"..."}}` and a meaningful status: 400 invalid input, 401 access, 409 concurrent import, 413 size limit, 422 insufficient/invalid recipe, 429 hourly limit, or 503 unavailable providers.

Each configured provider gets at most two attempts. Transient errors use a bounded delay; long `Retry-After` values cause a switch to another provider. The server limits each access token to one concurrent import and 20 attempts per hour. It does not log keys, tokens, captions, or full provider error bodies.

## Before a public release

This is a deployable private testing service. Individual static tokens require manual issuance/revocation. A public app needs a real identity provider, short-lived user sessions, subscription/billing policy if applicable, and shared durable rate limits across server instances. Current rate limits are in process memory and reset when the server restarts. The existing iOS local email profile is not proof of Google identity and must not authorize paid API access.

## API references

- [Google generateContent](https://ai.google.dev/api/generate-content)
- [Google video understanding](https://ai.google.dev/gemini-api/docs/generate-content/video-understanding)
- [Claude Messages API](https://platform.claude.com/docs/en/api/messages/create)
