FROM rust:latest

WORKDIR /app

# Arg to pick integration to run
ARG TEST_FILE

# Copy toml
COPY Cargo.toml ./

# Copy your integration test into tests/
RUN mkdir -p tests
COPY ${TEST_FILE} tests/${TEST_FILE}

# Run the test during build
# --nocapture ensures println! output is visible
RUN cargo test -- --nocapture
