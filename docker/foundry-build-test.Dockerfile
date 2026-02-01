# Use the latest foundry image
FROM ghcr.io/foundry-rs/foundry:v1.6.0-rc1

# Make sure user is foundry
USER foundry
 
# Copy our source code into the container
WORKDIR /app

# Init Foundry Project
RUN forge init ./

# Build test project to install dependencies earlier
RUN forge build --use solc:0.8.30

# Load the local RPC URL from build command
ARG RPC_URL=http://host.docker.internal:8545

# Allow reading local files in container
RUN echo 'fs_permissions = [{ access = "read", path = "./"},{ access = "read", path = "/app" }]' >> foundry.toml

# Build and test the source code
COPY test/ /app/test/
COPY logs/addresses.log /app/addresses.log
COPY logs/level_40.log /app/level_40.log
RUN forge build
RUN forge test -vvvvv --fork-url "$RPC_URL" --suppress-successful-traces

# Make the image convenient for interactive use (debugger)
ENTRYPOINT ["/bin/bash","-c"]