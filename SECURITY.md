# Security notes

This is a point-in-time risk record, not a security certification or a complete vulnerability audit.

## Review snapshot

This record was prepared on 2026-09-12 against:

| Item | Pinned value |
|---|---|
| Reviewed upstream repository | [`deepseek-ai/deepseek-harness`](https://github.com/deepseek-ai/deepseek-harness) |
| Upstream `HEAD` at review time | [`c291e7961a515f6d7af9304e7fd1d257929aef26`](https://github.com/deepseek-ai/deepseek-harness/tree/c291e7961a515f6d7af9304e7fd1d257929aef26) |
| Runtime installed by this image | `@deepseek-ai/dsh@0.1.5-rc.1` |
| Runtime registry integrity | `sha512-rmNmzQCg3oIc1z8xH7izRSOuy1TNzq+/NILyfM+7e8DKOyV+yBtg47WEsqR2SiIe1ATec3L/rUa1YhIcfQ2XEg==` |
| Package manager in the reviewed upstream tree | `pnpm@11.7.0` |
| Package manager in this image | `pnpm@11.26.0` |

The npm metadata for `@deepseek-ai/dsh@0.1.5-rc.1` did not publish a `gitHead`. The npm artifact therefore cannot be honestly claimed to correspond exactly to the reviewed upstream commit. Its version and registry integrity are recorded separately, and its complete resolved dependency tree is pinned by `package-lock.json`.

Repeat this review and update the table whenever the Harness version or upstream review commit changes. The `node:22-bookworm-slim` base tracks the maintained Node 22 image, so OS and Node patch versions can also change between builds.

## Known upstream risks and limitations

These are documented or directly implied by the upstream source at the pinned commit:

1. **Experimental software and model-generated execution.** The Harness is developer-preview software without a security audit. It can execute model-generated commands, load plugins, and access available files, credentials, processes, and networks. Sandboxing and approvals reduce risk but do not guarantee isolation. See the pinned [upstream safety notice](https://github.com/deepseek-ai/deepseek-harness/blob/c291e7961a515f6d7af9304e7fd1d257929aef26/SAFETY.md).
2. **Credentials are readable by the agent's UID.** `$DSH_HOME/.credentials.yaml` is owner-only, but Harness tools run as that same owner. Upstream explicitly says file permissions cannot keep this store secret from the agent. Use disposable, narrowly scoped API keys. See the pinned [credential-provider documentation](https://github.com/deepseek-ai/deepseek-harness/blob/c291e7961a515f6d7af9304e7fd1d257929aef26/packages/credentials/credentials-local/README.md#who-can-read-the-file).
3. **Credential and `.env` precedence.** Credential lookup is launch environment, stored credential file, workspace `.env`, then `$DSH_HOME/.env`. A repository-controlled `.env` can therefore supply values that are absent from higher-priority layers. Treat workspace contents as untrusted and review `.env` files before use.
4. **Reads and network access are not confined by `workspace-write`.** Upstream limits ordinary file mutations to the workspace and temporary roots, but reads and network access remain available. The Landlock fallback also does not hide other processes in its PID namespace. See the pinned [CLI deployment behavior](https://github.com/deepseek-ai/deepseek-harness/blob/c291e7961a515f6d7af9304e7fd1d257929aef26/apps/cli/reference/README.md#web-alias).
5. **Third-party plugins and MCP servers are trusted code.** Plugin installation changes executable profile dependencies, and upstream describes MCP server commands as trusted executables outside the agent sandbox. Do not install unreviewed packages, tarballs, Git repositories, or MCP commands.
6. **Telemetry and session export can contain sensitive content.** Upstream states that exports can include message text, tool arguments and results, and workspace paths. This image sets `DSH_TELEMETRY_MODE=DISABLED`; that does not enable or disable the separate, opt-in DeepSeek session-log contributor. Review profile changes before enabling either path.
7. **The Web surface can provide remote code execution capability.** Upstream intentionally rejects a normal `--host 0.0.0.0` launch. This image binds all interfaces only inside the container so Docker forwarding works, while Compose publishes the port to host `127.0.0.1` only. Changing the mapping to `3080:3080`, joining an untrusted Docker network, or leaking the tokenized startup URL can expose the agent surface.

## pnpm advisories present in the upstream pin

The reviewed upstream commit declares `pnpm@11.7.0`. That release is affected by these published advisories:

| Advisory | Risk | Patched in pnpm 11.x | This image |
|---|---|---:|---|
| [GHSA-vx52-2968-3vc6](https://github.com/advisories/GHSA-vx52-2968-3vc6) | Environment-secret exfiltration through proxy-setting placeholder expansion in an untrusted `pnpm-workspace.yaml` | 11.11.0 | Uses 11.26.0 |
| [GHSA-qrv3-253h-g69c](https://github.com/advisories/GHSA-qrv3-253h-g69c) | Path traversal through `configDependencies` names in a crafted lockfile | 11.8.0 | Uses 11.26.0 |
| [GHSA-c59q-g84q-2gj5](https://github.com/advisories/GHSA-c59q-g84q-2gj5) | Virtual-store path traversal and arbitrary file write from crafted lockfile package keys | 11.11.0 | Uses 11.26.0 |
| [GHSA-vq4v-j7r6-jq4m](https://github.com/advisories/GHSA-vq4v-j7r6-jq4m) | Tarball manifest-name traversal causing writes outside `node_modules` | 11.11.0 | Uses 11.26.0 |

The wrapper does not expose upstream's pnpm 11.7.0 executable. It installs 11.26.0 from this repository's lockfile. The production dependency audit reported zero known npm advisories on 2026-09-12, but a clean audit result does not prove the absence of vulnerabilities.

## Container-specific residual risks

- Docker containers share the host kernel. A kernel or Docker runtime vulnerability may cross the container boundary; use a disposable VM as an additional boundary for hostile workloads.
- Outbound networking remains enabled for model-provider access. The container may be able to reach Internet, LAN, or Docker-host services allowed by the host's network policy.
- Both persistent volumes are inside the Harness trust boundary. The agent can read their contents, and the Harness can modify them.
- The authenticated Web URL is printed to container logs. Anyone able to read those logs should be treated as able to access the running Harness.
- A host bind mount deliberately grants access to that host directory. Never mount the Docker socket, home directory, SSH agent, credential directories, or other sensitive paths.
- Resource limits reduce denial-of-service impact but do not eliminate it.

For materially untrusted prompts, repositories, plugins, or MCP servers, use Docker inside a disposable VM and credentials that can be revoked without affecting other systems.
