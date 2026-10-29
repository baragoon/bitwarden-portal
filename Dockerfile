# Use a Node.js base image
FROM node:26.13.0-alpine3.24

ENV TZ="Europe/Berlin"
RUN apk --no-cache add tzdata

# Set working directory
WORKDIR /app

# Install required packages
RUN apk --no-cache add python3 curl bash ca-certificates openssl ncurses coreutils make gcc g++ libgcc linux-headers grep util-linux binutils findutils uuidgen wget unzip tar openssl jq bash

# Install Bitwarden CLI
COPY package.json package-lock.json ./
RUN npm ci --omit=dev \
    && ln -s /app/node_modules/.bin/bw /usr/local/bin/bw \
    && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx

# Define a default cron schedule
ENV CRON_SCHEDULE="0 0 * * *"

# Create a cron job file with the defined schedule
RUN echo "$CRON_SCHEDULE root /app/backup.sh > /var/log/cron.log 2>&1" > /etc/crontabs/root

# Copy your script and encryption files to the container
COPY ./bitwarden-portal.sh /app/backup.sh

# Copy custom SSL certificates
COPY ./certs/* /usr/local/share/ca-certificates/
COPY ./certs/* /usr/share/ca-certificates/

# Update SSL certificates
RUN update-ca-certificates

# Make your script executable
RUN chmod +x /app/backup.sh

# Start cron and log output to console
CMD ["sh", "-c", "echo \"$CRON_SCHEDULE /app/backup.sh > /proc/1/fd/1 2>&1\" > /etc/crontabs/root && crond -f -L /dev/stdout"]