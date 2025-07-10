# examples

## buld 

```bash
# CONTAINER="shell-booking"
# TAG="shell-booking:dev"
# TAG="703177223665.dkr.ecr.eu-central-1.amazonaws.com/ql4b-farecrumbs:booking"
CONTAINER="rrlelay"
TAG="rrlelay:dev"


b () {
    docker build \
    --platform linux/arm64  \
    -t "$TAG"  \
    --secret id=github_token,env=GITHUB_TOKEN \
    .
}

r () {
    docker run -d --rm \
        -p 9000:8080 \
        --name $CONTAINER \
        --platform linux/arm64 \
        -v ~/.aws:/root/.aws:ro \
        --volume ~/.aws-lambda-rie:/aws-lambda \
        --volume ./rrelay.sh:/var/task/hander.sh:rw \
        --entrypoint /aws-lambda/aws-lambda-rie \
        --env HANDLER="handler.booking" \
        "$TAG" \
        /var/runtime/bootstrap
}

p () {
    docker ps -q --filter name="$CONTAINER"    
}

s () {
    docker stop $(p)    
}

e () {
    docker exec -it \
        $(p) \
    $@
}

req () {
    http-cli -d '{ "reservationNumber": "A3PJKR" }' \
    "http://localhost:9000/2015-03-31/functions/function/invocations"
}
```