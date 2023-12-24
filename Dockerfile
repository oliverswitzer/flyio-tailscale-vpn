FROM alpine:latest as builder
WORKDIR /app
COPY . ./
# This is where one could build the application code as well.


# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
FROM alpine:latest
# alpine:3.19 links iptables to iptables-nft https://gitlab.alpinelinux.org/alpine/aports/-/commit/f87a191922955bcf5c5f3fc66a425263a4588d48.
# iptables-nft requires kernel support for nft, which is currently not available in Fly.io,
# so we remove the links and ensure that the iptables-legacy version is used.
RUN apk update && apk add ca-certificates iptables iptables-legacy ip6tables  \
  && rm -rf /var/cache/apk/* \
  && rm /sbin/iptables && ln -s /sbin/iptables-legacy /sbin/iptables  \
  && rm /sbin/ip6tables && ln -s /sbin/ip6tables-legacy /sbin/ip6tables

# Copy binary to production image.
COPY --from=builder /app/start.sh /app/start.sh

# Copy Tailscale binaries from the tailscale image on Docker Hub.
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /app/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /app/tailscale
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

# Run on container startup.
CMD ["/app/start.sh"]
