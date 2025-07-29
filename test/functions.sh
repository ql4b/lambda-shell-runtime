#!/bin/sh

VARIANT=${VARIANT:-"tiny"}
HANDLER=${HANDLER:-"handler.f"}

TAG="lambda-shell-runtime-${VARIANT}"

# The AWS Lambda Runtime Interface Emulator is already available
# https://github.com/aws/aws-lambda-runtime-interface-emulator/


# Start the Lambda shell container
# Optionally:
# 
# * add --detach flag to run the container in the background
# * mount --volume ./task/handler.sh:/var/task/handler.sh
# * set the _HANDLER environent variable 

r () {
    docker run \
    --rm \
    --detach \
    --platform linux/arm64 \
    --entrypoint /usr/local/bin/aws-lambda-rie \
    -p 9000:8080 \
    --name "$TAG" \
    "$TAG" \
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