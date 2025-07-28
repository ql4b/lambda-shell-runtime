#!/bin/sh

function f () {
  EVENT="$1"
  echo "$EVENT" | jq 
  echo "Default handler — override this in your runtime build context." >&2
  # exit 1
}