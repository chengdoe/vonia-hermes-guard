# Vonia Hermes file guard

Minimal, auditable derivative image for Vonia's Hermes runtime. It keeps the
fixed upstream Hermes image byte-for-byte except for two reviewed changes:

- Base image: `nousresearch/hermes-agent@sha256:16788311e2fa3035456bdc1bafb8ec2b1777db64ebf020af9bb7eb73c3712c9e`
- Upstream source revision: `3c27eb6234bf91b8ceee9e9071591b31e9b148cb`
- Replaced path: `/opt/hermes/agent/file_safety.py`
- Replacement SHA-256: `0107e4004eb38b12c49952b0e509094f1351ffc4e9c7252dc1ec9bd018af16f4`
- Owner and mode: `0:0`, `0644`
- Feishu group identity patch: `feishu_group_sender_identity.patch`
- Feishu adapter source SHA-256: `55cbb66fa60abdd3710a3476c197b31d46dc3ff13ec401c23557ee6465f96029`
- Feishu adapter patched SHA-256: `32c7071cb3ce1b7063c374862963ef41ce9f91b8ed11760e5a2a2efd330981a6`
- Default container command: `sleep infinity`

The patch extends Hermes file-safety checks so credentials and protected state
cannot be written through write, patch, delete, or move operations. No runtime
credentials, environment files, user data, model configuration, or persistent
state are included in this repository or image.

The Feishu patch adds a group-only, fail-open display-name fallback to the
current chat's member roster when Contact lookup is unavailable. For private
groups whose app lacks that roster permission, it also supports an explicit
`sender_aliases` map keyed by stable Feishu IDs. It preserves the existing
open/user/union IDs used for Session isolation, never logs the alias keys,
does not alter bot identity handling, and requests no new permission scope.

The image also fixes the documented non-interactive resident command as its
default `CMD`. This prevents a deployment platform that omits a Service-level
command override from launching the interactive Hermes TUI and crash-looping;
the inherited entrypoint and s6 Gateway supervision remain unchanged.

The release workflow uses only the repository-scoped, short-lived
`GITHUB_TOKEN` with `packages: write`; no registry PAT is stored in the
repository.

See `build-manifest.json` for the complete source and patch hash contract.

## License

MIT, matching the upstream Hermes Agent project. See `LICENSE`.
