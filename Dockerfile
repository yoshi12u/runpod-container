ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG PYTHON_VERSION

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash
ENV VIRTUAL_ENV=/workspace/.venv

# Set the working directory
WORKDIR /

# Create workspace directory
RUN mkdir /workspace

# Update, upgrade, install packages, install python if PYTHON_VERSION is specified, clean up
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt install --yes --no-install-recommends git wget curl bash libgl1 software-properties-common openssh-server build-essential libssl-dev pkg-config cmake unzip fontconfig nginx fzf ripgrep && \
    # Install GitHub CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt install --yes --no-install-recommends gh && \
    # Install Helix editor
    add-apt-repository ppa:maveonair/helix-editor && \
    apt install --yes --no-install-recommends helix && \
    # Install Python if PYTHON_VERSION is specified
    if [ -n "${PYTHON_VERSION}" ]; then \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt install "python${PYTHON_VERSION}-dev" "python${PYTHON_VERSION}-venv" -y --no-install-recommends; \
    fi && \
    # Install cargo for Rust-based tools
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    # Install Rust-based CLI tools
    . "$HOME/.cargo/env" && \
    cargo install nu starship bat lsd && \
    # Set up starship prompt
    echo 'eval "$(starship init bash)"' >> /root/.bashrc && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set up Python and pip only if PYTHON_VERSION is specified
RUN if [ -n "${PYTHON_VERSION}" ]; then \
    ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python && \
    ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py && \
    rm get-pip.py; \
    fi

# Set the default working directory
WORKDIR /workspace

# Upgrade pip and install uv
RUN pip install --upgrade --no-cache-dir pip && \
    pip install --upgrade --no-cache-dir uv

# Create venv and install Python packages
RUN if [ -n "${PYTHON_VERSION}" ]; then \
    uv venv --python ${PYTHON_VERSION} && \
    uv pip install jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions notebook==6.5.5 && \
    uv run jupyter contrib nbextension install --user && \
    uv run jupyter nbextension enable --py widgetsnbextension; \
    fi

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# NGINX Proxy
COPY ./container-template/proxy/nginx.conf /etc/nginx/nginx.conf
COPY ./container-template/proxy/readme.html /usr/share/nginx/html/readme.html

# Copy the README.md
COPY README.md /usr/share/nginx/html/README.md

# Nushell
COPY ./container-template/nushell/config.nu /root/.config/nushell/config.nu

# Start Scripts
COPY ./container-template/start.sh /
RUN chmod +x /start.sh

# Welcome Message
COPY ./container-template/runpod.txt /etc/runpod.txt
RUN echo 'cat /etc/runpod.txt' >> /root/.bashrc

# Set the default command for the container
CMD [ "/start.sh" ]