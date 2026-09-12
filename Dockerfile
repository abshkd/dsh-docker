# syntax=docker/dockerfile:1

FROM node:22-bookworm-slim

LABEL org.opencontainers.image.title="DeepSeek Harness (containerized)" \
      org.opencontainers.image.description="A least-privilege container for DeepSeek Harness" \
      org.opencontainers.image.version="0.1.5-rc.1" \
      org.opencontainers.image.licenses="MIT" \
      io.deepseek-harness.upstream.url="https://github.com/deepseek-ai/deepseek-harness" \
      io.deepseek-harness.upstream.review-revision="c291e7961a515f6d7af9304e7fd1d257929aef26"

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
      bash \
      ca-certificates \
      git \
      ripgrep \
      tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/dsh
COPY package.json package-lock.json ./
RUN npm ci --omit=dev \
    && npm cache clean --force

ENV NODE_ENV=production \
    HOME=/workspace \
    DSH_HOME=/home/node/.dsh \
    DSH_PERMISSION_MODE=workspace-write \
    DSH_TELEMETRY_MODE=DISABLED \
    DSH_TOOLS_MODE=native \
    XDG_CACHE_HOME=/home/node/.dsh/xdg/cache \
    XDG_CONFIG_HOME=/home/node/.dsh/xdg/config \
    XDG_DATA_HOME=/home/node/.dsh/xdg/data \
    NPM_CONFIG_CACHE=/home/node/.dsh/npm-cache \
    PATH=/usr/local/bin:/opt/dsh/node_modules/.bin:$PATH

RUN install -d -o node -g node /workspace /home/node/.dsh

COPY --chown=root:root docker/container.cordis.patch.yml /etc/dsh/container.cordis.patch.yml
COPY --chown=root:root --chmod=0555 docker/dsh /usr/local/bin/dsh

WORKDIR /workspace
USER node

EXPOSE 3080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD ["node", "-e", "const s=require('node:net').connect(3080,'127.0.0.1',()=>{s.end();process.exit(0)});s.setTimeout(2000,()=>{s.destroy();process.exit(1)});s.on('error',()=>process.exit(1))"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/dsh", "web", "--patch", "/etc/dsh/container.cordis.patch.yml"]
CMD ["--no-open"]
