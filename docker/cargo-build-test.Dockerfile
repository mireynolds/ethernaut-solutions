FROM rust:1.93.0-slim-bookworm

# Create non root user
RUN useradd -m -u 1000 rustacean

# Create workdir and set permissions
WORKDIR /app
RUN mkdir -p /app && chown -R rustacean:rustacean /app

# Switch user
USER rustacean

# Arg to pick integration to run
ARG TEST

# Copy addresses
COPY /logs/addresses.log /app/addresses.log

# Copy your integration test into tests/
RUN mkdir -p tests
COPY ${TEST}/Cargo.toml ./
COPY ${TEST}/${TEST}.rs tests/${TEST}.rs

# Run the test during build
# --nocapture ensures println! output is visible
RUN cargo test -- --nocapture
