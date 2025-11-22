# Stage 1: Build the application
FROM amazoncorretto:17-alpine AS builder

WORKDIR /app

# Install Git and Gradle
RUN apk add --no-cache git gradle

# Clone the repository
RUN git clone https://github.com/pedroteixeira80/cogsi2526-1201264-1210901-1210902.git /app

# Navigate to the chat application directory
WORKDIR /app/CA2-part1/gradle_basic_demo-main

# Build the application
RUN gradle build -x test --no-daemon

# Stage 2: Runtime image
FROM amazoncorretto:17-alpine

WORKDIR /app

# Copy ONLY the JAR from the build stage
COPY --from=builder /app/CA2-part1/gradle_basic_demo-main/build/libs/basic_demo-0.1.0.jar /app/basic_demo-0.1.0.jar

# Run the chat server
CMD ["java", "-cp", "basic_demo-0.1.0.jar", "basic_demo.ChatServerApp", "59001"]