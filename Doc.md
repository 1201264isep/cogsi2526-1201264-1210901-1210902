# Alternative Solution Analysis: Docker vs. Vagrant

## 1. Alternative Technological Solution

An alternative to the VM-based approach of Vagrant is **containerization**, specifically using **Docker** and **Docker Compose**.  
This changes from virtualizing an entire hardware stack to virtualizing only the application's environment. Docker packages an application and its dependencies into lightweight, portable units called **containers**, while Docker Compose orchestrates multi-container applications.

| Feature / Aspect       | Vagrant (with VirtualBox) | Docker Compose |
| :--------------------- | :------------------------- | :-------------- |
| **Virtualization Type** | **Full Virtualization (VMs)**. Uses a hypervisor to run an independent guest operating system with its own kernel. | **OS-Level Virtualization (Containers)**. Uses containers for application-level virtualization, sharing the host OS's kernel. |
| **Isolation** | **Complete OS-level Isolation.** Each VM is an independent system offering strong separation from the host and other VMs. | **Application-level Isolation.** Containers are isolated from each other but share the host kernel. |
| **Startup Speed** | **Slow (Minutes).** Startup is slow, as each VM must go through the entire operating system boot process. | **Fast (Seconds).** Offers almost instant startup, as containers use the host's kernel and do not need to boot an operating system. |

---

## 2. Implementation with Docker and Docker Compose

This section details how Docker and Docker Compose were used to fulfill the requirements.

---

### Part 1: All-in-One Environment in a Single Container

The goal of Part 1 was to create a single, self-contained environment that clones, builds, and runs both the Spring Boot REST service and the Gradle chat application.

#### Dockerfile for the Unified Environment

This Dockerfile is responsible for creating a base image with all the necessary tools and dependencies installed.

- **Base Image:** 'ubuntu:22.04'
- **Dependencies:** Installs 'git', 'openjdk-17-jdk', 'maven', and a specific version of 'gradle' to handle different build systems.
- **Exposed Ports:** 8080 for the Spring web app, and 59001 for the chat server.

```Dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y     git     openjdk-17-jdk     maven     wget     unzip     && rm -rf /var/lib/apt/lists/*

# Install Gradle
RUN wget https://services.gradle.org/distributions/gradle-8.5-bin.zip -P /tmp     && unzip -d /opt/gradle /tmp/gradle-8.5-bin.zip     && rm /tmp/gradle-8.5-bin.zip

ENV GRADLE_HOME=/opt/gradle/gradle-8.5
ENV PATH=${GRADLE_HOME}/bin:${PATH}

# Set working directory
WORKDIR /app

# Expose ports
EXPOSE 8080 59001

# Default command
CMD ["/bin/bash"]
```

#### Automating Cloning, Building, and Starting Applications

- **'docker-compose.yml'**: Builds the Docker image and runs the container. It uses environment variables ('CLONE_REPO', 'START_SERVICES') to dynamically control behavior.
- **'provision.sh'**: Executed when the container starts. It clones the repository, builds both applications, and starts them as background services.  
  The final 'tail -f /dev/null' command keeps the container running after initialization.

```yaml
# part1/docker-compose.yml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
      - "59001:59001"
    volumes:
      - ./data:/app/data
      - ./provision.sh:/app/provision.sh
    environment:
      - CLONE_REPO=true
      - START_SERVICES=true
      - REPO_URL=https://...
    command: /bin/bash /app/provision.sh
'''

---

### Ensuring H2 Database Retains Data Between Restarts

To ensure data persistence, a Docker volume is used:

- In 'docker-compose.yml', the line 'volumes: - ./data:/app/data' maps a local directory to the container’s '/app/data'.
- The 'provision.sh' script dynamically creates an 'application.properties' file for Spring Boot, configuring H2 to store its database file in this persistent location ('spring.datasource.url=jdbc:h2:file:/app/data/jpadb').  
  This ensures that even if the container is destroyed and recreated, the database data remains intact.

---

### Part 2: App and Database in a Multi-Container Environment

The goal of Part 2 was to separate the Spring application and the H2 database into two distinct containers.

#### Dockerfile for the H2 Database ('part2/DockerfileDB')

This Dockerfile creates a lightweight container for running H2 in server mode.

- **H2 Installation:** Downloads a specific H2 JAR for consistent versioning.
- **Server Mode:** The  instruction starts the H2 database server, configured to accept remote TCP connections ('-tcp -tcpAllowOthers') on port 9092 .

```Dockerfile
# part2/DockerfileDB
FROM eclipse-temurin:17-jdk-focal
RUN apt-get update && apt-get install -y wget netcat-openbsd

