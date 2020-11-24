FROM ubuntu:latest
FROM homebrew/brew

# Ubuntu image with curl, git, brew, Helm, and Openshift CLI

#RUN apt update
# RUN sudo apt install -yq \
#       bash-completion \
#       curl \
#       git \
#       jq \
#       less \
#       nano \
#       sudo \
#     && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

RUN brew install helm && brew install openshift-cli

#RUN sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"