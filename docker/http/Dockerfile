FROM alpine:3.12

RUN apk add mini_httpd openrc --no-cache --upgrade
EXPOSE 80
RUN mkdir /www
RUN chown minihttpd /www
ADD scripts/http/mini_httpd.conf /etc/mini_httpd/mini_httpd.conf.orig
ADD scripts/http/index.html /www/
# "rc-service mini_httpd start"
#"mini_httpd", "-C", "/etc/mini_httpd/mini_httpd.conf.orig"
