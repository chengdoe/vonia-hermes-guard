# Vonia Hermes file guard

Minimal, auditable derivative image for Vonia's Hermes runtime. It keeps the
fixed upstream Hermes image byte-for-byte except for one root-owned Python
module:

- Base image: `nousresearch/hermes-agent@sha256:16788311e2fa3035456bdc1bafb8ec2b1777db64ebf020af9bb7eb73c3712c9e`
- Upstream source revision: `3c27eb6234bf91b8ceee9e9071591b31e9b148cb`
- Replaced path: `/opt/hermes/agent/file_safety.py`
- Replacement SHA-256: `0107e4004eb38b12c49952b0e509094f1351ffc4e9c7252dc1ec9bd018af16f4`
- Owner and mode: `0:0`, `0644`

The patch extends Hermes file-safety checks so credentials and protected state
cannot be written through write, patch, delete, or move operations. No runtime
credentials, environment files, user data, model configuration, or persistent
state are included in this repository or image.

The release workflow uses only the repository-scoped, short-lived
`GITHUB_TOKEN` with `packages: write`; no registry PAT is stored in the
repository.

See `build-manifest.json` for the complete source and patch hash contract.

## License

MIT, matching the upstream Hermes Agent project. See `LICENSE`.
