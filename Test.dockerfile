# Use the latest foundry image
FROM ghcr.io/foundry-rs/foundry
 
# Copy our source code into the container
WORKDIR /app

# Find foundry files
# [submodule "lib/forge-std"]
#	path = lib/forge-std
#	url = https://github.com/foundry-rs/forge-std
#	branch = master
# RUN git submodule add --name "lib/forge-std" --path "lib/forge-std" --url "https://github.com/foundry-rs/forge-std" --branch "master"

# Init Foundry Project
RUN forge init ./

# Build test project to install dependencies earlier
RUN forge build --use solc:0.8.30

# Load the local RPC URL from build command
ARG RPC_URL=http://host.docker.internal:8545

# Allow reading local files in container
RUN echo 'fs_permissions = [{ access = "read", path = "./"}]' >> foundry.toml

# Build and test the source code
COPY test/ /app/test/
COPY addresses.log /app/addresses.log
RUN forge build
RUN forge test -vvvvv --fork-url "$RPC_URL" --suppress-successful-traces

# Make the image convenient for interactive use (debugger)
ENTRYPOINT ["/bin/bash","-lc"]