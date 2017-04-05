########################################################
# Dockerfile per l'applicazione sentence / word service 
########################################################

FROM frolvlad/alpine-oraclejdk8 

########################################################
# BEGIN - Install gradle
########################################################
RUN apk update && \
	apk add ca-certificates && \
	update-ca-certificates && \
	apk add openssl
RUN mkdir /usr/lib/gradle /app

ENV GRADLE_VERSION 2.13
ENV GRADLE_HOME /usr/lib/gradle/gradle-${GRADLE_VERSION}
ENV PATH ${PATH}:${GRADLE_HOME}/bin

WORKDIR /usr/lib/gradle
RUN set -x \
  && apk add --no-cache wget \
  && wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
  && unzip gradle-${GRADLE_VERSION}-bin.zip \
  && rm gradle-${GRADLE_VERSION}-bin.zip \
  && apk del wget

RUN apk update && apk add bash libstdc++ && rm -rf /var/cache/apk/*
########################################################
# END - Install gradle
########################################################

ADD app /opt/app 
WORKDIR /opt/app
RUN gradle build

EXPOSE 8080

ENTRYPOINT ["/usr/bin/java", "-Xmx128m", "-Xms128m"]

CMD ["-jar", "build/libs/word-0.0.1-SNAPSHOT.jar"]

#CMD ["-jar", "-Dspring.profiles.active=subject", "word.jar"]
#CMD ["-jar", "-Dspring.profiles.active=verb", "word.jar"]
#CMD ["-jar", "-Dspring.profiles.active=object", "word.jar"]

