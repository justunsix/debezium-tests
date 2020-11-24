#!/bin/bash

# Helm install via script
# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh

# Instal Homebrew, get Helm and Openshift CLI install using brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
/home/linuxbrew/.linuxbrew/bin/brew install helm && /home/linuxbrew/.linuxbrew/bin/brew install gcc && /home/linuxbrew/.linuxbrew/bin/brew install openshift-cli