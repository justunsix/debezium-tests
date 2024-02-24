FROM gitpod/workspace-full

# Make sure tailscale is up to date
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add - \
     && curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list \
     && sudo apt-get update -q \
     && sudo apt-get install -yq tailscale jq \
     && sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-nft

# Install custom tools, runtimes, etc.
# For example "bastet", a command-line tetris clone:
# RUN brew install bastet

# Optional packages for Kubernetes and Openshift development
# RUN brew install helm && brew install openshift-cli

# Deprecated due to 2020-12 rollout of Docker and root privileges in gitpod https://www.gitpod.io/blog/root-docker-and-vscode/
# Gitpod’s default image (workspace-full) comes equipped with Docker now, so all you need to do is run sudo docker-up, 
# and wait until the service is listening. Now start another terminal and use the Docker CLI as usual.
# RUN brew install docker
# RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y
