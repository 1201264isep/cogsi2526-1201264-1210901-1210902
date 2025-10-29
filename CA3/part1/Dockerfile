FROM ubuntu:22.04


# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    openjdk-17-jdk \
    maven \
    wget \
    unzip \
    curl \
    netcat \
    && rm -rf /var/lib/apt/lists/*

# Install Gradle
RUN wget https://services.gradle.org/distributions/gradle-8.5-bin.zip -P /tmp \
    && unzip -d /opt/gradle /tmp/gradle-8.5-bin.zip \
    && rm /tmp/gradle-8.5-bin.zip

ENV GRADLE_HOME=/opt/gradle/gradle-8.5
ENV PATH=${GRADLE_HOME}/bin:${PATH}

# Set working directory
WORKDIR /app

# Set Java home
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Expose ports
EXPOSE 8080 59001

# Default command
CMD ["/bin/bash"]
