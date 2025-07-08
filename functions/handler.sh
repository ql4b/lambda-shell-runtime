#!/bin/sh

function hello() {
  EVENT="$1"
  echo "$EVENT" \
  | jq 
}