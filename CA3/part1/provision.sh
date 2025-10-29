#!/bin/bash

echo "=== Starting Provisioning ==="

# Clone repository if environment variable is set
if [ "$CLONE_REPO" = "true" ]; then
    echo "Cloning repository..."
    if [ ! -d "/app/repo" ]; then
        git clone $REPO_URL /app/repo
    else
        echo "Repository already exists, pulling latest changes..."
        cd /app/repo && git pull
    fi
fi

cd /app/repo

# Debug: Show what's in the repo
echo "=== Repository structure ==="
ls -la /app/repo/
echo ""

# Build and start services if environment variable is set
if [ "$START_SERVICES" = "true" ]; then
    
    # ====== BUILD AND START SPRING BOOT APPLICATION ======
    echo "=== Starting the Spring Boot application ==="
    
    if [ -d "CA2-part2/tut-gradle" ]; then
        cd CA2-part2/tut-gradle
        
        # Configure H2 for persistent storage
        echo "Configuring H2 database for persistent storage..."
        mkdir -p src/main/resources
        cat > src/main/resources/application.properties << 'EOF'
spring.datasource.url=jdbc:h2:file:/app/data/jpadb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=update
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console
spring.h2.console.settings.web-allow-others=true
EOF
        
        # Check if it uses Gradle or Maven
        if [ -f "build.gradle" ]; then
            echo "Building with system Gradle..."
            gradle build -x test
            echo "Starting Spring Boot application with Gradle..."
            nohup gradle bootRun > /app/spring-app.log 2>&1 &
            echo $! > /app/spring-app.pid
            echo "Spring Boot application started (PID: $(cat /app/spring-app.pid))"
        elif [ -f "mvnw" ]; then
            chmod +x mvnw
            echo "Building with Maven wrapper..."
            ./mvnw clean install -DskipTests
            echo "Starting Spring Boot application with Maven..."
            nohup ./mvnw spring-boot:run > /app/spring-app.log 2>&1 &
            echo $! > /app/spring-app.pid
            echo "Spring Boot application started (PID: $(cat /app/spring-app.pid))"
        else
            echo "ERROR: No build file found in CA2-part2/tut-gradle"
        fi
        
        cd /app/repo
    else
        echo "ERROR: CA2-part2/tut-gradle directory not found!"
    fi
    
    # ====== BUILD AND START GRADLE CHAT APPLICATION ======
    echo "=== Building the Gradle chat application ==="
    
    if [ -d "CA2-part1/gradle_basic_demo-main" ]; then
        cd CA2-part1/gradle_basic_demo-main
        
        if [ -f "gradlew" ]; then
            chmod +x gradlew
            echo "Building with Gradle wrapper..."
            ./gradlew build
            
            echo "Starting chat server..."
            nohup ./gradlew runServer > /app/chat-server.log 2>&1 &
            echo $! > /app/chat-server.pid
            echo "Chat server started (PID: $(cat /app/chat-server.pid))"
        elif [ -f "build.gradle" ]; then
            echo "Building with system Gradle..."
            gradle build
            
            echo "Starting chat server..."
            nohup gradle runServer > /app/chat-server.log 2>&1 &
            echo $! > /app/chat-server.pid
            echo "Chat server started (PID: $(cat /app/chat-server.pid))"
        else
            echo "ERROR: No build.gradle or gradlew found"
        fi
        
        cd /app/repo
    else
        echo "ERROR: CA2-part1/gradle_basic_demo-main directory not found!"
    fi
    
    # Wait a bit for services to start
    echo "Waiting for services to initialize..."
    sleep 5
fi

echo ""
echo "=== Provisioning Complete ==="
echo "============================================"
echo "Spring Boot Application:"
echo "  Web UI: http://localhost:8080"
echo "  H2 Console: http://localhost:8080/h2-console"
echo "    JDBC URL: jdbc:h2:file:/app/data/jpadb"
echo "    Username: sa"
echo "    Password: (leave empty)"
echo ""
echo "Chat Server: localhost:59001"
echo "============================================"
echo ""
echo "View logs:"
echo "  Spring Boot: docker exec cogsi_part1 cat /app/spring-app.log"
echo "  Chat Server: docker exec cogsi_part1 cat /app/chat-server.log"
echo ""
echo "Check if services are running:"
echo "  docker exec cogsi_part1 ps aux | grep java"
echo ""

# Keep container running
tail -f /dev/null
