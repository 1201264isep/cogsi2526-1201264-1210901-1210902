#!/bin/bash
set -e  # Exit on error

echo "=== Starting DB VM Provisioning ==="

# Update package list
sudo apt-get update

# Install Java and required packages
echo "=== Installing Java and dependencies ==="
sudo apt-get install -y openjdk-17-jdk unzip wget net-tools

# Verify Java installation
java -version

# Define H2 variables
H2_DIR="/opt/h2"
H2_VERSION="2.2.224"  # Latest stable version
H2_ZIP="h2-${H2_VERSION}.zip"
H2_URL="https://github.com/h2database/h2database/releases/download/version-${H2_VERSION}/h2-2023-09-17.zip"

# Download and install H2 if not already present
if [[ ! -d "$H2_DIR" ]]; then
    echo "=== Downloading H2 database ==="
    cd /tmp
    # Use a stable H2 version
    wget https://repo1.maven.org/maven2/com/h2database/h2/2.1.214/h2-2.1.214.jar -O h2.jar

    # Create directory and move H2
    sudo mkdir -p $H2_DIR
    sudo mv h2.jar $H2_DIR/

    echo "H2 database installed."
else
    echo "H2 already installed."
fi

# Check if H2 is already running
if netstat -tuln | grep -q ":9092"; then
    echo "H2 server is already running on port 9092."
else
    echo "=== Starting H2 server ==="
    # Start H2 in TCP server mode
    # -tcp: Enable TCP server
    # -tcpAllowOthers: Allow remote connections
    # -tcpPort 9092: Use port 9092
    # -ifNotExists: Create database if it doesn't exist
    nohup java -cp $H2_DIR/h2.jar org.h2.tools.Server \
        -tcp -tcpAllowOthers -tcpPort 9092 \
        -web -webAllowOthers -webPort 8082 \
        -ifNotExists \
        > /home/vagrant/h2-server.log 2>&1 &

    echo $! > /home/vagrant/h2-server.pid
    echo "H2 server started (PID: $(cat /home/vagrant/h2-server.pid))"

    # Wait for H2 to start
    sleep 5
fi

# Install and configure UFW (Uncomplicated Firewall)
echo "=== Configuring firewall ==="
sudo apt-get install -y ufw

# Set default policies
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (important for Vagrant)
sudo ufw allow 22/tcp

# Allow H2 database port ONLY from app VM
sudo ufw allow from 192.168.56.12 to any port 9092 proto tcp

# Allow H2 console port (optional, for debugging)
sudo ufw allow from 192.168.56.0/24 to any port 8082 proto tcp

# Enable UFW
echo "y" | sudo ufw enable

# Show firewall status
sudo ufw status verbose

echo "=== DB VM Provisioning Complete ==="
echo "H2 Database server is running on port 9092"
echo "H2 Console available at http://192.168.56.11:8082"