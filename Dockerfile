FROM alpine:3.9 as hugo
# Docker to use hugo
LABEL maintainer="Sergio Talens-Oliag <sto@iti.es>"
# Environment variables
ENV HUGO_VERSION 0.54.0
ENV HUGO_TARFILE hugo_${HUGO_VERSION}_Linux-64bit.tar.gz
ENV HUGO_DOWNLOAD_BASEURL https://github.com/gohugoio/hugo/releases/download
# Download & install hugo binary
RUN apk update \
    && apk add --no-cache curl \
    && cd /tmp \
    && curl -L ${HUGO_DOWNLOAD_BASEURL}/v${HUGO_VERSION}/${HUGO_TARFILE} \
        > /tmp/hugo.tgz \ 
    && cd /usr/bin \
    && tar xvzf /tmp/hugo.tgz hugo \
    && rm -f /tmp/hugo.tgz \
    && apk del curl \
    && rm -rf /var/cache/apk/*
# Adjust working directory
WORKDIR /workdir/site
# Expose gollum default port
EXPOSE 1313
# Run hugo as main process
ENTRYPOINT ["/usr/bin/hugo"]
# Default command is server
CMD ["server", "--bind", "0.0.0.0"]

FROM hugo as compiled
COPY gohugo-theme-ananke /workdir/gohugo-theme-ananke
RUN cd /workdir/gohugo-theme-ananke/exampleSite \
    && rm -rf public \
    && hugo -b /

FROM nginx:1.15.10-alpine as nginx-hugo
COPY --from=compiled /workdir/gohugo-theme-ananke/exampleSite/public/. \
                     /usr/share/nginx/html
