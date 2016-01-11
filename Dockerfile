FROM alpine:latest

RUN apk update && apk upgrade && apk add curl wget bash ca-certificates  && rm -rf /var/cache/apk/*

COPY runfluentd /usr/local/bin/runfluentd
ENV FLUENTD_VERSION=0.12.19, JEMALLOC_PATH=/usr/lib/libjemalloc.so, FLUENTD_CONF="fluent.conf"

RUN apk update && apk add build-base ruby ruby-dev jemalloc-dev geoip geoip-dev geoip-doc  && \
  echo 'gem: --no-document' >> /etc/gemrc && \
  gem update --system && \
  gem install fluentd -v $FLUENTD_VERSION && \
  # Native build plugins
  fluent-gem install fluent-plugin-graphite && \
  fluent-gem install fluent-plugin-geoip && \
  #
  fluentd --setup /etc/fluent && \
  mkdir /var/run/fluentd && \
  chmod 755 /usr/local/bin/runfluentd && \
  ulimit -n 65536 && \
  apk del build-base geoip-dev && \
  rm -rf /var/cache/apk/*

RUN fluent-gem install fluent-plugin-elasticsearch && \
  fluent-gem install fluent-plugin-record-reformer && \
  fluent-gem install fluent-plugin-docker-format && \
  fluent-gem install fluent-plugin-grok_pure-parser && \
  fluent-gem install fluent-plugin-secure-forward && \ 
  fluent-gem install fluent-plugin-extract_query_params && \
  fluent-gem install fluent-plugin-grep && \
  fluent-gem install fluent-plugin-anonymizer && \
  fluent-gem install fluent-plugin-add && \
  fluent-gem install fluent-plugin-burrow && \
  fluent-gem install fluent-plugin-conditional_filter && \
  fluent-gem install fluent-plugin-docker_metadata_filter
    
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
