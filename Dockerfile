FROM alpine:latest

RUN apk update && apk upgrade && apk add curl wget bash ca-certificates  && rm -rf /var/cache/apk/*

RUN apk update && apk add go go-tools git && \
  mkdir /git && cd /git && git clone https://github.com/elastic/logstash-forwarder.git && \
  cd /git/logstash-forwarder && go build -o logstash-forwarder && cp logstash-forwarder /usr/local/bin && \
  cd / && rm -rf /git && apk del go go-tools git &&  rm -rf /var/cache/apk/* && ls -l /usr/local/bin/logstash-forwarder

COPY runfluentd /usr/local/bin/runfluentd
ENV FLUENTD_VERSION=0.12.14, JEMALLOC_PATH=/usr/lib/libjemalloc.so, FLUENTD_CONF="fluent.conf"

RUN apk update && apk add build-base ruby ruby-dev jemalloc-dev && \
  echo 'gem: --no-document' >> /etc/gemrc && \
  gem update --system && \
  gem install fluentd -v $FLUENTD_VERSION && \
  fluentd --setup /etc/fluent && \
  mkdir /var/run/fluentd && \
  chmod 755 /usr/local/bin/runfluentd && \
  ulimit -n 65536 && \
  apk del build-base geoip-dev && \
  rm -rf /var/cache/apk/*
    
EXPOSE 24224

# for log storage (maybe shared with host)
RUN mkdir -p /fluentd/log
# configuration/plugins path (default: copied from .)
RUN mkdir -p /fluentd/etc
RUN mkdir -p /fluentd/plugins
COPY fluent.conf /fluentd/etc/fluent.conf

VOLUME ["/fluentd"]
ONBUILD COPY fluent.conf /fluentd/etc/
ONBUILD COPY plugins/ /fluentd/plugins/

CMD ["/usr/local/bin/runfluentd","start"]