ENV H2_DIR=/opt/h2
ENV H2_DATA_DIR=/opt/h2-data

RUN mkdir -p $H2_DIR && mkdir -p $H2_DATA_DIR
RUN wget https://repo1.maven.org/maven2/com/h2database/h2/2.1.214/h2-2.1.214.jar -O $H2_DIR/h2.jar

WORKDIR $H2_DATA_DIR
EXPOSE 9092

CMD ["java", "-cp", "/opt/h2/h2.jar", "org.h2.tools.Server",
     "-tcp", "-tcpAllowOthers", "-tcpPort", "9092",
     "-baseDir", "/opt/h2-data", "-ifNotExists"]
```

#### Dockerfile for the Spring Application ('part2/DockerfileApp')

- **Stage 1:** Uses 'gradle:8.5.0-jdk17' to install Git, clone the repository, and build the application.
- **Stage 2:** Uses a minimal 'eclipse-temurin:17-jre-focal' base image to run the compiled JAR file, ensuring a smaller and more secure runtime image.

```Dockerfile
# part2/DockerfileApp
# === STAGE 1: Build the application ===
FROM gradle:8.5.0-jdk17 AS builder
RUN apt-get update && apt-get install -y git

WORKDIR /home/gradle/project
ARG REPO_URL
RUN git clone ${REPO_URL} .
WORKDIR /home/gradle/project/CA2-part2/tut-gradle
RUN gradle build -x test

# === STAGE 2: Create the final, lightweight runtime image ===
FROM eclipse-temurin:17-jre-focal
WORKDIR /app
COPY --from=builder /home/gradle/project/CA2-part2/tut-gradle/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

### Orchestration, Networking, and Startup Automation

The 'docker-compose.yml' file defines and connects the two services:

```yaml
# part2/docker-compose.yml
services:
  db:
    build:
      context: .
      dockerfile: DockerfileDB
    container_name: cogsi_h2_database
    volumes:
      - ./db-data:/opt/h2-data
    networks:
      cogsi_network:
        ipv4_address: 172.20.0.10
    healthcheck:
      test: ["CMD-SHELL", "nc -z 172.20.0.10 9092 || exit 1"]
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 10s

  app:
    build:
      context: .
      dockerfile: DockerfileApp
      args:
        REPO_URL: https://<TOKEN>@github.com/pedroteixeira80/cogsi2526-1201264-1210901-1210902.git
    ports:
      - "8080:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:h2:tcp://db:9092/./h2-data/jpadb
      - SPRING_DATASOURCE_USERNAME=sa
      - SPRING_DATASOURCE_PASSWORD=
    networks:
      cogsi_network:
        ipv4_address: 172.20.0.20
    depends_on:
      db:
        condition: service_healthy

networks:
  cogsi_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

#### Notes

- **Configuring H2 in Server Mode:**  
  The 'app' service connects to the database via environment variables.  
  The URL 'jdbc:h2:tcp://db:9092/...' uses the service name 'db', which Docker resolves automatically through its internal network.

- **Automating Startup Order:**  
  The healthcheck ensures the database container is ready before the app starts.  
  Docker Compose waits for the 'db' service to report healthy before launching the 'app'.

- **Security to Restrict Database Access:**  
  The database container does **not** expose port 9092 to the host, only to the internal network, ensuring that only the app container can access it.

- **Resource Management:**  
  No CPU or memory limits were configured. Docker dynamically allocates host resources as needed.
