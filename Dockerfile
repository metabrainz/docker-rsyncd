FROM metabrainz/base-image:resolute-1.0.22-v0.1
MAINTAINER Laurent Monin <zas@metabrainz.org>

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends rsync && \
  apt-get clean autoclean && \
  apt-get autoremove -y && \
  rm -rf /var/lib/{apt,dpkg,cache,log}/ && \
  mkdir /etc/service/rsyncd

ADD ./rsyncd.sh /etc/service/rsyncd/run

EXPOSE 873
VOLUME /data
