# Based on Node.js 20 and Debian Bookworm
FROM node:20-bookworm

WORKDIR /app

# Clone Ethernaut source
RUN git clone --progress https://github.com/OpenZeppelin/ethernaut.git ./ && git checkout d05643a40aa98c45d66247c69ffceab8f44dd8cb

# Add Foundry to PATH for all subsequent layers then install foundry
ENV PATH="/root/.foundry/bin:${PATH}"

# Download foundry installer `foundryup`
RUN apt-get update && apt-get install -y curl && curl -L https://foundry.paradigm.xyz | bash && foundryup --install v1.6.0-rc1

# Enable yarn, install, and compile contracts
RUN corepack enable && corepack prepare yarn@stable --activate && yarn install && yarn compile:contracts

# Set ACTIVE_NETWORK to NETWORKS.LOCAL
RUN sed -i '/let id_to_network = {}/i export const ACTIVE_NETWORK = NETWORKS.LOCAL;' client/src/constants.js

# Expose UI
EXPOSE 3000

# Expose Anvil
EXPOSE 8545

# Set NODE_OPTIONS to use legacy OpenSSL provider
ENV NODE_OPTIONS="--openssl-legacy-provider"

# Start RPC. Contract deployment and starting the UI done in further commands.
CMD ["/bin/bash", \
    "-c", \
    "set -euo pipefail; \
    trap 'kill 0' INT TERM; \
    cd contracts; \
    anvil \
    --host ${ANVIL_IP_ADDR:-127.0.0.1} \
    --port ${ANVIL_PORT:-8545} \
    --block-time 1 \
    --auto-impersonate \
    --state ${ANVIL_STATE_PATH:-/data/anvil-state.json} \
    --state-interval ${ANVIL_STATE_INTERVAL:-5}" \
]