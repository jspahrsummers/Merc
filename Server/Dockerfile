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
RUN apt-get install -yq ddclient

COPY build/StandaloneLinux64 Merc/
COPY --from=builder /root/run.sh run.sh
COPY --from=builder /etc/ddclient.conf /etc/ddclient.conf
RUN chmod 0700 /etc/ddclient.conf

ENV GAME_PORT 7778
EXPOSE $GAME_PORT

CMD [ "./run.sh" ]
