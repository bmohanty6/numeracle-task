FROM eclipse-temurin:17-jdk-alpine
COPY target/demo-0.0.1-SNAPSHOT.jar demo-app.jar
ENTRYPOINT ["java","-jar","/demo-app.jar"]