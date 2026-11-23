
#!/bin/bash

set -e

echo "=============================================="
echo "   Jenkins + Java 25 + Docker Installation"
echo "=============================================="

# ==========================================================
# VARIABLES
# ==========================================================

JENKINS_VERSION="2.580.2"
JENKINS_DIR="/opt/jenkins"
JENKINS_WAR="$JENKINS_DIR/jenkins.war"
JENKINS_LOG="$JENKINS_DIR/jenkins.log"

CURRENT_USER=$(whoami)

# ==========================================================
# 1. UPDATE SYSTEM
# ==========================================================

echo ""
echo "[1/9] Updating Ubuntu..."

sudo apt-get update -y

# ==========================================================
# 2. INSTALL JAVA 25 + REQUIRED PACKAGES
# ==========================================================

echo ""
echo "[2/9] Installing Java 25 and required packages..."

sudo apt-get install -y \
    openjdk-25-jdk \
    wget \
    curl \
    ca-certificates \
    gnupg

# ==========================================================
# 3. VERIFY JAVA 25
# ==========================================================

echo ""
echo "[3/9] Checking Java version..."

java -version

# Verify Java 25 is installed
JAVA_VERSION=$(java -version 2>&1 | head -n 1)

echo ""
echo "Detected Java:"
echo "$JAVA_VERSION"

# ==========================================================
# 4. INSTALL JENKINS
# ==========================================================

echo ""
echo "[4/9] Installing Jenkins ${JENKINS_VERSION}..."

sudo mkdir -p "$JENKINS_DIR"

if [ ! -f "$JENKINS_WAR" ]; then

    echo "Downloading Jenkins ${JENKINS_VERSION}..."

    sudo wget \
        "https://get.jenkins.io/war-stable/${JENKINS_VERSION}/jenkins.war" \
        -O "$JENKINS_WAR"

else

    echo "Jenkins WAR already exists."

fi

sudo chmod 755 "$JENKINS_WAR"

# ==========================================================
# 5. CREATE JENKINS USER
# ==========================================================

echo ""
echo "[5/9] Creating Jenkins user..."

if ! id jenkins >/dev/null 2>&1; then

    sudo useradd \
        --system \
        --home-dir "$JENKINS_DIR" \
        --shell /bin/bash \
        jenkins

else

    echo "Jenkins user already exists."

fi

sudo chown -R jenkins:jenkins "$JENKINS_DIR"

# ==========================================================
# 6. INSTALL DOCKER
# ==========================================================

echo ""
echo "[6/9] Installing Docker..."

# Docker keyring
sudo install -m 0755 -d /etc/apt/keyrings

# Remove old Docker GPG key if present
sudo rm -f /etc/apt/keyrings/docker.gpg

# Download Docker GPG key
curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor \
    -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list
sudo apt-get update -y

# Install Docker
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# ==========================================================
# 7. START DOCKER
# ==========================================================

echo ""
echo "[7/9] Starting Docker..."

sudo systemctl enable docker
sudo systemctl start docker

# Add current user to Docker group
sudo usermod -aG docker "$CURRENT_USER"

# Add Jenkins user to Docker group
sudo usermod -aG docker jenkins

# ==========================================================
# 8. CREATE JENKINS SYSTEMD SERVICE
# ==========================================================

echo ""
echo "[8/9] Creating Jenkins systemd service..."

sudo tee /etc/systemd/system/jenkins-war.service > /dev/null <<EOF
[Unit]
Description=Jenkins WAR
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple

User=jenkins
Group=jenkins

WorkingDirectory=$JENKINS_DIR

ExecStart=/usr/bin/java -Djava.net.preferIPv4Stack=true -jar $JENKINS_WAR

Restart=on-failure
RestartSec=10

Environment="JENKINS_HOME=$JENKINS_DIR"

StandardOutput=append:$JENKINS_LOG
StandardError=append:$JENKINS_LOG

[Install]
WantedBy=multi-user.target
EOF

# ==========================================================
# 9. START JENKINS
# ==========================================================

echo ""
echo "[9/9] Starting Jenkins..."

sudo systemctl daemon-reload

sudo systemctl enable jenkins-war

sudo systemctl restart jenkins-war

echo ""
echo "Waiting for Jenkins to start..."

sleep 20

# ==========================================================
# VERIFICATION
# ==========================================================

echo ""
echo "=============================================="
echo "        INSTALLATION COMPLETE"
echo "=============================================="

echo ""
echo "Java:"
java -version

echo ""
echo "Docker:"
sudo docker --version

echo ""
echo "Docker Compose:"
sudo docker compose version

echo ""
echo "Docker Buildx:"
sudo docker buildx version

echo ""
echo "Jenkins:"
sudo -u jenkins /usr/bin/java -jar "$JENKINS_WAR" --version



echo ""
echo "=============================================="
echo " Jenkins and Docker Status"
echo "=============================================="


echo ""
echo "Docker Service:"
sudo systemctl is-active docker

echo ""
echo "Jenkins Service:"
sudo systemctl is-active jenkins-war

sudo systemctl --no-pager --full status jenkins-war



echo ""
echo "=============================================="
echo " Initial Admin Password"
echo "=============================================="

if [ -f "$JENKINS_DIR/secrets/initialAdminPassword" ]; then

    sudo cat "$JENKINS_DIR/secrets/initialAdminPassword"

else

    echo "Password not available yet."
    echo ""
    echo "Check:"
    echo "sudo cat $JENKINS_DIR/secrets/initialAdminPassword"

fi



echo ""
echo "=============================================="
echo " Installation Finished"
echo "=============================================="
