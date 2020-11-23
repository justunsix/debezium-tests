#!/bin/bash

clear

echo "Setting proxy to proxy_http and git config global proxy"

export http_proxy=http://204.40.130.129:3128
export https_proxy=http://204.40.120.129:3128
git config --global http.proxy http://204.40.130.129:3128
