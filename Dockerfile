ARG BASE_IMAGE=ghcr.io/chengdoe/vonia-hermes-guard@sha256:e84019aefecaab92792e0f9046b6eef1862dfcd057f23c5af7233e613abea663
FROM ${BASE_IMAGE}

LABEL ai.vonia.compaction-progress-silence.patch-sha256="a5a59033b06e6349f56c72070ecff778310d1b787b0aa2d30cb435b89081a642"
LABEL ai.vonia.compaction-progress-silence.file-sha256="d65c4b5989df481bad963b6364f119bc624663b17e232839b637dbb521694fd3"

# Build on the exact production image so the credential guard, Feishu sender
# identity and quoted-reply fixes remain byte-for-byte inherited. Only the
# gateway status filter changes.
COPY --chown=0:0 --chmod=0644 gateway_compaction_progress_silence.patch /tmp/gateway_compaction_progress_silence.patch

RUN test "$(sha256sum /opt/hermes/gateway/run.py | awk '{print $1}')" = \
      "0b749a90ff5740b5c8ce9d138f869aca19295f4c458e3b680e9be9fd7b0fb2ec" && \
    test "$(sha256sum /tmp/gateway_compaction_progress_silence.patch | awk '{print $1}')" = \
      "a5a59033b06e6349f56c72070ecff778310d1b787b0aa2d30cb435b89081a642" && \
    cd /opt/hermes && \
    git apply --check /tmp/gateway_compaction_progress_silence.patch && \
    git apply /tmp/gateway_compaction_progress_silence.patch && \
    chown 0:0 /opt/hermes/gateway/run.py && \
    chmod 0644 /opt/hermes/gateway/run.py && \
    test "$(sha256sum /opt/hermes/gateway/run.py | awk '{print $1}')" = \
      "d65c4b5989df481bad963b6364f119bc624663b17e232839b637dbb521694fd3" && \
    test "$(stat -c '%u:%g:%a' /opt/hermes/gateway/run.py)" = "0:0:644" && \
    rm /tmp/gateway_compaction_progress_silence.patch

CMD ["sleep", "infinity"]
