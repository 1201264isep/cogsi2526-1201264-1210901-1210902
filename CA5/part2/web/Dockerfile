FROM amazoncorretto:17-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git gradle

RUN git clone https://github.com/pedroteixeira80/cogsi2526-1201264-1210901-1210902.git /app

WORKDIR /app/CA2-part2/tut-gradle

RUN mkdir -p src/main/resources && \
    echo "spring.datasource.url=\${SPRING_DATASOURCE_URL:jdbc:h2:mem:testdb}" > src/main/resources/application.properties && \
    echo "spring.datasource.driverClassName=\${SPRING_DATASOURCE_DRIVERCLASSNAME:org.h2.Driver}" >> src/main/resources/application.properties && \
    echo "spring.datasource.username=\${SPRING_DATASOURCE_USERNAME:sa}" >> src/main/resources/application.properties && \
    echo "spring.datasource.password=\${SPRING_DATASOURCE_PASSWORD:}" >> src/main/resources/application.properties && \
    echo "spring.jpa.database-platform=\${SPRING_JPA_DATABASE_PLATFORM:org.hibernate.dialect.H2Dialect}" >> src/main/resources/application.properties && \
    echo "spring.jpa.hibernate.ddl-auto=\${SPRING_JPA_HIBERNATE_DDL_AUTO:update}" >> src/main/resources/application.properties && \
    echo "spring.h2.console.enabled=\${SPRING_H2_CONSOLE_ENABLED:true}" >> src/main/resources/application.properties && \
    echo "spring.h2.console.path=\${SPRING_H2_CONSOLE_PATH:/h2-console}" >> src/main/resources/application.properties

RUN gradle build -x test --no-daemon

FROM amazoncorretto:17-alpine

WORKDIR /app

COPY --from=builder /app/CA2-part2/tut-gradle/build/libs/*.jar /app/spring-app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "spring-app.jar"]