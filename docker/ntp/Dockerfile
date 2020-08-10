FROM centos:7

RUN yum install -y ntp nano
RUN yum update -y
EXPOSE 123:123/udp
COPY scripts/ntp/ntp.conf /etc/ntp.conf
