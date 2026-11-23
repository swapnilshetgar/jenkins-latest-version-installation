# Jenkins + Java 25 + Docker Automated Installation

An automated Bash script (`jenkins.sh`) to install and configure **Jenkins (WAR)**, **OpenJDK 25**, and **Docker** on Ubuntu systems, complete with a dedicated `systemd` service.

## What This Script Does

1. **System Update:** Updates existing Ubuntu package lists.
2. **Java 25 Setup:** Installs `openjdk-25-jdk` along with `wget`, `curl`, `ca-certificates`, and `gnupg`.
3. **Jenkins WAR Download:** Downloads Jenkins **v2.580.2** into `/opt/jenkins/jenkins.war`.
4. **User & Permissions:** Creates a dedicated `jenkins` system user with `/opt/jenkins` as its home directory.
5. **Docker Installation:** Configures the official Docker APT repository and installs `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, and `docker-compose-plugin`.
6. **Group Configuration:** Adds both the current user and the `jenkins` user to the `docker` group so Jenkins pipelines can run Docker commands without `sudo`.
7. **Systemd Service:** Creates and enables `jenkins-war.service` (configured to start after Docker and restart automatically on failure).
8. **Verification & Password Output:** Verifies installed versions, checks service statuses, and prints the initial Jenkins admin password.

---

## Prerequisites

- **OS:** Ubuntu (Debian-based Linux with `apt` and `systemd`)
- **Privileges:** A user with `sudo` access
- **Network:** Active internet connection to download packages and the Jenkins WAR file

---

## Quick Start

### 1. Download the Script

```bash
curl -O [https://raw.githubusercontent.com/swapnilshetgar/jenkins-latest-version-installation/main/jenkins.sh]
