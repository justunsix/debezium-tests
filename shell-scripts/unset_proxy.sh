#!/bin/bash

clear

echo "Unsetting proxy from proxy_http and git config global proxy"

# remove system proxy
unset http_proxy
unset https_proxy
# remove git proxy
git config --global --unset http.proxy
