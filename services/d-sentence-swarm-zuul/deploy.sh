#!/bin/bash

echo 'Starting sentence application as a stack' 

docker stack deploy --compose-file docker-compose.yml sentence-alt
