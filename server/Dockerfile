ARG GO_VERSION=1.21.5
FROM golang:${GO_VERSION}-bookworm as builder

WORKDIR /usr/src/app
COPY go.mod go.sum ./
RUN go mod download && go mod verify
COPY . .
RUN go build -v -o /run-app .


FROM debian:bookworm

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y ca-certificates chromium chromium-sandbox && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy the config file and binary to the bin
COPY --from=builder /usr/src/app/temporal-global-citizen-db0309516509.json /usr/local/bin/
COPY --from=builder /run-app /usr/local/bin/

CMD ["run-app"]
