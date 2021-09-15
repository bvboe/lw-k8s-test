#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

serverAddress=<insert address here>

echo Starting on Host http://$serverAddress/ >> pingproxy.log
curl -s http://$serverAddress/hello.html >> pingproxy.log
curl -s http://$serverAddress/128MB.html > /dev/null
curl -s http://$serverAddress/128MB.html > /dev/null
curl -s http://$serverAddress/128MB.html > /dev/null
curl -s http://$serverAddress/128MB.html > /dev/null
echo Done >> pingproxy.log
date >> pingproxy.log
