# Classic postgres image extended with pg_duckdb built from source
# Based on https://github.com/duckdb/pg_duckdb/blob/main/Dockerfile
ARG POSTGRES_VERSION=17

###
### BUILDER
###
FROM postgres:${POSTGRES_VERSION}-bookworm AS builder
ARG POSTGRES_VERSION
ARG PG_DUCKDB_VERSION=main

RUN apt-get update -qq && \
    apt-get install -y \
    postgresql-server-dev-${POSTGRES_VERSION} \
    build-essential libreadline-dev zlib1g-dev flex bison libxml2-dev libxslt-dev \
    libssl-dev libxml2-utils xsltproc pkg-config libc++-dev libc++abi-dev libglib2.0-dev \
    libtinfo5 cmake libstdc++-12-dev liblz4-dev ccache ninja-build git libcurl4-openssl-dev && \
    rm -rf /var/lib/apt/lists/*

ENV PATH=/usr/lib/ccache:$PATH
ENV CCACHE_DIR=/ccache

# Clone with duckdb submodule (Makefile requires .git/modules/third_party/duckdb/HEAD)
RUN git clone --depth 1 --branch ${PG_DUCKDB_VERSION} --recurse-submodules --shallow-submodules \
    https://github.com/duckdb/pg_duckdb.git /build
WORKDIR /build

# build & install into /out for packaging
RUN --mount=type=cache,target=/ccache/ echo "Available CPUs=$(nproc)" && make -j$(nproc)
RUN DESTDIR=/out make install

###
### OUTPUT
###
FROM postgres:${POSTGRES_VERSION}-bookworm

RUN apt-get update -qq && \
    apt-get install -y ca-certificates libcurl4 && \
    rm -rf /var/lib/apt/lists/*

# Automatically enable pg_duckdb
RUN echo "shared_preload_libraries='pg_duckdb'" >> /usr/share/postgresql/postgresql.conf.sample

COPY --from=builder /out /
