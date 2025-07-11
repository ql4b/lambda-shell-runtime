FROM ghcr.io/ql4b/lambda-shell-runtime:0.1.0-develop.11-tiny

WORKDIR /var/task

RUN dnf install -y util-linux && \
    cp /usr/bin/uuidgen /var/task/bin/ && \
    dnf remove -y util-linux && \
    dnf clean all

COPY ./rrelay.sh handler.sh