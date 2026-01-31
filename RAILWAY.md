# Deploy Moltbot on Railway

One-click deployment of [Moltbot](https://molt.bot) personal AI assistant.

## Quick Start

1. **Click "Deploy on Railway"** (or use this template)
2. **Set required environment variables** (see below)
3. **Deploy** - Railway will build and start the gateway

## Required Environment Variables

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Your Anthropic API key ([get one](https://console.anthropic.com/)) |

## Gateway Authentication (set one)

| Variable | Description |
|----------|-------------|
| `CLAWDBOT_GATEWAY_TOKEN` | Token auth (recommended) - generate with `openssl rand -hex 32` |
| `CLAWDBOT_GATEWAY_PASSWORD` | Password auth - for shared/team access |

> **Note:** Set ONE of these. If both are set, password mode takes precedence.

## Messaging Providers (set the ones you use)

| Variable | Description |
|----------|-------------|
| `TELEGRAM_BOT_TOKEN` | Telegram bot token from [@BotFather](https://t.me/BotFather) |

## Optional Environment Variables

| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | For GPT-4o fallback models |
| `OPENROUTER_API_KEY` | For additional model access via OpenRouter |

## Connecting to the Gateway

After deployment, your gateway will be available at your Railway URL.

**Dashboard:** `https://your-app.railway.app/`

Enter your `CLAWDBOT_GATEWAY_TOKEN` or `CLAWDBOT_GATEWAY_PASSWORD` in the dashboard settings.

## Persistent Storage

This template uses a Railway volume mounted at `/data` for:
- Session state
- Telegram update offsets
- Agent data

## Resources

- [Moltbot Docs](https://docs.molt.bot)
- [Getting Started Guide](https://docs.molt.bot/start/getting-started)
- [Telegram Setup](https://docs.molt.bot/channels/telegram)
- [Discord](https://discord.gg/clawd)
