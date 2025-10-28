#!/bin/bash
set -e  # Exit on error

echo "=== Starting APP VM Provisioning ==="

# Get environment variables
CLONE_REPO=${CLONE_REPO:-$ARG_CLONE_REPO}
START_SERVICES=${START_SERVICES:-$ARG_START_SERVICES}
GITHUB_TOKEN=${GITHUB_TOKEN}

echo "Configuration:"
echo "  - GITHUB_TOKEN: ${GITHUB_TOKEN:+[SET]}"
echo "  - CLONE_REPO: ${CLONE_REPO}"
echo "  - START_SERVICES: ${START_SERVICES}"

# Update package list
echo "=== Updating system ==="
sudo apt-get update

# Install dependencies
echo "=== Installing dependencies ==="
sudo apt-get install -y openjdk-17-jdk git netcat-openbsd curl wget unzip net-tools

# Install Gradle
echo "=== Installing Gradle ==="
if [ ! -f /usr/bin/gradle ]; then
    GRADLE_VERSION=8.5
    cd /tmp
    wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
    sudo unzip -d /opt/gradle gradle-${GRADLE_VERSION}-bin.zip
    sudo ln -sf /opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle
fi

# Verify installations
echo "=== Verifying installations ==="
java -version
git --version
gradle -version

# Set Git configuration
git config --global user.email "1210902@isep.ipp.pt"
git config --global user.name "Pedro"

# Clone repository if requested
if [[ "${CLONE_REPO}" == "true" ]]; then
    echo "=== Cloning repository ==="

    if [ -d "/home/vagrant/app" ]; then
        echo "Removing existing app directory..."
        rm -rf /home/vagrant/app
    fi

    # Clone your repository
    echo "Cloning repository with authentication..."
    git clone https://${GITHUB_TOKEN}@github.com/pedroteixeira80/cogsi2526-1201264-1210901-1210902.git /home/vagrant/app

    if [ $? -eq 0 ]; then
        echo "Repository cloned successfully!"
        sudo chown -R vagrant:vagrant /home/vagrant/app
    else
        echo "ERROR: Failed to clone repository"
        exit 1
    fi
else
    echo "=== Skipping repository cloning ==="
fi

# Configure and start application if requested
if [[ "${START_SERVICES}" == "true" ]] && [ -d "/home/vagrant/app" ]; then
    echo "=== Configuring Spring Boot application ==="

    # Path to your Gradle Spring Boot project
    APP_DIR="/home/vagrant/app/CA2-part2/tut-gradle"

    if [ ! -d "$APP_DIR" ]; then
        echo "ERROR: Application directory not found at $APP_DIR"
        echo "Directory structure:"
        ls -la /home/vagrant/app/ 2>/dev/null || true
        ls -la /home/vagrant/app/CA2-part2/ 2>/dev/null || true
        exit 1
    fi

    echo "Using application directory: $APP_DIR"
    cd "$APP_DIR"

    # Check Gradle wrapper integrity
    echo "=== Checking Gradle wrapper ==="
    if [ -f "./gradlew" ] && [ -f "gradle/wrapper/gradle-wrapper.jar" ]; then
        echo "Gradle wrapper appears complete"
        chmod +x ./gradlew
        GRADLE_CMD="./gradlew"
    else
        echo "Gradle wrapper incomplete or missing, using system Gradle"
        GRADLE_CMD="gradle"

        # Regenerate wrapper using system Gradle
        echo "Regenerating Gradle wrapper..."
        gradle wrapper --gradle-version 8.5
        chmod +x ./gradlew
        GRADLE_CMD="./gradlew"
    fi

    # Create application.properties for H2 remote connection
    echo "=== Creating application.properties ==="
    mkdir -p src/main/resources

    cat > src/main/resources/application.properties << 'EOFPROPS'
# H2 Database Configuration (Remote DB Server)
spring.datasource.url=jdbc:h2:tcp://192.168.56.11:9092/~/jpadb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=

# JPA Configuration
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=update

# H2 Console Configuration
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console
spring.h2.console.settings.web-allow-others=true

# Spring Data REST
spring.data.rest.base-path=/api
EOFPROPS

    echo "=== Waiting for DB server to be ready ==="
    MAX_RETRIES=30
    RETRY_COUNT=0

    until nc -z 192.168.56.11 9092 2>/dev/null; do
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            echo "ERROR: Database server not available after $MAX_RETRIES attempts"
            exit 1
        fi
        echo "Waiting for DB VM... (attempt $RETRY_COUNT/$MAX_RETRIES)"
        sleep 5
    done

    echo "Database server is ready!"

    echo "=== Building the application ==="
    echo "Using: $GRADLE_CMD"
    $GRADLE_CMD clean build -x test

    echo "=== Starting Spring Boot application with Gradle ==="
    # Start the application in background using Gradle bootRun
    nohup $GRADLE_CMD bootRun > /home/vagrant/spring-app.log 2>&1 &
    echo $! > /home/vagrant/spring-app.pid

    echo "Spring Boot application started (PID: $(cat /home/vagrant/spring-app.pid))"
    echo ""
    echo "Access information:"
    echo "  - Application: http://localhost:8080"
    echo "  - H2 Console: http://192.168.56.11:8082"
    echo "    JDBC URL: jdbc:h2:tcp://192.168.56.11:9092/~/jpadb"
    echo ""
    echo "Logs: tail -f /home/vagrant/spring-app.log"
    echo "Check status: ps aux | grep gradle"
else
    echo "=== Skipping application startup ==="
fi

echo "=== APP VM Provisioning Complete ==="