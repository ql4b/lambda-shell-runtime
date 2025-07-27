FROM lambda-shell-runtime:base AS tiny

COPY task/helpers.sh helpers.sh

LABEL org.opencontainers.image.title="lambda-shell-runtime:tiny"