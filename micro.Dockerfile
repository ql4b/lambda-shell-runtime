FROM public.ecr.aws/lambda/provided:al2023 AS builder

RUN dnf install -y unzip python3-pip  findutils && \
    dnf clean all

RUN pip3 install --no-cache-dir --target /tmp/awscurl awscurl && \
    find /tmp/awscurl -type d -name '__pycache__' -exec rm -rf {} + && \
    find /tmp/awscurl -type f -name '*.pyc' -delete && \
    find /tmp/awscurl -type d -name '*.dist-info' -exec rm -rf {} +

# Stage 2: Runtime stage
FROM lambda-shell-runtime:tiny AS micro

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

LABEL org.opencontainers.image.title="lambda-shell-runtime:micro"