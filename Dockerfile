FROM lamda-shell-runtime:tiny

RUN dnf install -y \
    jq \
    aws-cli  && \
    dnf clean all && \
    rm -rf /var/cache/dnf
