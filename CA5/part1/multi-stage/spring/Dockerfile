# Stage 1: Build the application
FROM amazoncorretto:17-alpine AS builder

WORKDIR /app

# Install Git and Gradle
RUN apk add --no-cache git gradle

# Clone the repository
RUN git clone https://github.com/pedroteixeira80/cogsi2526-1201264-1210901-1210902.git /app

# Navigate to the Spring application directory
WORKDIR /app/CA2-part2/tut-gradle

# Build the application
RUN gradle build -x test --no-daemon

# Stage 2: Runtime image
FROM amazoncorretto:17-alpine

WORKDIR /app

# Copy ONLY the JAR from the build stage
COPY --from=builder /app/CA2-part2/tut-gradle/build/libs/*.jar /app/spring-app.jar

EXPOSE 8080

# Run the Spring Boot application
ENTRYPOINT ["java", "-jar", "spring-app.jar"]