FROM amazoncorretto:17-alpine

WORKDIR /app

# Install Git and Gradle
RUN apk add --no-cache git gradle

# Clone the repository
RUN git clone https://github.com/pedroteixeira80/cogsi2526-1201264-1210901-1210902.git /app

# Navigate to the SPRING application directory
WORKDIR /app/CA2-part2/tut-gradle

# Build the Spring Boot application
RUN gradle build -x test --no-daemon

EXPOSE 8080

# Run the Spring Boot application
ENTRYPOINT ["gradle", "bootRun", "--no-daemon"]