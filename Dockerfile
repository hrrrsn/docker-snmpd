# Use Red Hat UBI 9 minimal as the base image
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

MAINTAINER Troy Kelly <troy.kelly@really.ai>

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Docker image to provide the net-snmp daemon" \
      org.label-schema.description="Provides snmpd for CoreOS and other small footprint environments without package managers" \
      org.label-schema.url="https://github.com/hrrrrsn/docker-snmpd" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/hrrrrsn/docker-snmpd" \
      org.label-schema.vendor="Really Really, Inc." \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

EXPOSE 161 161/udp

# Install necessary packages
# Note: UBI minimal does not have a full set of packages available in its default repo
RUN microdnf install -y findutils sed tar gzip gcc make file && \
    mkdir -p /etc/snmp && \
    curl -L "https://sourceforge.net/projects/net-snmp/files/net-snmp/5.9.4/net-snmp-5.9.4.tar.gz/download" -o net-snmp.tgz && \
    tar zxvf net-snmp.tgz && \
    cd net-snmp-* && \
    find . -type f -print0 | xargs -0 sed -i 's/\"\/proc/\"\/host_proc/g' && \
    ./configure --prefix=/usr/local --disable-ipv6 --disable-snmpv1 --with-defaults && \
    make && \
    make install && \
    cd .. && \
    rm -Rf ./net-snmp* && \
    microdnf remove -y findutils tar gcc make && \
    microdnf clean all && \
    curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro && \
    chmod +x /usr/bin/distro

# Copy the snmpd configuration file
COPY snmpd.conf /etc/snmp

# Command to run snmpd
CMD [ "/usr/local/sbin/snmpd", "-f", "-c", "/etc/snmp/snmpd.conf" ]