================================================================================
                        DOCKERFILE - ALL INSTRUCTIONS
================================================================================

--------------------------------------------------------------------------------
1. BASE IMAGE
--------------------------------------------------------------------------------

FROM        Sets the base image
            FROM eclipse-temurin:17-jre        -eclipse-temurin:17-jre-jammy → Ubuntu 22.04
            FROM ubuntu:22.04
            FROM scratch  (empty base image)

FROM eclipse-temurin:17-jre-alpine    # your current
FROM eclipse-temurin:17-jre-jammy     # ubuntu based
FROM eclipse-temurin:17-jdk-alpine    # with JDK
FROM eclipse-temurin:17               # full version

--------------------------------------------------------------------------------
2. FILESYSTEM
--------------------------------------------------------------------------------

WORKDIR     Sets working directory inside container
            WORKDIR /app
            WORKDIR /usr/local/app
            (creates directory if it doesn't exist)

COPY        Copies files from host to container
            COPY target/app.jar app.jar           -- “Host” means the same machine (server) where Docker is installed.
            COPY src/ /app/src/

COPY target/*.jar app.jar  ----   

Your machine:          Inside Container:
target/
  pipeline.jar   →→→   app.jar

Rule to remember:
src/ → copy inside contents
src → copy folder itself

            COPY . .  (copy everything)


          COPY target/app.jar app.jar

        (Host Machine / Server)
        -----------------------
        target/app.jar
              |
              |   (COPY during docker build)
              v
        -----------------------
        (Docker Container/Image)
        app.jar


ADD         Like COPY but also handles URLs and tar extraction
            ADD app.tar.gz /app/
            ADD https://example.com/file.txt /app/
            (prefer COPY unless you need ADD features)

RUN         Executes commands during image BUILD time
            RUN apt-get update && apt-get install -y curl
            RUN mvn clean install
            RUN mkdir -p /app/logs

--------------------------------------------------------------------------------
3. ENVIRONMENT
--------------------------------------------------------------------------------

ENV         Sets environment variables (available at build + runtime)
            ENV JAVA_HOME=/usr/lib/jvm/java-17
            ENV APP_ENV=production
            ENV PORT=8080

ARG         Build-time variables only (NOT available at runtime)
            ARG VERSION=1.0
            ARG BUILD_DATE
            docker build --build-arg VERSION=2.0 .

VOLUME      Creates mount point for external/persistent storage
            VOLUME ["/data"]
            VOLUME /logs
            VOLUME /app/config

--------------------------------------------------------------------------------
4. NETWORKING
--------------------------------------------------------------------------------

EXPOSE      Documents which port container listens on
            EXPOSE 8080
            EXPOSE 8080/tcp
            EXPOSE 8080/udp
            EXPOSE 8080 9090  (multiple ports)
            NOTE: Does not actually publish the port, just documents it

--------------------------------------------------------------------------------
5. EXECUTION
--------------------------------------------------------------------------------

CMD         Default command when container STARTS
            CMD ["java", "-jar", "app.jar"]
            CMD ["nginx", "-g", "daemon off;"]
            Can be overridden at runtime

Because your app is meant to run after container starts, not during build.

            Only LAST CMD in Dockerfile takes effect

ENTRYPOINT  Main executable command, harder to override than CMD
            ENTRYPOINT ["java", "-jar", "app.jar"]
            ENTRYPOINT ["nginx"]
            Often combined with CMD for default arguments

            COMBINED EXAMPLE:
            ENTRYPOINT ["java"]
            CMD ["-jar", "app.jar"]
            (CMD args can be overridden, ENTRYPOINT stays fixed)

DIFFERENCE:
            RUN         = runs during BUILD time
            CMD         = runs when CONTAINER STARTS (overridable)
            ENTRYPOINT  = runs when CONTAINER STARTS (not easily overridden)

--------------------------------------------------------------------------------
6. METADATA
--------------------------------------------------------------------------------

LABEL       Adds metadata/information to image
            LABEL version="1.0"
            LABEL maintainer="team@worldpay.com"
            LABEL description="IQ User Profile Service"
            LABEL build-date="2024-01-01"

MAINTAINER  DEPRECATED - use LABEL instead
            MAINTAINER team@worldpay.com

--------------------------------------------------------------------------------
7. USER & SECURITY
--------------------------------------------------------------------------------

USER        Sets user for subsequent RUN / CMD / ENTRYPOINT
            USER appuser
            USER 1001
            USER appuser:appgroup

            BEST PRACTICE:
            RUN adduser --system --group appuser
            USER appuser

HEALTHCHECK Tells Docker how to test if container is healthy
            HEALTHCHECK --interval=30s --timeout=3s \
              CMD curl -f http://localhost:8080/actuator/health || exit 1

            Options:
            --interval=30s    (how often to check, default 30s)
            --timeout=3s      (how long before timeout, default 30s)
            --retries=3       (failures before unhealthy, default 3)
            --start-period=5s (wait before first check)

            HEALTHCHECK NONE  (disables inherited healthcheck)

--------------------------------------------------------------------------------
8. MULTI-STAGE BUILD
--------------------------------------------------------------------------------

            Used to keep final image small by separating build and runtime

            EXAMPLE:
            # Stage 1 - Build
            FROM maven:3.8 AS builder
            WORKDIR /app
            COPY pom.xml .
            COPY src ./src
            RUN mvn clean install -DskipTests

            # Stage 2 - Runtime (only copies built jar)
            FROM eclipse-temurin:17-jre
            WORKDIR /app
            COPY --from=builder /app/target/app.jar app.jar
            EXPOSE 8080
            CMD ["java", "-jar", "app.jar"]

            BENEFIT: Final image only has JRE + jar, not Maven/JDK/source code

--------------------------------------------------------------------------------
9. MISC INSTRUCTIONS
--------------------------------------------------------------------------------

SHELL       Changes default shell used for RUN commands
            SHELL ["/bin/bash", "-c"]
            SHELL ["powershell", "-command"]
            Default shell is ["/bin/sh", "-c"]

STOPSIGNAL  Sets the system call signal to stop the container
            STOPSIGNAL SIGTERM
            STOPSIGNAL SIGKILL

ONBUILD     Trigger instruction for child images
            ONBUILD COPY . /app
            ONBUILD RUN mvn install
            Runs ONLY when another image uses this as its base image

--------------------------------------------------------------------------------
10. QUICK REFERENCE - WHEN EACH INSTRUCTION RUNS
--------------------------------------------------------------------------------

Instruction     When it runs        Purpose
----------------------------------------------------------
FROM            Build time          Set base image
ARG             Build time          Build-only variables
RUN             Build time          Execute shell commands
COPY            Build time          Copy files into image
ADD             Build time          Copy + URL + tar support
WORKDIR         Build time          Set working directory
ENV             Build + Runtime     Set environment variables
LABEL           Build time          Add metadata
EXPOSE          Documentation       Document ports
USER            Runtime             Set running user
CMD             Runtime             Default start command
ENTRYPOINT      Runtime             Main executable
HEALTHCHECK     Runtime             Monitor container health
VOLUME          Runtime             Define mount points
SHELL           Build time          Change default shell
STOPSIGNAL      Runtime             Signal to stop container
ONBUILD         Child build time    Trigger for child images

--------------------------------------------------------------------------------
11. MOST COMMONLY USED (Real Projects)
--------------------------------------------------------------------------------

FROM
WORKDIR
COPY
RUN
ENV
EXPOSE
USER
HEALTHCHECK
CMD

--------------------------------------------------------------------------------
12. PRODUCTION READY EXAMPLE (Java Spring Boot)
--------------------------------------------------------------------------------

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY target/app.jar app.jar
EXPOSE 8080
RUN adduser --system --group appuser
USER appuser
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/actuator/health || exit 1
CMD ["java", "-jar", "app.jar"]

--------------------------------------------------------------------------------
13. BEST PRACTICES
--------------------------------------------------------------------------------

1.  Use specific image tags, not latest
    GOOD:  FROM eclipse-temurin:17-jre
    BAD:   FROM openjdk:latest

2.  Use JRE not JDK for runtime
    GOOD:  FROM eclipse-temurin:17-jre
    BAD:   FROM openjdk:17  (includes full compiler)

3.  Never run as root
    Always add USER instruction

4.  Combine RUN commands to reduce layers
    GOOD:  RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
    BAD:   RUN apt-get update
           RUN apt-get install -y curl

5.  Use .dockerignore to exclude unnecessary files
    Add: .git, target/, node_modules/, *.log

6.  Use multi-stage builds to keep image small

7.  Always add HEALTHCHECK in production

8.  Use ENV for configuration, ARG for build-time only values

================================================================================
                              END OF DOCUMENT
================================================================================

docker build -t <username>/<imagename>:<tag> <path>

docker build -t myusername/myapp:1.0 .

.         --       build context — current directory where Dockerfile lives
myusernameyour     --       Docker Hub username


----------------------------------------------------
docker run -p 8080:8080 username/image:tag

docker push username/image:tag

docker pull username/image:tag

IMAGES

docker images                        # list all images
docker rmi username/image:tag        # remove an image
docker tag myapp:1.0 myapp:latest    # tag an existing image
docker image prune                   # remove unused images

CONTAINERS

docker ps                            # list running containers
docker ps -a                         # list all containers
docker stop mycontainer              # stop a container
docker start mycontainer             # start a stopped container
docker restart mycontainer           # restart a container
docker rm mycontainer                # remove a container
docker rm -f mycontainer             # force remove running container

LOGS & EXEC

docker logs mycontainer              # view container logs
docker logs -f mycontainer           # follow/stream logs
docker exec -it mycontainer bash     # open shell inside container
docker inspect mycontainer           # detailed container info

SYSTEM

docker system prune                  # remove all unused resources
docker system prune -a               # remove everything unused
docker stats                         # live resource usage
docker info                          # docker system info

LOGIN / LOGOUT

docker login                         # login to Docker Hub
docker login registry.example.com   # login to private registry
docker logout                        # logout























