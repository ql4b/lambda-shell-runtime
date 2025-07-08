# Ultra-minimal AWS CLI (CLI v1 via pip)
FROM public.ecr.aws/lambda/python:3.11 AS builder

RUN yum install -y unzip && \
    yum clean all

RUN pip install awscli --target /aws-cli

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
RUN dnf install -y jq python3 && \
     dnf clean all && \
    rm -rf /var/cache/dnf

COPY --from=builder /aws-cli /opt/python
ENV PYTHONPATH=/opt/python

# Copy http-cli
COPY --from=builder /http-cli-bin/http-cli /var/task/bin/http-cli

ENV PATH="/var/task/bin:${PATH}"

COPY runtime/bootstrap /var/runtime/bootstrap
RUN chmod +x /var/runtime/bootstrap

WORKDIR /var/task

COPY functions/handler.sh handler.sh


