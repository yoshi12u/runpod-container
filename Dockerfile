ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG PYTHON_VERSION

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash
ENV JUPYTER_IDLE_TIMEOUT=60

# Set the working directory
WORKDIR /

# Create workspace directory
RUN mkdir /workspace

# Update, upgrade, install packages, install python if PYTHON_VERSION is specified, clean up
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt install --yes --no-install-recommends git wget curl bash libgl1 software-properties-common openssh-server nginx fzf ripgrep build-essential && \
    if [ -n "${PYTHON_VERSION}" ]; then \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt install "python${PYTHON_VERSION}-dev" "python${PYTHON_VERSION}-venv" -y --no-install-recommends; \
    fi && \
    # Install cargo for Rust-based tools
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    # Install Rust-based CLI tools
    . "$HOME/.cargo/env" && \
    cargo install nu starship bat lsd && \
    # Add cargo binaries to PATH
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /root/.bashrc && \
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
    rm get-pip.py \
    fi

# Upgrade pip and install Python packages
RUN pip install --upgrade --no-cache-dir pip && \
    pip install --upgrade --no-cache-dir \
    jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions notebook==6.5.5 uv && \
    jupyter contrib nbextension install --user && \
    jupyter nbextension enable --py widgetsnbextension

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
COPY ./container-template/scripts/start.sh /
RUN chmod +x /start.sh

# Welcome Message
COPY ./container-template/logo/runpod.txt /etc/runpod.txt
RUN echo 'cat /etc/runpod.txt' >> /root/.bashrc

# Set the default command for the container
CMD [ "/start.sh" ]