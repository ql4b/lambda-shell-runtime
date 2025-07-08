# lambda-shell-runtime

Custom AWS Lambda runtime environment for executing shell/bash functions with AWS Lambda.

Implement AWS Lambda functions in Bash, packaged as OCI-compliant container images that interface with the Lambda Runtime API and follow the custom runtime execution flow.

Inspired by: https://docs.aws.amazon.com/lambda/latest/dg/runtimes-walkthrough.html

## Runtime Variants

Each runtime variant has its own Dockerfile:

- `tiny`: [`jq`](https://stedolan.github.io/jq/) + [`http-cli`](https://github.com/ql4b/http-cli)
- `slim`: same as `tiny` + AWS CLI v1
- `full`: same as `slim` + AWS CLI v2

### Build locally

```bash
# Build tiny
docker build -f tiny.Dockerfile -t lambda-shell-base:tiny .

# Build slim
docker build -f slim.Dockerfile -t lambda-shell-base:slim .

# Build full
docker build -f Dockerfile -t lambda-shell-base:full .
```

## Usage

To use this runtime in your own Lambda container image:

```Dockerfile
FROM ghcr.io/ql4b/lambda-shell-base:tiny

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
  lambda-shell-base:tiny \
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
