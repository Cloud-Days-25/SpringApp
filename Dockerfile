FROM eclipse-temurin:17-jre-alpine as runtime

# Set working directory
WORKDIR /app

# Create a non-root user to run the app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
RUN chown -R appuser:appgroup /app

# Copy the JAR file
COPY build/libs/*.jar app.jar

# Set Spring Boot actuator port
ENV MANAGEMENT_SERVER_PORT=8080
ENV MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,prometheus
ENV MANAGEMENT_ENDPOINT_HEALTH_PROBES_ENABLED=true
ENV MANAGEMENT_HEALTH_LIVENESSSTATE_ENABLED=true
ENV MANAGEMENT_HEALTH_READINESSSTATE_ENABLED=true

# Run as non-root user
USER appuser

# Run the application
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-jar", "app.jar"]

# Expose the application port
EXPOSE 8080
