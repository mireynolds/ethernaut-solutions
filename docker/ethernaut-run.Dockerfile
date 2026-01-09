# Based on Node.js 20 and Debian Bookworm
FROM node:20-bookworm

WORKDIR /app

# Enable Yarn
RUN corepack enable && corepack prepare yarn@stable --activate

# Clone Ethernaut source
RUN git clone https://github.com/OpenZeppelin/ethernaut.git ./

# Install dependencies
RUN yarn install

# Download foundry installer `foundryup`
RUN apt-get update && apt-get install -y curl
RUN curl -L https://foundry.paradigm.xyz | bash 

# add Foundry to PATH for all subsequent layers then install foundry
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

# Compile Foundry contracts
RUN yarn compile:contracts

# Set ACTIVE_NETWORK to NETWORKS.LOCAL
RUN sed -i '/let id_to_network = {}/i export const ACTIVE_NETWORK = NETWORKS.LOCAL;' client/src/constants.js

# Expose UI
EXPOSE 3000

# Expose Anvil
EXPOSE 8545

# Set NODE_OPTIONS to use legacy OpenSSL provider
ENV NODE_OPTIONS="--openssl-legacy-provider"

# Start RPC, deploy contracts, then run the UI
CMD ["/bin/bash", \
    "-c", \
    "set -e; \
    ANVIL_IP_ADDR=0.0.0.0 yarn network & \
    yes | CI=true yarn deploy:contracts && \
    exec yarn start:ethernaut" \
]