FROM alpine:3.12 as hugo
# Docker to use hugo
LABEL maintainer="Sergio Talens-Oliag <sto@mixinet.net>"
# Environment variables
ENV GITHUB_REPO="gohugoio/hugo"
ENV LATEST_URL="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
ENV REGEX="hugo_[0-9].*_Linux-64bit.tar.gz"
ENV JQ_FILTER=".assets[]|select(.name|test(\"$REGEX\")).browser_download_url"
# Download & install hugo binary
RUN apk update \
    && apk add --no-cache curl jq \
    && cd /tmp \
    && DOWNLOAD_URL="$(curl -s "$LATEST_URL" | jq -r "$JQ_FILTER")" \
    && curl -sL "${DOWNLOAD_URL}" > /tmp/hugo.tgz \
    && cd /usr/bin \
    && tar xvzf /tmp/hugo.tgz hugo \
    && rm -f /tmp/hugo.tgz \
    && apk del curl jq \
    && rm -rf /var/cache/apk/*
# Adjust working directory
WORKDIR /workdir/site
# Expose hugo default port
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

FROM nginx:1.19.3-alpine as nginx-hugo
COPY --from=compiled /workdir/gohugo-theme-ananke/exampleSite/public/. \
                     /usr/share/nginx/html
