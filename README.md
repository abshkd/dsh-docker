# DeepSeek Harness in Docker

This unofficial community project runs [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) in a small, locked-down container. It is not affiliated with, endorsed by, or supported by DeepSeek. Sessions survive restarts, and the agent cannot see your host files unless you explicitly mount them.

DeepSeek Harness is developer-preview software. The upstream project says it has not had a security audit. A container reduces risk, but it is not the same as a separate virtual machine.

## Start it

You need Docker with Docker Compose.

```sh
docker compose build
docker compose up -d
docker compose logs -f dsh
```

Open the authenticated URL printed in the logs. It starts with `http://127.0.0.1:3080/` and contains a temporary access token.

Add your model from **Settings → Models**. Stop watching the logs with `Ctrl+C`; the container keeps running.

## Your data

Two Docker volumes are created automatically:

- `dsh-home` keeps sessions, settings, credentials, attachments, and installed profiles.
- `dsh-workspace` is the only persistent work area the agent can modify.

Stopping or recreating the container keeps both volumes:

```sh
docker compose down
docker compose up -d
```

Do not add `-v` to `docker compose down` unless you intend to delete the persistent data.

To work on files in the local `workspace` folder instead of an opaque Docker volume:

```sh
docker compose -f compose.yaml -f compose.bind.yaml up -d
```

Only that folder is mounted. Do not mount your home directory, SSH folder, cloud credentials, Docker socket, or the whole repository unless you want the agent to access it.

## Useful commands

See the installed version:

```sh
docker compose run --rm --entrypoint dsh dsh --version
```

Run one headless task with the same persistent data and workspace:

```sh
docker compose run --rm --entrypoint dsh dsh --profile headless "inspect this workspace"
```

Update the image after changing the pinned version in `package.json` and refreshing `package-lock.json`:

```sh
docker compose build --pull --no-cache
docker compose up -d
```

The container also includes a patched pnpm release for optional Harness plugin management. It is intentionally newer than the vulnerable pnpm version named by the current upstream source tree.

## Security choices

The default Compose service:

- runs as an unprivileged user;
- drops every Linux capability and prevents privilege escalation;
- makes the image filesystem read-only;
- publishes the Web UI on host loopback only;
- gives the agent only its two named volumes and temporary storage;
- keeps the upstream `workspace-write` sandbox and approval prompts enabled (using its Landlock fallback inside Docker);
- disables optional telemetry by default; and
- sets CPU, memory, and process limits.

Outbound network access remains enabled because the harness needs to reach model providers. Anything stored in the two volumes is inside the agent's trust boundary. In particular, upstream documents that same-user processes can read its file-backed credential store. Use a disposable API key with narrow limits, keep backups, and use a VM as well as Docker for genuinely hostile workloads.

The Web server listens on all interfaces *inside the container* so Docker can forward it. Compose publishes that port only to `127.0.0.1`, so it is not exposed on your LAN. Do not change the port mapping to `3080:3080` unless you intentionally want network exposure and have added a trusted authentication proxy.

See [SECURITY.md](SECURITY.md) for the exact upstream commit reviewed, the installed npm artifact, known upstream limitations, applicable pnpm advisories, mitigations, and remaining container risks.

## License and disclaimer

The Docker wrapper files in this repository are released under the [MIT License](LICENSE). DeepSeek Harness and all other bundled dependencies retain their own copyright notices and licenses.

This software is provided **as is**, without warranty of any kind. To the maximum extent permitted by law, the authors and copyright holders are not liable for claims, damages, data loss, credential disclosure, security incidents, service interruption, or other liability arising from the software or its use. You are responsible for reviewing the configuration, complying with applicable laws and provider terms, securing credentials, maintaining backups, and deciding whether this software is suitable for your environment.

No license or README can guarantee that a person will never make a legal claim. This notice is general project information, not legal advice; obtain advice from a qualified lawyer for your jurisdiction and intended distribution.
