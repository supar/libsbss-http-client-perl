FROM debian:latest
MAINTAINER  Paul Rezunenko "supar@gmail.com"

# Get rid of the debconf messages
ENV DEBIAN_FRONTEND noninteractive

# Update packages and install the ones that are needed
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y  --no-install-recommends ca-certificates \
                        curl unzip locales \
			libmoose-perl libjson-perl libdigest-perl \
			libhttp-request-params-perl libtest-lwp-useragent-perl \
			libmoosex-types-perl libmoosex-types-structured-perl \
                        vim \
                        && rm -rf /var/lib/apt/lists/*

RUN echo "Europe/Moscow" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
ENV LANG C.UTF-8

EXPOSE 80

ENTRYPOINT [ "/bin/bash" ]

