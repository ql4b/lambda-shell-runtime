FROM public.ecr.aws/lambda/provided:al2023 AS builder

RUN dnf install -y unzip python3-pip  findutils && \
    dnf clean all

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

RUN pip3 install --no-cache-dir --target /tmp/awscurl awscurl && \
    find /tmp/awscurl -type d -name '__pycache__' -exec rm -rf {} + && \
    find /tmp/awscurl -type f -name '*.pyc' -delete && \
    find /tmp/awscurl -type d -name '*.dist-info' -exec rm -rf {} +

# Stage 2: Runtime stage
FROM public.ecr.aws/lambda/provided:al2023

# Install only runtime dependencies
RUN dnf install -y jq python3 && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Copy only what's needed
COPY --from=builder /tmp/awscurl /var/task/aws
# Clean up Python cache and metadata
RUN rm -rf \
  /var/task/aws/__pycache__ \
  /var/task/aws/*.dist-info \
  /var/task/aws/**/__pycache__

ENV PYTHONPATH="/var/task/aws"

RUN mkdir -p /var/task/bin && \
    printf '#!/bin/sh\nexport PYTHONPATH=/var/task/aws\nexec python3 -m awscurl.awscurl "$@"\n' > /var/task/bin/awscurl && \
    chmod +x /var/task/bin/awscurl

# Copy http-cli
COPY --from=builder /http-cli-bin/http-cli /var/task/bin/http-cli
ENV PATH="/var/task/bin:${PATH}"

COPY runtime/bootstrap /var/runtime/bootstrap
RUN chmod +x /var/runtime/bootstrap

WORKDIR /var/task

COPY task/handler.sh handler.sh
