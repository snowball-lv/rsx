#!/usr/bin/env sh

curl -i -F "img=@./snufkin.png" -F "password=snowpw" localhost:4567/upload
