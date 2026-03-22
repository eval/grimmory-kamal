# Wrapper Dockerfile for Kamal deployment
# Pulls the official BookLore image and allows Kamal to add required labels
ARG VERSION=latest
FROM ghcr.io/grimmory-tools/grimmory:${VERSION}
ARG VERSION
ARG KAMAL_REGISTRY_USERNAME
ENV BOOKLORE_VERSION=${VERSION}
LABEL org.opencontainers.image.source=https://github.com/${KAMAL_REGISTRY_USERNAME}/booklore-kamal
