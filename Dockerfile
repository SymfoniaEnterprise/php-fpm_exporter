# Stage 1: Build
FROM golang:1.26.5-alpine AS builder

RUN apk add --no-cache git

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /php-fpm_exporter .

# Stage 2: Runtime
FROM alpine:3.22.1

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

COPY --from=builder /php-fpm_exporter /

RUN addgroup -S exporter && adduser -S -G exporter exporter
USER exporter

EXPOSE     9253
ENTRYPOINT [ "/php-fpm_exporter", "server" ]

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="php-fpm_exporter" \
      org.label-schema.description="A prometheus exporter for PHP-FPM." \
      org.label-schema.url="https://hipages.com.au/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/hipages/php-fpm_exporter" \
      org.label-schema.vendor="hipages" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0" \
      org.label-schema.docker.cmd="docker run -it --rm -e PHP_FPM_SCRAPE_URI=\"tcp://127.0.0.1:9000/status\" hipages/php-fpm_exporter"
