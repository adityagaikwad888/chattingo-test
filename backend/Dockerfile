# Stage 1: Build dependencies cache
FROM maven:3.8.5-openjdk-17-slim AS dependencies

WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B


# Stage 2: Build application
FROM maven:3.8.5-openjdk-17-slim AS build

WORKDIR /app
COPY pom.xml .
COPY --from=dependencies /root/.m2 /root/.m2
COPY src ./src
RUN mvn clean package -DskipTests


# Stage 3: Production runtime
FROM eclipse-temurin:17-jre-alpine AS production


RUN apk add --no-cache curl

WORKDIR /app

# Create log directories properly with full permissions
RUN mkdir -p /var/log/chattingo/app && \
    mkdir -p /var/log/chattingo/auth && \
    mkdir -p /var/log/chattingo/chat && \
    mkdir -p /var/log/chattingo/error && \
    mkdir -p /var/log/chattingo/system && \
    mkdir -p /var/log/chattingo/websocket && \
    chmod -R 777 /var/log/chattingo

COPY --from=build /app/target/*.jar app.jar
COPY src/main/resources/application.properties ./config/
COPY src/main/resources/logback-spring.xml ./config/

ENV SPRING_PROFILES_ACTIVE=production \
    LOG_PATH=/var/log/chattingo \
    JAVA_OPTS="-Xmx512m -Xms256m -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

EXPOSE 8080


HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
