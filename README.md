# lambda-shell-runtime

Custom AWS Lambda runtime environment for executing shell/bash functions with AWS Lambda.

Implement AWS Lambda functions in Bash, packaged as OCI-compliant container images that interface with the Lambda Runtime API and follow the custom runtime execution flow.

Inspired by: https://docs.aws.amazon.com/lambda/latest/dg/runtimes-walkthrough.html

This custom Lambda runtime enables Bash-based execution with minimal dependencies. We provide three image variants tailored to different needs:

## Runtime Image Variants

### 1. `tiny`
- Includes: `jq`, `curl`, `http-cli`
- Use case: Lightweight data parsing and HTTP requests.

### 2. `micro`
- Based on: `tiny`
- Adds: `awscurl`
- Use case: AWS API calls using IAM credentials without full AWS CLI.

### 3. `full`
- Based on: `tiny`
- Adds: **full AWS CLI** (official install)
- Use case: Complete access to AWS CLI features.
- Note: Previously experimented with intermediate setups (e.g., stripped-down AWS CLI), but they proved unstable. This variant now uses the official, standard installation of the AWS CLI.

---

Each image is built from the same base but optimized for different tasks. You can choose the right variant for your Lambda depending on the environment and tools required.

Each runtime variant has its own Dockerfile:

## Local build process

To run the script locally:

```
./build --platform linux/arm64 --tag your-repo/lambda-shell --load micro
```

```
./build --platform linux/arm64 --tag your-repo/lambda-shell --push micro
```

Key Features:

* Platform targeting: Defaults to linux/arm64, which is suitable for AWS Lambda ARM-based functions.
* Variants: You can build one or more of the supported variants: tiny, micro, or full.
* Secrets: Supports injecting a GitHub token via --secret id=github_token,env=GITHUB_TOKEN for private dependency access during build.

Modes:
* `--load` (default): Loads the image into the local Docker engine.
* `--push`: Pushes the image to a remote registry.

## GitHub Actions Build

In a GitHub Actions environment, the build script is typically used in combination with Docker Buildx and secrets configured in the CI pipeline.

## Usage

To use this runtime in your own Lambda container image:

```Dockerfile
FROM public.ecr.aws/j5r7n1v7/lambda-shell-runtime:tiny

WORKDIR /var/task

COPY relay.sh handler.sh .
```

Your `handler.sh` file should define bash functions, and the handler name passed to Lambda should match `filename.functionname`, e.g., `handler.hello`.

## Local testing

Use [aws-lambda-runtime-interface-emulator](https://github.com/aws/aws-lambda-runtime-interface-emulator) for local testing.

```bash
docker run -d \
  -v ~/.aws-lambda-rie:/aws-lambda \
  -p 9000:8080 \
  --env HANDLER="handler.hello" \
  --entrypoint /aws-lambda/aws-lambda-rie \
  lambda-shell-runtime:tiny \
  /var/runtime/bootstrap

curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
```

## Publishing

Images are published to GitHub Container Registry (GHCR):

```bash
./scripts/publish <version>
```

## Layout

- `runtime/` — custom bootstrap and core loop
- `test/` — simple example test function + runner
- `scripts/` — utilities like publishing
