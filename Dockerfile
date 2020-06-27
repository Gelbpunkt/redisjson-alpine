FROM alpine:edge as builder

ENV LIBDIR /usr/lib/redis/modules

# Set up a build environment
RUN apk add --no-cache --virtual .fetch curl && \
    curl -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly -y && \
    apk del .fetch && \
    apk add gcc clang clang-dev llvm10 llvm10-dev musl-dev cmake make g++

# Build the source

RUN apk add --no-cache --virtual .fetch git && \
    git clone https://github.com/RedisJSON/RedisJSON && \
    apk del .fetch

ENV RUSTFLAGS "-C target-feature=-crt-static"
ENV cc "clang"

RUN source $HOME/.cargo/env && \
    cd RedisJSON && \
    cargo build --release && \
    mv target/release/librejson.so target/release/rejson.so

# Package the runner
FROM redis:alpine

ENV LIBDIR /usr/lib/redis/modules

WORKDIR /data

RUN set -ex;\
    mkdir -p "$LIBDIR";

COPY --from=builder /RedisJSON/target/release/rejson.so "$LIBDIR"

RUN apk add --no-cache libgcc

CMD ["redis-server", "--loadmodule", "/usr/lib/redis/modules/rejson.so"]

