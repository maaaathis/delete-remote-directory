FROM alpine:latest

RUN apk add --no-cache git git-lfs

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]