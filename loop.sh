#!/bin/bash

cd "$(dirname "$0")" || exit

while true; do
  d="$(date)"
  echo "$d"
  echo -n '0: '
  ./mongo 127.0.0.1:21000/testdb --quiet --eval "db.c.insert({x: '$d'})"
  echo -n '1: '
  ./mongo 127.0.0.1:21001/testdb --quiet --eval "db.c.insert({x: '$d'})"
  echo
  sleep 1
done
