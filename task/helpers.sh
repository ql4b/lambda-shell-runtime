#!/bin/bash

# https://docs.aws.amazon.com/lambda/latest/dg/runtimes-api.html
# https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html#apigateway-example-event
# https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
# https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-output-format

lambda_parse_event () {
    local EVENT="$1"
    # Extract commonly used fields
    if echo "$EVENT" | jq -e '.requestContext' >/dev/null; then
        export EVENT_BODY=$(echo "$EVENT" | jq -r '.body // empty')
        export EVENT_QUERY=$(echo "$EVENT" | jq -c '.queryStringParameters // {}')
        export EVENT_HEADERS=$(echo "$EVENT" | jq -c '.headers // {}')
        export EVENT_PATH=$(echo "$EVENT" | jq -r '.path // empty')
        export EVENT_HTTPMETHOD=$(echo "$EVENT" | jq -r '.httpMethod // empty')
    else
        # Handle other event types
        export EVENT_TYPE=$(echo "$EVENT" | jq -r 'keys[0]' 2>/dev/null || echo "unknown")
    fi
}


lambda_require_http_event () {
    if [ -z "$EVENT_HTTPMETHOD" ]; then
        lambda_error_response "Not an HTTP event" 400
        exit 1
    fi
}

# JSON response with CORS
lambda_json_response() {
    local data="$1"
    local status="${2:-200}"
    
    jq -n \
        --arg data "$data" \
        --arg status "$status" \
        '{
            statusCode: ($status|tonumber),
            body: $data,
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        }'
}

# Error response
lambda_error_response() {
    local message="$1"
    local status="${2:-400}"
    lambda_json_response "$(jq -n --arg msg "$message" '{error: $msg}')" "$status"
}

# Success with data
lambda_ok_response() {
    local data="$1"
    lambda_json_response "$data" 200
}

# Not found
lambda_not_found_response() {
    lambda_ok_response "Not found" 404
}

# Method not allowed
lambda_method_not_allowed_response() {
    lambda_ok_response "Method not allowed" 405
}

# lambda_log function 
lambda_log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp [$level] $message" >&2
    
}

# lambda_log_error
lambda_log_error() {
    lambda_log "$1" "ERROR"
}

# lambda_log_info
lambda_log_info() {
    lambda_log "$1" "INFO"
}

# lambda_log_debug
lambda_log_debug() {
    lambda_log "$1" "DEBUG"
}

# lambda_log_warn
lambda_log_warn() {
    lambda_log "$1" "WARN"
}

