# Vonia Hermes file guard

Minimal, auditable derivative image for Vonia's Hermes runtime. It keeps the
fixed upstream Hermes image byte-for-byte except for the reviewed files and
runtime command contract listed below:

- Base image: `nousresearch/hermes-agent@sha256:16788311e2fa3035456bdc1bafb8ec2b1777db64ebf020af9bb7eb73c3712c9e`
- Upstream source revision: `3c27eb6234bf91b8ceee9e9071591b31e9b148cb`
- Replaced path: `/opt/hermes/agent/file_safety.py`
- Replacement SHA-256: `0107e4004eb38b12c49952b0e509094f1351ffc4e9c7252dc1ec9bd018af16f4`
- Owner and mode: `0:0`, `0644`
- Feishu group identity patch: `feishu_group_sender_identity.patch`
- Feishu adapter source SHA-256: `55cbb66fa60abdd3710a3476c197b31d46dc3ff13ec401c23557ee6465f96029`
- Feishu adapter patched SHA-256: `4c5bcaa8c2ce725ae284c4a33c665599c7b844f63ebcf212a86f3a627c272d8b`
- Feishu outbound routing patch: `feishu_dm_reply_routing.patch`
- Gateway base source SHA-256: `67262c97333b9e8274d269229ae6d0adecee104eaf5729208d0ea9b0ae8b814c`
- Gateway base patched SHA-256: `b0540e301b49bff7995776312d038d6346ee0514be1e092d7d11a094a7a01273`
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

The same reviewed adapter patch distinguishes real Feishu topics from ordinary
quoted replies. Only an explicit `thread_id` opens a topic lane;
`root_id`/`parent_id` remain reply context. This keeps ordinary DM and group
answers visible in the main conversation while preserving true-topic routing.
The small shared-gateway compatibility patch applies only to Feishu DMs: it
neutralizes stale thread IDs already persisted by an older runtime and replies
to the current user turn. Group topics and every non-Feishu platform retain
their original routing behavior.

The image also fixes the documented non-interactive resident command as its
default `CMD`. This prevents a deployment platform that omits a Service-level
command override from launching the interactive Hermes TUI and crash-looping;
the inherited entrypoint and s6 Gateway supervision remain unchanged.

The release workflow uses only the repository-scoped, short-lived
`GITHUB_TOKEN` with `packages: write`; no registry PAT is stored in the
repository. After publishing, it runs the secret-free
`feishu_reply_routing_canary.py` inside the exact image digest and verifies DM
quotes (including an old persisted DM source), group quotes, and real topics
through the adapter and shared gateway's runtime behavior.

See `build-manifest.json` for the complete source and patch hash contract.

## License

MIT, matching the upstream Hermes Agent project. See `LICENSE`.
