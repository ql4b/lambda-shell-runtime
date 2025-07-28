#!/bin/sh

function main () {
  EVENT="$1"
  echo "$EVENT" | jq 
  echo "Default handler — override this in your runtime build context." >&2
}