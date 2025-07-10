# Stage 1: Build stage
FROM public.ecr.aws/lambda/provided:al2023 AS builder

RUN dnf install -y unzip && \
    dnf clean all
# Install AWS CLI v2 (minimal installation)
RUN curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /aws-cli-bin --install-dir /aws-cli && \
    rm -rf aws awscliv2.zip

# Download http-cli
RUN --mount=type=secret,id=github_token \
    curl -H "Authorization: token $(cat /run/secrets/github_token)" \
    -L https://github.com/ql4b/http-cli/archive/refs/heads/develop.zip \
    -o http-cli.zip && \
    unzip http-cli.zip && \
    mkdir -p /http-cli-bin && \
    mv http-cli-develop/http-cli /http-cli-bin/ && \
    chmod +x /http-cli-bin/http-cli && \
    rm -rf http-cli.zip http-cli-develop

# Stage 2: Runtime stage
FROM public.ecr.aws/lambda/provided:al2023

# Install only runtime dependencies
RUN dnf install -y jq python3 python3-libs  && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Copy AWS CLI binaries only
COPY --from=builder /aws-cli-bin/aws /usr/local/bin/aws
COPY --from=builder /aws-cli /usr/local/aws-cli

# Copy http-cli
COPY --from=builder /http-cli-bin/http-cli /var/task/bin/http-cli

ENV PATH="/var/task/bin:${PATH}"

COPY runtime/bootstrap /var/runtime/bootstrap
RUN chmod +x /var/runtime/bootstrap

WORKDIR /var/task

COPY task/handler.sh handler.sh