#!/bin/bash
while inotifywait -r -e modify ./test ./lib; do
  mix test $1
done
