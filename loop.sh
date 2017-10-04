#!/bin/bash

cd "$(dirname "$0")" || exit

while true; do
  d="$(date)"
  echo "$d"
  echo -n '4: '
  ./mongo --quiet lighthouse.4.mongolayer.com:10615/testdb -u testuser -p testpass --eval "db.c.insert({x: '$d'})"
  echo -n '5: '
  ./mongo --quiet lighthouse.5.mongolayer.com:10615/testdb -u testuser -p testpass --eval "db.c.insert({x: '$d'})"
  echo
  sleep 1
done
