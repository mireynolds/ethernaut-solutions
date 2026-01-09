FROM rust:latest

WORKDIR /app

# Copy toml
COPY Cargo.toml ./

# Copy your integration test into tests/
RUN mkdir -p tests
COPY ecdsa.rs tests/ecdsa.rs

# Run the test during build
# --nocapture ensures println! output is visible
RUN cargo test -- --nocapture
