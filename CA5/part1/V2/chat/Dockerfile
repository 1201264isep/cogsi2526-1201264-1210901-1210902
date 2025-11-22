FROM amazoncorretto:17-alpine

WORKDIR /app

# Copy the pre-built JAR from host
COPY basic_demo-0.1.0.jar /app/basic_demo-0.1.0.jar

# Run the chat server
CMD ["java", "-cp", "basic_demo-0.1.0.jar", "basic_demo.ChatServerApp", "59001"]