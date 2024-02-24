#!/bin/bash

clear

echo "Setting proxy to proxy_http and git config global proxy"

export http_proxy=http://1.1.1.4:4422
export https_proxy=http://1.1.1.4:4422
git config --global http.proxy http://1.1.1.4:4422
