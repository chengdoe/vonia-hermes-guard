ARG BASE_IMAGE=nousresearch/hermes-agent@sha256:16788311e2fa3035456bdc1bafb8ec2b1777db64ebf020af9bb7eb73c3712c9e
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.revision="3c27eb6234bf91b8ceee9e9071591b31e9b148cb"
LABEL ai.vonia.credential-guard.patch-sha256="d81eadd887e558da5a3608e050c7aea711104e811b6e2e14495553c4a0344c33"
LABEL ai.vonia.credential-guard.file-sha256="0107e4004eb38b12c49952b0e509094f1351ffc4e9c7252dc1ec9bd018af16f4"
LABEL ai.vonia.feishu-group-identity.patch-sha256="7588cf0c51b7db43b29d0e83e6ec9bfcbd20e4c8c43f3e97f96aad6c1b9998a3"
LABEL ai.vonia.feishu-group-identity.file-sha256="32c7071cb3ce1b7063c374862963ef41ce9f91b8ed11760e5a2a2efd330981a6"
LABEL ai.vonia.runtime.default-cmd="sleep infinity"

# Preserve the fixed image's root-owned, read-only application tree. The
# entrypoint, CMD contract, runtime UID drop, installed dependencies and every
# other image byte continue to come from the immutable parent digest.
COPY --chown=0:0 --chmod=0644 file_safety.py /opt/hermes/agent/file_safety.py
COPY --chown=0:0 --chmod=0644 feishu_group_sender_identity.patch /tmp/feishu_group_sender_identity.patch

RUN test "$(sha256sum /opt/hermes/agent/file_safety.py | awk '{print $1}')" = \
      "0107e4004eb38b12c49952b0e509094f1351ffc4e9c7252dc1ec9bd018af16f4" && \
    test "$(stat -c '%u:%g:%a' /opt/hermes/agent/file_safety.py)" = "0:0:644" && \
    test "$(sha256sum /opt/hermes/plugins/platforms/feishu/adapter.py | awk '{print $1}')" = \
      "55cbb66fa60abdd3710a3476c197b31d46dc3ff13ec401c23557ee6465f96029" && \
    test "$(sha256sum /tmp/feishu_group_sender_identity.patch | awk '{print $1}')" = \
      "7588cf0c51b7db43b29d0e83e6ec9bfcbd20e4c8c43f3e97f96aad6c1b9998a3" && \
    cd /opt/hermes && \
    git apply --check /tmp/feishu_group_sender_identity.patch && \
    git apply /tmp/feishu_group_sender_identity.patch && \
    chown 0:0 /opt/hermes/plugins/platforms/feishu/adapter.py && \
    chmod 0644 /opt/hermes/plugins/platforms/feishu/adapter.py && \
    test "$(sha256sum /opt/hermes/plugins/platforms/feishu/adapter.py | awk '{print $1}')" = \
      "32c7071cb3ce1b7063c374862963ef41ce9f91b8ed11760e5a2a2efd330981a6" && \
    test "$(stat -c '%u:%g:%a' /opt/hermes/plugins/platforms/feishu/adapter.py)" = "0:0:644" && \
    rm /tmp/feishu_group_sender_identity.patch

# Zeabur's deploy-from-specification path can clear a Service-level command
# override. Keep the documented non-interactive resident command in the image
# itself so an omitted override cannot fall back to the interactive Hermes TUI.
# The inherited entrypoint still starts s6 and reconciles the desired Gateway.
CMD ["sleep", "infinity"]
