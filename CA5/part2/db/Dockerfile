FROM amazoncorretto:17-alpine

WORKDIR /app

# Download H2 database JAR
RUN apk add --no-cache wget && \
    wget https://repo1.maven.org/maven2/com/h2database/h2/2.2.224/h2-2.2.224.jar -O h2.jar && \
    apk del wget

# Create directory for database files
RUN mkdir -p /app/data

EXPOSE 8082 9092

# Run H2 in server mode
# -tcp: Enable TCP server
# -tcpAllowOthers: Allow remote connections
# -ifNotExists: Create database if it doesn't exist
CMD ["java", "-cp", "h2.jar", "org.h2.tools.Server", \
     "-tcp", "-tcpAllowOthers", "-tcpPort", "9092", \
     "-web", "-webAllowOthers", "-webPort", "8082", \
     "-ifNotExists"]