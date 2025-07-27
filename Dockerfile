FROM public.ecr.aws/lambda/provided:al2023 AS builder

ARG HTTP_CLI_VERSION=v1.0.1

RUN dnf install -y unzip && \
    dnf clean all

# Download http-cli
RUN --mount=type=secret,id=github_token \
    curl -H "Authorization: token $(cat /run/secrets/github_token)" \
    -L "https://github.com/ql4b/http-cli/archive/refs/tags/${HTTP_CLI_VERSION}.zip" \
    -o http-cli.zip && \
    unzip http-cli.zip && \
    mkdir -p /http-cli-bin && \
    mv http-cli-${HTTP_CLI_VERSION#v}/http-cli /http-cli-bin/ && \
    chmod +x /http-cli-bin/http-cli && \
    rm -rf http-cli.zip http-cli-${HTTP_CLI_VERSION#v}

LABEL org.opencontainers.image.http_cli_version="${HTTP_CLI_VERSION}"

# base: minimal runtime setup with jq
FROM public.ecr.aws/lambda/provided:al2023 AS base

ARG VERSION=develop
ARG HTTP_CLI_VERSION

# Install only runtime dependencies
RUN dnf install -y jq && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Copy http-cli
COPY --from=builder /http-cli-bin/http-cli /var/task/bin/http-cli
ENV PATH="/var/task/bin:${PATH}"

COPY runtime/bootstrap /var/runtime/bootstrap
RUN chmod +x /var/runtime/bootstrap

WORKDIR /var/task

COPY task/handler.sh handler.sh

LABEL org.opencontainers.image.source="https://github.com/ql4b/lambda-shell-runtime"
LABEL org.opencontainers.image.version="${VERSION}"

# tiny: add lamnda helper functions
FROM base AS tiny

ARG VERSION
ARG HTTP_CLI_VERSION

COPY task/helpers.sh helpers.sh

LABEL org.opencontainers.image.title="lambda-shell-runtime:tiny"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.http_cli_version="${HTTP_CLI_VERSION}"

FROM public.ecr.aws/lambda/provided:al2023 AS awscurl-installer

RUN dnf install -y unzip python3-pip  findutils && \
    dnf clean all

RUN pip3 install --no-cache-dir --target /tmp/awscurl awscurl && \
    find /tmp/awscurl -type d -name '__pycache__' -exec rm -rf {} + && \
    find /tmp/awscurl -type f -name '*.pyc' -delete && \
    find /tmp/awscurl -type d -name '*.dist-info' -exec rm -rf {} +

# micro: inclues awscurl
FROM tiny AS micro

ARG VERSION
ARG HTTP_CLI_VERSION

RUN dnf install -y python3 && \
    dnf clean all && \
    rm -rf /var/cache/dnf

COPY --from=awscurl-installer /tmp/awscurl /var/task/aws
# Clean up Python cache and metadata
RUN rm -rf \
  /var/task/aws/__pycache__ \
  /var/task/aws/*.dist-info \
  /var/task/aws/**/__pycache__

ENV PYTHONPATH="/var/task/aws"

RUN mkdir -p /var/task/bin && \
    printf '#!/bin/sh\nexport PYTHONPATH=/var/task/aws\nexec python3 -m awscurl.awscurl "$@"\n' > /var/task/bin/awscurl && \
    chmod +x /var/task/bin/awscurl

LABEL org.opencontainers.image.title="lambda-shell-runtime:micro"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.http_cli_version="${HTTP_CLI_VERSION}"

# full: includes aws-cli for complete AWS functionality
FROM tiny AS full

ARG VERSION
ARG HTTP_CLI_VERSION

RUN dnf install -y \
    aws-cli  && \
    dnf clean all && \
    rm -rf /var/cache/dnf   

LABEL org.opencontainers.image.title="lambda-shell-runtime:full"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.http_cli_version="${HTTP_CLI_VERSION}"