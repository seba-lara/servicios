FROM alpine:3.12

RUN apk add dhcp bash  --no-cache --upgrade
EXPOSE 67/udp 67/tcp
ADD scripts/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf
RUN ["touch", "/var/lib/dhcp/dhcpd.leases"]
