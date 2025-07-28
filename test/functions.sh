#!/bin/sh

VARIANT=${VARIANT:-"tiny"}
HANDLER=${HANDLER:-"handler.f"}

# Setup the AWS Lambda Runtime Interface Emulator
# https://github.com/aws/aws-lambda-runtime-interface-emulator/
em () {
    mkdir -p ~/.aws-lambda-rie && curl -Lo ~/.aws-lambda-rie/aws-lambda-rie \
    https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-arm64 \
    && chmod +x ~/.aws-lambda-rie/aws-lambda-rie
}

# Start the Lambda shell container
# Optionally:
# 
# * add --detach flag to run the container in the background
# * mount --volume ./task/handler.sh:/var/task/handler.sh
r () {
    docker run --rm \
    --detach \
    -p 9000:8080 \
    --name lambda-shell-runtime \
    --platform linux/arm64 \
    -v ~/.aws:/root/.aws:ro \
    --volume ~/.aws-lambda-rie:/aws-lambda \
    --entrypoint /aws-lambda/aws-lambda-rie \
    --env HANDLER="$HANDLER" \
    "lambda-shell-runtime:$VARIANT" \
    /var/runtime/bootstrap
}

# Get running container
p () {
    docker ps --filter "name=^lambda-shell-runtime$" \
    "$@"
}

# logs
l () {
    p -q  | xargs -I {} docker logs -f {}
}

# stop
s () {
    docker stop $(p -q )
}

# exec bash (into running container)
e () {
    docker exec -it $(p -q ) /bin/bash
}

i () {
    # Invoke test using http-bin
    http-cli -d '{}' \
    "http://localhost:9000/2015-03-31/functions/function/invocations"
}