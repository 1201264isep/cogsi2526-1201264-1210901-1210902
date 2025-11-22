FROM amazoncorretto:17-alpine

WORKDIR /app

# Install Git and Gradle
RUN apk add --no-cache git gradle

# Clone the repository
RUN git clone https://github.com/pedroteixeira80/cogsi2526-1201264-1210901-1210902.git /app

WORKDIR /app/CA2-part1/gradle_basic_demo-main

# Build the application
RUN gradle build -x test --no-daemon

# Run the chat server
CMD ["java", "-cp", "build/libs/basic_demo-0.1.0.jar", "basic_demo.ChatServerApp", "59001"]