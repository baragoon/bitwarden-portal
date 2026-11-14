# syntax = docker/dockerfile:1.29.0@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

FROM node:26.13.1-alpine3.24@sha256:6bd9ab43c0ec0190ca7b2d193906cb8b7edf6e7f4afa43ddeccd6452710bffb5
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
