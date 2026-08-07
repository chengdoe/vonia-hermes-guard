ARG BASE_IMAGE=nousresearch/hermes-agent@sha256:16788311e2fa3035456bdc1bafb8ec2b1777db64ebf020af9bb7eb73c3712c9e
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.revision="3c27eb6234bf91b8ceee9e9071591b31e9b148cb"
LABEL ai.vonia.credential-guard.patch-sha256="d81eadd887e558da5a3608e050c7aea711104e811b6e2e14495553c4a0344c33"
LABEL ai.vonia.credential-guard.file-sha256="0107e4004eb38b12c49952b0e509094f1351ffc4e9c7252dc1ec9bd018af16f4"

# Preserve the fixed image's root-owned, read-only application tree. The
# entrypoint, CMD contract, runtime UID drop, installed dependencies and every
# other image byte continue to come from the immutable parent digest.
COPY --chown=0:0 --chmod=0644 file_safety.py /opt/hermes/agent/file_safety.py

RUN test "$(sha256sum /opt/hermes/agent/file_safety.py | awk '{print $1}')" = \
      "0107e4004eb38b12c49952b0e509094f1351ffc4e9c7252dc1ec9bd018af16f4" && \
    test "$(stat -c '%u:%g:%a' /opt/hermes/agent/file_safety.py)" = "0:0:644"
