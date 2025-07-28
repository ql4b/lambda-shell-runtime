# lambda-shell-runtime

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://github.com/ql4b/lambda-shell-runtime/pkgs/container/lambda-shell-runtime)
[![AWS Lambda](https://img.shields.io/badge/AWS%20Lambda-FF9900?style=flat&logo=awslambda&logoColor=white)](https://aws.amazon.com/lambda/)

> **Turn shell scripts into serverless functions in minutes**

Custom AWS Lambda runtime for executing Bash functions as serverless applications. Deploy shell scripts directly to AWS Lambda with full access to common CLI tools like `jq`, `curl`, and AWS CLI.

## Features

- 🚀 **Zero-config deployment** - Just write Bash, deploy to Lambda
- 📦 **Three optimized variants** - Choose the right tools for your use case
- 🔧 **Built-in utilities** - `jq`, `curl`, `http-cli`, and optional AWS CLI
- 🏗️ **Multi-platform support** - ARM64 and x86_64 architectures
- 🧪 **Local testing** - Full Lambda Runtime Interface Emulator support
- 📋 **Production ready** - Based on official AWS Lambda base images

## Quick Start

1. **Create your handler function:**

```bash
# handler.sh
hello() {
    local event="$1"
    echo '{"message": "Hello from Bash Lambda!", "input": '"$event"'}'
}
```

2. **Create your Dockerfile:**

```dockerfile
FROM ghcr.io/ql4b/lambda-shell-runtime:tiny
COPY handler.sh .
```

3. **Deploy to AWS Lambda** using container images

## Runtime Variants

Choose the variant that matches your requirements:

| Variant | Size | Tools Included | Best For |
|---------|------|----------------|----------|
| **`tiny`** | ~50MB | `jq`, `curl`, `http-cli` | HTTP APIs, JSON processing |
| **`micro`** | ~80MB | `tiny` + `awscurl` | AWS API calls without full CLI |
| **`full`** | ~200MB | `micro` + AWS CLI | Complete AWS operations |

### Available Images

```bash
# From GitHub Container Registry
ghcr.io/ql4b/lambda-shell-runtime:tiny
ghcr.io/ql4b/lambda-shell-runtime:micro  
ghcr.io/ql4b/lambda-shell-runtime:full

# From AWS Public ECR
public.ecr.aws/j5r7n1v7/lambda-shell-runtime:tiny
public.ecr.aws/j5r7n1v7/lambda-shell-runtime:micro
public.ecr.aws/j5r7n1v7/lambda-shell-runtime:full
```

## Examples

### HTTP API with JSON Processing

```bash
# handler.sh
api_handler() {
    local event="$1"
    local name=$(echo "$event" | jq -r '.queryStringParameters.name // "World"')
    
    echo '{
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": '{"greeting": "Hello, '"$name"'!"}'
    }'
}
```

### AWS API Integration

```bash
# handler.sh (using micro variant)
list_buckets() {
    local buckets=$(awscurl --service s3 https://s3.amazonaws.com/ | jq '.ListAllMyBucketsResult.Buckets')
    echo '{"buckets": '"$buckets"'}'
}
```

### File Processing with AWS CLI

```bash
# handler.sh (using full variant)
process_s3_file() {
    local event="$1"
    local bucket=$(echo "$event" | jq -r '.Records[0].s3.bucket.name')
    local key=$(echo "$event" | jq -r '.Records[0].s3.object.key')
    
    aws s3 cp "s3://$bucket/$key" /tmp/input.json
    local result=$(jq '.data | length' /tmp/input.json)
    
    echo '{"processed": true, "count": '"$result"'}'
}
```

## Function Handler Format

Your handler functions receive the Lambda event as the first argument:

```bash
# handler.sh
my_function() {
    local event="$1"          # Lambda event JSON
    local context="$2"        # Lambda context (optional)
    
    # Process the event
    local result=$(echo "$event" | jq '.key')
    
    # Return JSON response
    echo '{"result": '"$result"'}'
}
```

**Handler naming:** Set your Lambda handler to `handler.my_function` (filename.function_name)

## Deployment

### Using AWS CLI

```bash
# Build and push your image
docker build -t my-lambda .
docker tag my-lambda:latest 123456789012.dkr.ecr.region.amazonaws.com/my-lambda:latest
docker push 123456789012.dkr.ecr.region.amazonaws.com/my-lambda:latest

# Create/update Lambda function
aws lambda create-function \
  --function-name my-bash-function \
  --code ImageUri=123456789012.dkr.ecr.region.amazonaws.com/my-lambda:latest \
  --role arn:aws:iam::123456789012:role/lambda-execution-role \
  --package-type Image \
  --timeout 30
```

### Using Terraform

```hcl
resource "aws_lambda_function" "bash_function" {
  function_name = "my-bash-function"
  role         = aws_iam_role.lambda_role.arn
  package_type = "Image"
  image_uri    = "123456789012.dkr.ecr.region.amazonaws.com/my-lambda:latest"
  timeout      = 30
}
```

## Local Testing

### Using Lambda Runtime Interface Emulator

```bash
# Download RIE (one time setup)
mkdir -p ~/.aws-lambda-rie
curl -Lo ~/.aws-lambda-rie/aws-lambda-rie \
  https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie
chmod +x ~/.aws-lambda-rie/aws-lambda-rie

# Run your function locally
docker run --rm -p 9000:8080 \
  -v ~/.aws-lambda-rie:/aws-lambda \
  -e HANDLER="handler.hello" \
  --entrypoint /aws-lambda/aws-lambda-rie \
  my-lambda:latest /var/runtime/bootstrap

# Test your function
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d '{"name": "World"}'
```

### Debug Mode

```bash
# Run with debug output
docker run --rm -p 9000:8080 \
  -e HANDLER="handler.hello" \
  -e _LAMBDA_RUNTIME_DEBUG=1 \
  my-lambda:latest
```

## Building from Source

```bash
# Clone the repository
git clone https://github.com/ql4b/lambda-shell-runtime.git
cd lambda-shell-runtime

# Build specific variant
./build --platform linux/arm64 --tag my-runtime --load tiny

# Build and push to registry
./build --platform linux/arm64 --tag my-registry/lambda-shell --push micro
```

### Build Options

- `--platform`: Target platform (default: `linux/arm64`)
- `--tag`: Image tag prefix
- `--load`: Load image locally (default)
- `--push`: Push to registry
- `--secret`: Inject build secrets (e.g., GitHub token)

## Performance & Limitations

- **Cold start**: ~100-300ms depending on variant
- **Memory usage**: 64MB minimum recommended
- **Timeout**: Standard Lambda limits apply (15 minutes max)
- **Package size**: Varies by variant (50MB-200MB)
- **Concurrent executions**: Standard Lambda limits

## Troubleshooting

### Common Issues

**Function not found:**
```bash
# Ensure your function is defined and handler matches
HANDLER="handler.my_function"  # filename.function_name
```

**Permission errors:**
```bash
# Ensure Lambda execution role has required permissions
# For AWS API calls, add appropriate IAM policies
```

**Timeout issues:**
```bash
# Increase Lambda timeout setting
# Optimize shell script performance
```

## Contributing

We welcome contributions! Please see our [contributing guidelines](CONTRIBUTING.md) for details.

### Development Setup

```bash
git clone https://github.com/ql4b/lambda-shell-runtime.git
cd lambda-shell-runtime
./build --load tiny  # Build and test locally
```

### Project Structure

```
lambda-shell-runtime/
├── runtime/          # Custom bootstrap and runtime logic
├── task/            # Helper functions and example handlers  
├── test/            # Test functions and runners
├── scripts/         # Build and publishing utilities
├── Dockerfile       # Multi-stage build definitions
└── build           # Build script for all variants
```

## License

MIT License - see [LICENSE](LICENSE) file for details.
