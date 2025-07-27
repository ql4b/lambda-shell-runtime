FROM lambda-shell-runtime:base AS tiny

<<<<<<<< HEAD:base.Dockerfile
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

FROM public.ecr.aws/lambda/provided:al2023 AS base

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

# Label for documentation/reference
LABEL org.opencontainers.image.title="lambda-shell-runtime:base"
========
COPY task/helpers.sh helpers.sh

LABEL org.opencontainers.image.title="lambda-shell-runtime:tiny"
>>>>>>>> 09d81b0 (chore(ci): add base image build step to release workflow):tiny.Dockerfile
