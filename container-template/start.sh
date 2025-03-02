#!/bin/bash
set -e  # Exit the script if any statement returns a non-true return value

# ---------------------------------------------------------------------------- #
#                          Function Definitions                                #
# ---------------------------------------------------------------------------- #

# Start nginx service
start_nginx() {
    echo "Starting Nginx service..."
    service nginx start
}

# Execute script if exists
execute_script() {
    local script_path=$1
    local script_msg=$2
    if [[ -f ${script_path} ]]; then
        echo "${script_msg}"
        bash ${script_path}
    fi
}

# Setup ssh
setup_ssh() {
    if [[ $PUBLIC_KEY ]]; then
        echo "Setting up SSH..."
        mkdir -p ~/.ssh
        echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
        chmod 700 -R ~/.ssh

         if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
            ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -q -N ''
            echo "RSA key fingerprint:"
            ssh-keygen -lf /etc/ssh/ssh_host_rsa_key.pub
        fi

        if [ ! -f /etc/ssh/ssh_host_dsa_key ]; then
            ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -q -N ''
            echo "DSA key fingerprint:"
            ssh-keygen -lf /etc/ssh/ssh_host_dsa_key.pub
        fi

        if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
            ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -q -N ''
            echo "ECDSA key fingerprint:"
            ssh-keygen -lf /etc/ssh/ssh_host_ecdsa_key.pub
        fi

        if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
            ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -q -N ''
            echo "ED25519 key fingerprint:"
            ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
        fi

        service ssh start

        echo "SSH host keys:"
        for key in /etc/ssh/*.pub; do
            echo "Key: $key"
            ssh-keygen -lf $key
        done
    fi
}

# Export env vars
export_env_vars() {
    echo "Exporting environment variables..."
    # For bash
    printenv | grep -E '^RUNPOD_|^PATH=|^_=' | awk -F = '{ print "export " $1 "=\"" $2 "\"" }' >> /etc/rp_environment
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /etc/rp_environment
    chmod +r /etc/rp_environment
    echo 'source /etc/rp_environment' >> ~/.bashrc
    
    # For nushell
    printenv | grep -E '^RUNPOD_|^PATH=|^_=' | awk -F = '{ print "$env." $1 " = \"" $2 "\"" }' > /etc/rp_environment.nu
    echo '$env.PATH = ($"($env.HOME)/.cargo/bin:" + ($env.PATH | str join ":"))' >> /etc/rp_environment.nu
    chmod +r /etc/rp_environment.nu
    echo 'source /etc/rp_environment.nu' >> ~/.config/nushell/config.nu
}

# Start jupyter lab with idle timeout
start_jupyter() {
    if [[ $JUPYTER_PASSWORD ]]; then
        # Set default idle timeout to 60 minutes if not specified
        JUPYTER_IDLE_TIMEOUT=${JUPYTER_IDLE_TIMEOUT:-60}
        echo "Starting Jupyter Lab with idle timeout of ${JUPYTER_IDLE_TIMEOUT} minutes..."
        mkdir -p /workspace && \
        cd / && \
        nohup jupyter lab --allow-root --no-browser --port=8888 --ip=* \
            --FileContentsManager.delete_to_trash=False \
            --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
            --ServerApp.token=$JUPYTER_PASSWORD \
            --ServerApp.allow_origin=* \
            --ServerApp.preferred_dir=/workspace \
            --MappingKernelManager.cull_idle_timeout=$((JUPYTER_IDLE_TIMEOUT * 60)) \
            --MappingKernelManager.cull_interval=60 \
            --MappingKernelManager.cull_connected=True \
            &> /jupyter.log &
        
        # Store the Jupyter process ID
        JUPYTER_PID=$!
        echo "Jupyter Lab started with PID: $JUPYTER_PID"
        echo $JUPYTER_PID > /jupyter.pid
    fi
}

# Monitor Jupyter and shutdown container when it exits
monitor_jupyter_and_shutdown() {
    if [[ -f /jupyter.pid ]]; then
        JUPYTER_PID=$(cat /jupyter.pid)
        echo "Monitoring Jupyter process (PID: $JUPYTER_PID)..."
        
        # Start monitoring in background
        (
            # Wait for the Jupyter process to finish
            while kill -0 $JUPYTER_PID 2>/dev/null; do
                sleep 10
            done
            
            echo "Jupyter process has terminated. Shutting down container..."
            # Give some time for cleanup
            sleep 5
            # Exit the container
            kill 1
        ) &
    fi
}

# ---------------------------------------------------------------------------- #
#                               Main Program                                   #
# ---------------------------------------------------------------------------- #

start_nginx

execute_script "/pre_start.sh" "Running pre-start script..."

echo "Pod Started"

setup_ssh
start_jupyter
export_env_vars
monitor_jupyter_and_shutdown

execute_script "/post_start.sh" "Running post-start script..."

echo "Start script(s) finished, pod is ready to use."
echo "Jupyter will automatically shutdown after ${JUPYTER_IDLE_TIMEOUT:-60} minutes of inactivity, which will terminate the container."

# Wait for signals
wait
