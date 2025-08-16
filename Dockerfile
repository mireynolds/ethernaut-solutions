# Based on Node.js 20 and Debian Bullseye
FROM node:20-bullseye

WORKDIR /app

# Enable Yarn
RUN corepack enable && corepack prepare yarn@1.22.22 --activate

# Install Ganache CLI & jq
# RUN yarn global add ganache

# Clone Ethernaut source
RUN git clone https://github.com/OpenZeppelin/ethernaut.git ./

# Install dependencies
RUN yarn install

# Download foundry installer `foundryup`
RUN apt-get update && apt-get install -y curl
RUN curl -L https://foundry.paradigm.xyz | bash 
# add Foundry to PATH for all subsequent layers
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

# Set ACTIVE_NETWORK to NETWORKS.LOCAL
RUN sed -i '/let id_to_network = {}/i export const ACTIVE_NETWORK = NETWORKS.LOCAL;' client/src/constants.js

# Expose UI + Anvil RPC
EXPOSE 3000 8545

# Set NODE_OPTIONS to use legacy OpenSSL provider
ENV NODE_OPTIONS="--openssl-legacy-provider"

# Compile Foundry contracts
RUN yarn compile:contracts

# Start Ganache, deploy contracts, then run the UI
CMD yarn network & \
    yes | CI=true yarn deploy:contracts && ls -l /app/client/src/gamedata && cp /app/client/src/gamedata/deploy.local.json /addresses/addresses.log && \
    yarn start:ethernaut
