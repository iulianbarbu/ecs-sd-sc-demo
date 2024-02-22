#syntax=docker/dockerfile-upstream:1.4


# Base image for builds and cache
FROM --platform=linux/amd64 docker.io/lukemathwalker/cargo-chef:latest-rust-1.76-bookworm as cargo-chef
WORKDIR /build

# Stores source cache and cargo chef recipe
FROM cargo-chef as chef-planner
WORKDIR /src
COPY . .

RUN find . \( \
    -name "*.rs" -or \
    -name "*.toml" -or \
    -name "Cargo.lock" -or \
    -name "*.sql" -or \
    -name "README.md" -or \
    # Used for local TLS testing, as described in admin/README.md
    -name "*.pem" \
    \) -type f -exec install -D \{\} /build/\{\} \;

WORKDIR /build
RUN cargo chef prepare --recipe-path /recipe.json
# Builds crate according to cargo chef recipe.
# This step is skipped if the recipe is unchanged from previous build (no dependencies changed).
FROM cargo-chef AS chef-builder
ARG CARGO_PROFILE
COPY --from=chef-planner /recipe.json /
# https://i.imgflip.com/2/74bvex.jpg
RUN cargo chef cook \
    --all-features \
    --recipe-path /recipe.json
COPY --from=chef-planner /build .
# Building all at once to share build artifacts in the "cook" layer
RUN cargo build

####### Helper step
FROM --platform=linux/amd64 docker.io/library/debian:bookworm-20230904-slim AS bookworm-20230904-slim-plus
RUN apt update && apt install -y curl ca-certificates; rm -rf /var/lib/apt/lists/*

#### Service
FROM bookworm-20230904-slim-plus AS ecs-sd-sc-demo
COPY --from=chef-builder /build/target/debug/ecs-sd-sc-demo /usr/local/bin
ENTRYPOINT ["/usr/local/bin/ecs-sd-sc-demo"]
