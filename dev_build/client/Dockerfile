ARG OS_VERSION=7

FROM centos:${OS_VERSION}

COPY root.tar.gz /root.tar.gz
RUN /bin/tar xvzf /root.tar.gz && /setup.sh
ENTRYPOINT /usr/local/bin/runsvdir -P /etc/service
