FROM ubuntu:latest AS builder
WORKDIR /root

RUN apt-get update
RUN apt-get install -y dos2unix

COPY Server/run.sh run.sh
RUN dos2unix run.sh

ARG DDCLIENT_CONF
RUN echo "$DDCLIENT_CONF" > /etc/ddclient.conf

FROM ubuntu:latest
WORKDIR /root

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -yq ddclient curl

COPY build/StandaloneLinux64 Merc/
COPY --from=builder /root/run.sh run.sh
COPY --from=builder /etc/ddclient.conf /etc/ddclient.conf
RUN chmod 0700 /etc/ddclient.conf

EXPOSE 7777
EXPOSE 7778

CMD [ "./run.sh" ]
