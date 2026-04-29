# ai_screen_assistant

**Source:** [github.com/pankajprajapat/ai_screen_assistant](https://github.com/pankajprajapat/ai_screen_assistant)

Screen-grounded AI chat for Ruby: **pluggable LLM providers**, **credential resolvers**, **conversation stores**, **topic guards**, and **JSONL export** for fine-tuning datasets.

## Install

```ruby
gem "ai_screen_assistant", "~> 0.1"
```

## Quick start

```ruby
require "ai_screen_assistant"

store = AiScreenAssistant::Stores::MemoryStore.new
provider = AiScreenAssistant::Providers::OpenAiProvider.new
resolver = AiScreenAssistant::Credentials::EnvResolver.new("OPENAI_API_KEY")

orch = AiScreenAssistant::ChatOrchestrator.new(
  provider: provider,
  store: store,
  credential_resolver: resolver,
  preflight: AiScreenAssistant::TopicGuard::Pipeline.new([
    AiScreenAssistant::TopicGuard::KeywordOverlap.new
  ])
)

screen = AiScreenAssistant::ScreenContext.new(
  screen_id: "orders/123",
  route: "/orders/123",
  human_summary: "Order #123: two items, status Shipped.",
  structured_payload: { order_id: 123, status: "shipped" },
  recent_api_traces: ["GET /api/orders/123 -> 200"],
  allowed_intent_tags: %w[order shipped]
)

result = orch.respond(
  thread_id: nil,
  user_message: "When did it ship?",
  screen_context: screen
)

puts result.reply
puts result.thread_id
```

## SPA / API payload (`screen_context`)

Send JSON your backend forwards into `ScreenContext.new`:

| Field | Meaning |
|--------|--------|
| `screen_id` | **Required.** Stable id for this view (e.g. route + entity id). |
| `route` | Optional URL path. |
| `human_summary` | Short natural-language summary of visible UI. |
| `structured_payload` | Hash of redacted fields (order ids, labels, etc.). |
| `recent_api_traces` | Array of short strings (already redacted) from recent XHR/fetch. |
| `allowed_intent_tags` | Optional tags; enables `KeywordOverlap` preflight heuristic. |

The gem **does not** scrape the browser: your client must attach context.

## Credentials (“BYOK” vs “SSO”)

Public LLM APIs are normally **server-to-server** with an **API key**. Patterns:

- **BYOK**: `Credentials::EnvResolver`, `Credentials::StaticResolver`, or vault-backed `Credentials::BlockResolver`.
- **Per-user / tenant**: resolve your own session or JWT in `BlockResolver` to a key or upstream proxy.
- **“SSO”** in products usually means **OAuth into your app** (Okta, etc.) so only logged-in users hit your chat endpoint—not OAuth to OpenAI per end customer.

## Topic guards

- **`TopicGuard::KeywordOverlap`** — optional **preflight** heuristic when `allowed_intent_tags` is set.
- **`TopicGuard::HostVeto`** — `lambda { |ctx| :ok }` or `:block` (default no-op).
- **`TopicGuard::JSONEnvelope`** — postflight when the model returns JSON `{"kind":"answer","body":"..."}`; pair with `ChatOrchestrator.new(..., json_reply: true)` and include this guard in `postflight`.

LLMs are not provably on-topic; combine guards with **server-side authorization** for sensitive actions.

## Persistence and export

- **`Stores::MemoryStore`** — dev / tests.
- **`Stores::FileStore`** — JSON files under a directory.
- **`Exporter.messages_to_jsonl`** — backup / audit.
- **`Exporter.thread_to_openai_finetune_line`** — one OpenAI-style training row per thread snapshot.

**PII, consent, and retention** are the host’s responsibility. Add redaction before persisting if needed.

## Providers

| Class | Notes |
|--------|--------|
| `Providers::OpenAiProvider` | Chat Completions API; `credentials: { api_key:, organization_id?: }` |
| `Providers::AnthropicProvider` | Messages API; `credentials: { api_key:, max_tokens?: }` |
| `Providers::StubProvider` | Tests |
| `Providers::BedrockProvider` | Optional: add `gem "aws-sdk-bedrockruntime"` to your app; Converse API |

## Threat model (short)

- Keys must stay on the server; never ship provider keys to the browser.
- Treat `screen_context` as sensitive; log redacted copies only.
- Rate-limit your chat endpoint (`rack-attack`, API gateway).

## Rails

Use the companion gem [`ai_screen_assistant-rails`](https://github.com/pankajprajapat/ai_screen_assistant-rails) for ActiveRecord storage and a controller concern.

## Sinatra

See [examples/sinatra](../examples/sinatra/) in this repository.
