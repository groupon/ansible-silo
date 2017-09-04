FROM ubuntu:16.04

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y python && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 80

CMD ["/sbin/init"]
