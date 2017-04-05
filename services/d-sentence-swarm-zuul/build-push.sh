#!/bin/bash

echo 'Building and pushing the images.'

docker-compose build
docker-compose push
