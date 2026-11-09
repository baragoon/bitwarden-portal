# syntax = docker/dockerfile:1.28.0@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

FROM node:26.13.0-alpine3.24@sha256:8996bb5821d62a8fd9bb27c1cb07462f3fdce6e47d640c6a881ead0b064ce216
ENV TZ="Europe/Berlin"
RUN apk --no-cache add tzdata
WORKDIR /app
RUN apk --no-cache add python3 curl bash ca-certificates openssl ncurses coreutils make gcc g++ libgcc linux-headers grep util-linux binutils findutils uuidgen wget unzip tar openssl jq bash
COPY package.json package-lock.json ./
RUN npm ci --omit=dev \
    && ln -s /app/node_modules/.bin/bw /usr/local/bin/bw \
    && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx
ENV CRON_SCHEDULE="0 0 * * *"
RUN echo "$CRON_SCHEDULE root /app/backup.sh > /var/log/cron.log 2>&1" > /etc/crontabs/root
COPY ./bitwarden-portal.sh /app/backup.sh
COPY ./certs/* /usr/local/share/ca-certificates/
COPY ./certs/* /usr/share/ca-certificates/
RUN update-ca-certificates
RUN chmod +x /app/backup.sh
CMD ["sh", "-c", "echo \"$CRON_SCHEDULE /app/backup.sh > /proc/1/fd/1 2>&1\" > /etc/crontabs/root && crond -f -L /dev/stdout"]
