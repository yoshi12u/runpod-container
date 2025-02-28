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

# Update and upgrade system packages
RUN apt-get update --yes && \
    apt-get upgrade --yes

# Install system dependencies
RUN apt install --yes --no-install-recommends \
    git wget curl bash libgl1 software-properties-common \
    openssh-server nginx fzf ripgrep build-essential \
    libssl-dev pkg-config cmake unzip fontconfig

# Install Python if PYTHON_VERSION is specified
RUN if [ -n "${PYTHON_VERSION}" ]; then \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt install "python${PYTHON_VERSION}-dev" "python${PYTHON_VERSION}-venv" -y --no-install-recommends; \
    fi

# Install Rust and cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . "$HOME/.cargo/env" && \
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /root/.bashrc

# Install Rust-based CLI tools
RUN . "$HOME/.cargo/env" && \
    cargo install nu starship bat lsd && \
    echo 'eval "$(starship init bash)"' >> /root/.bashrc

# Install Nerd Fonts
RUN mkdir -p /usr/local/share/fonts/NerdFonts && \
    cd /usr/local/share/fonts/NerdFonts && \
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip && \
    unzip -q JetBrainsMono.zip && \
    rm JetBrainsMono.zip && \
    fc-cache -fv

# Clean up
RUN apt-get autoremove -y && \
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

# Upgrade pip
RUN pip install --upgrade --no-cache-dir pip

# Install Python packages
RUN pip install --upgrade --no-cache-dir \
    jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions notebook==6.5.5 uv

# Set up Jupyter extensions
RUN jupyter contrib nbextension install --user && \
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
COPY ./container-template/start.sh /
RUN chmod +x /start.sh

# Welcome Message
COPY ./container-template/runpod.txt /etc/runpod.txt
RUN echo 'cat /etc/runpod.txt' >> /root/.bashrc

# Set the default command for the container
CMD [ "/start.sh" ]