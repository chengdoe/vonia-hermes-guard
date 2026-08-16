ARG BASE_IMAGE=nousresearch/hermes-agent@sha256:16788311e2fa3035456bdc1bafb8ec2b1777db64ebf020af9bb7eb73c3712c9e
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.revision="3c27eb6234bf91b8ceee9e9071591b31e9b148cb"
LABEL ai.vonia.credential-guard.patch-sha256="d81eadd887e558da5a3608e050c7aea711104e811b6e2e14495553c4a0344c33"
LABEL ai.vonia.credential-guard.file-sha256="0107e4004eb38b12c49952b0e509094f1351ffc4e9c7252dc1ec9bd018af16f4"
LABEL ai.vonia.feishu-group-identity.patch-sha256="f07083559e7a0a7480167ab4bb7ff7a3d7989069dd82340cda62e88c4a8b6cff"
LABEL ai.vonia.feishu-group-identity.file-sha256="4c5bcaa8c2ce725ae284c4a33c665599c7b844f63ebcf212a86f3a627c272d8b"
LABEL ai.vonia.feishu-dm-routing.patch-sha256="a91b333f7d713ae055044c20e2726df84c8a3ddf3e8efaff28f5927d516b71df"
LABEL ai.vonia.feishu-dm-routing.file-sha256="b0540e301b49bff7995776312d038d6346ee0514be1e092d7d11a094a7a01273"
LABEL ai.vonia.feishu-reply-routing="explicit-thread-id-only"
LABEL ai.vonia.runtime.default-cmd="sleep infinity"

# Preserve the fixed image's root-owned, read-only application tree. The
# entrypoint, CMD contract, runtime UID drop, installed dependencies and every
# other image byte continue to come from the immutable parent digest.
COPY --chown=0:0 --chmod=0644 file_safety.py /opt/hermes/agent/file_safety.py
COPY --chown=0:0 --chmod=0644 feishu_group_sender_identity.patch /tmp/feishu_group_sender_identity.patch
COPY --chown=0:0 --chmod=0644 feishu_dm_reply_routing.patch /tmp/feishu_dm_reply_routing.patch

RUN test "$(sha256sum /opt/hermes/agent/file_safety.py | awk '{print $1}')" = \
      "0107e4004eb38b12c49952b0e509094f1351ffc4e9c7252dc1ec9bd018af16f4" && \
    test "$(stat -c '%u:%g:%a' /opt/hermes/agent/file_safety.py)" = "0:0:644" && \
    test "$(sha256sum /opt/hermes/plugins/platforms/feishu/adapter.py | awk '{print $1}')" = \
      "55cbb66fa60abdd3710a3476c197b31d46dc3ff13ec401c23557ee6465f96029" && \
    test "$(sha256sum /tmp/feishu_group_sender_identity.patch | awk '{print $1}')" = \
      "f07083559e7a0a7480167ab4bb7ff7a3d7989069dd82340cda62e88c4a8b6cff" && \
    test "$(sha256sum /opt/hermes/gateway/platforms/base.py | awk '{print $1}')" = \
      "67262c97333b9e8274d269229ae6d0adecee104eaf5729208d0ea9b0ae8b814c" && \
    test "$(sha256sum /tmp/feishu_dm_reply_routing.patch | awk '{print $1}')" = \
      "a91b333f7d713ae055044c20e2726df84c8a3ddf3e8efaff28f5927d516b71df" && \
    cd /opt/hermes && \
    git apply --check /tmp/feishu_group_sender_identity.patch && \
    git apply --check /tmp/feishu_dm_reply_routing.patch && \
    git apply /tmp/feishu_group_sender_identity.patch && \
    git apply /tmp/feishu_dm_reply_routing.patch && \
    chown 0:0 /opt/hermes/plugins/platforms/feishu/adapter.py && \
    chmod 0644 /opt/hermes/plugins/platforms/feishu/adapter.py && \
    chown 0:0 /opt/hermes/gateway/platforms/base.py && \
    chmod 0644 /opt/hermes/gateway/platforms/base.py && \
    test "$(sha256sum /opt/hermes/plugins/platforms/feishu/adapter.py | awk '{print $1}')" = \
      "4c5bcaa8c2ce725ae284c4a33c665599c7b844f63ebcf212a86f3a627c272d8b" && \
    test "$(stat -c '%u:%g:%a' /opt/hermes/plugins/platforms/feishu/adapter.py)" = "0:0:644" && \
    test "$(sha256sum /opt/hermes/gateway/platforms/base.py | awk '{print $1}')" = \
      "b0540e301b49bff7995776312d038d6346ee0514be1e092d7d11a094a7a01273" && \
    test "$(stat -c '%u:%g:%a' /opt/hermes/gateway/platforms/base.py)" = "0:0:644" && \
    rm /tmp/feishu_group_sender_identity.patch /tmp/feishu_dm_reply_routing.patch

# Zeabur's deploy-from-specification path can clear a Service-level command
# override. Keep the documented non-interactive resident command in the image
# itself so an omitted override cannot fall back to the interactive Hermes TUI.
# The inherited entrypoint still starts s6 and reconciles the desired Gateway.
CMD ["sleep", "infinity"]
