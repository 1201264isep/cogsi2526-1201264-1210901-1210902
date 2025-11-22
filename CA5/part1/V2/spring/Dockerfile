FROM amazoncorretto:17-alpine

WORKDIR /app

# Copy the pre-built JAR from host
COPY *.jar /app/spring-app.jar

EXPOSE 8080

# Run the Spring Boot application
ENTRYPOINT ["java", "-jar", "spring-app.jar"]