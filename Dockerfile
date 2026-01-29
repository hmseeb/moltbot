FROM node:22-bookworm AS base

# Cache bust: v6-chromium-deps-2026-01-30
RUN echo "v6-chromium" > /etc/build-version

# Install Bun (required for build scripts) - v5 chromium deps
RUN echo "Build: $(date +%s)" && curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Install Tailscale, gosu, and Linuxbrew dependencies
RUN curl -fsSL https://tailscale.com/install.sh | sh && \
    apt-get update && apt-get install -y gosu build-essential procps curl file git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Linuxbrew (Homebrew for Linux) as non-root user
RUN useradd -m -s /bin/bash linuxbrew && \
    mkdir -p /home/linuxbrew/.linuxbrew && \
    chown -R linuxbrew:linuxbrew /home/linuxbrew
USER linuxbrew
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
USER root
# Make Homebrew writable by node user for runtime skill installations
RUN chown -R node:node /home/linuxbrew/.linuxbrew
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV HOMEBREW_NO_AUTO_UPDATE=1

RUN corepack enable

WORKDIR /app

# Install Chrome/Puppeteer dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      chromium \
      libnss3 \
      libnspr4 \
      libatk1.0-0 \
      libatk-bridge2.0-0 \
      libcups2 \
      libdrm2 \
      libdbus-1-3 \
      libxkbcommon0 \
      libx11-6 \
      libxcomposite1 \
      libxdamage1 \
      libxext6 \
      libxfixes3 \
      libxrandr2 \
      libgbm1 \
      libpango-1.0-0 \
      libcairo2 \
      libasound2 \
      fonts-liberation && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Environment for Puppeteer to use system Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

ARG CLAWDBOT_DOCKER_APT_PACKAGES=""
RUN if [ -n "$CLAWDBOT_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $CLAWDBOT_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN pnpm install --frozen-lockfile

COPY . .
RUN CLAWDBOT_A2UI_SKIP_MISSING=1 pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV CLAWDBOT_PREFER_PNPM=1
RUN pnpm ui:install
RUN pnpm ui:build

ENV NODE_ENV=production

# Set up pnpm global directory for node user
ENV PNPM_HOME=/home/node/data/.pnpm-global
ENV PATH="${PNPM_HOME}:${PATH}"

# Create config and data directories (including pnpm global dir)
RUN mkdir -p /home/node/.clawdbot /home/node/data /home/node/data/.pnpm-global && chown -R node:node /home/node/.clawdbot /home/node/data
COPY --chown=node:node clawdbot.json /home/node/.clawdbot/clawdbot.json
ENV CLAWDBOT_CONFIG_PATH=/home/node/.clawdbot/clawdbot.json
# Use volume path for state (persistent storage)
ENV CLAWDBOT_STATE_DIR=/home/node/data
ENV HOME=/home/node
# Set npm cache to use volume for skill installations
ENV npm_config_cache=/home/node/data/.npm

# Create entrypoint script with proper Unix line endings - v3 with lock cleanup
RUN printf '#!/bin/bash\nif [ -d /home/node/data ]; then chown -R node:node /home/node/data; fi\nmkdir -p /home/node/data/.pnpm-global && chown node:node /home/node/data/.pnpm-global\nchown -R node:node /home/linuxbrew/.linuxbrew 2>/dev/null || true\nif [ -d /home/node/data/agents ]; then find /home/node/data/agents -name "*.lock" -type f -delete 2>/dev/null && echo "Cleaned up stale session lock files"; fi\nexec gosu node node dist/index.js gateway --bind lan --port ${PORT:-18789}\n' > /entrypoint.sh && chmod +x /entrypoint.sh

# Run entrypoint as root (it will switch to node user after fixing permissions)
CMD ["/entrypoint.sh"]
