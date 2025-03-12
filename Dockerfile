# -----------------------------------------------------------------------------
# Stage 1: Rust Builder
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS builder

# Install necessary build dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    pkg-config \
    libssl-dev

# Configure environment variables.
ENV CARGO_HOME=/root/.cargo
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.cargo/bin:${PATH}"
ENV RUSTUP_HOME=/root/.rustup

# Install and configure rustup.
RUN <<EOF
set -eux
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
  sh -s -- -y --profile minimal
rustup toolchain install 1.83.0
rustup default 1.83.0
rustup component add rust-src --toolchain 1.83.0
rustup component add rust-std --toolchain 1.83.0
rustup component add rust-docs --toolchain 1.83.0
EOF

# -----------------------------------------------------------------------------
# Stage 2: Runtime Image
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS runtime

# Install openssl and ca-certificates for HTTPS requests, and python3/pip
RUN <<EOF
apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  openssl \
  python3 \
  python3-pip
rm -rf /var/lib/apt/lists/*
EOF

# Copy the Rust installation from the builder stage.
COPY --from=builder /root/.cargo /root/.cargo
COPY --from=builder /root/.rustup /root/.rustup
COPY --from=builder /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu

# Configure environment variables.
ENV RUSTUP_HOME=/root/.rustup
ENV CARGO_HOME=/root/.cargo
ENV PATH="/root/.cargo/bin:${PATH}"
ENV RUST_VERSION=1.83.0

# Create a non-root user.
RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown -R appuser:appuser /root/.cargo /root/.rustup \
  && chmod -R u+rwx /root/.cargo /root/.rustup

# --- Cargo Smoke Test ---
WORKDIR /app
USER appuser
COPY --chown=appuser:appuser ./test_cargo /app/test_cargo
# FIXME: CARGO NOT EXECUTABLE
RUN cd test_cargo && cargo build --release && ./target/release/hello-world

# --- Maturin Smoke Test ---
USER root
RUN pip install --no-cache-dir maturin

WORKDIR /app
USER appuser
COPY --chown=appuser:appuser ./test_maturin /app/test_maturin

RUN maturin build --release -m /app/test_maturin/Cargo.toml
RUN test -f "$(find /app/test_maturin/target/wheels -name '*.whl' -print -quit)"

# --- Runtime configuration ---
USER appuser
WORKDIR /app
CMD ["/app/test_cargo/target/release/hello-world"]