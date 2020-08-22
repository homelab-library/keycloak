# Build stage
FROM adoptopenjdk:11-jdk-hotspot-bionic as builder

RUN apt-get update && apt-get install -yy curl

ENV KEYCLOAK_VERSION="11.0.1" \
    JDBC_POSTGRES_VERSION="42.2.5" \
    JDBC_MYSQL_VERSION="8.0.19" \
    JDBC_MARIADB_VERSION="2.5.4" \
    JDBC_MSSQL_VERSION="7.4.1.jre11"

ENV KEYCLOAK_DIST="https://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.tar.gz"

RUN mkdir -p /opt/jboss && \
    curl -sL "https://github.com/keycloak/keycloak-containers/archive/${KEYCLOAK_VERSION}.tar.gz" | \
    tar xz -C /opt/jboss --strip-components=2 "keycloak-containers-${KEYCLOAK_VERSION}/server/tools"

RUN /opt/jboss/tools/build-keycloak.sh

# Target stage
FROM homelabs/base:java11
COPY --from=builder /opt /opt
COPY /rootfs/ /

RUN groupadd -g 1000 jboss && \
    useradd -M -d /opt/jboss -u 1000 -g 1000 -s /sbin/nologin jboss && \
    chown -R jboss:jboss /opt/jboss

ENV LAUNCH_JBOSS_IN_BACKGROUND="1" \
    PROXY_ADDRESS_FORWARDING="false" \
    JBOSS_HOME="/opt/jboss/keycloak" \
    LANG="en_US.UTF-8"

EXPOSE 8080 8443
