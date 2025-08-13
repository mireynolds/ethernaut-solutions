# Based on Node.js 20 and Debian Bullseye
FROM node:20-bullseye

WORKDIR /app
ENV NODE_OPTIONS=--max_old_space_size=4096

# Enable Yarn
RUN corepack enable && corepack prepare yarn@stable --activate

# Install Ganache CLI & jq
RUN yarn global add ganache && apt-get update && apt-get install -y jq

# Clone Ethernaut source
RUN git clone --depth 1 https://github.com/OpenZeppelin/ethernaut.git ./

# Set ACTIVE_NETWORK to NETWORKS.LOCAL
RUN sed -i 's/ACTIVE_NETWORK.*/ACTIVE_NETWORK = NETWORKS.LOCAL;/' client/src/constants.js

# Install dependencies
RUN yarn install --frozen-lockfile

# Expose UI + Ganache RPC
EXPOSE 3000 8545

# Start Ganache, deploy contracts, then run the UI
CMD ganache --host 0.0.0.0 --port 8545 --chainId 31337 --accounts 10 --defaultBalanceEther 1000 --deterministic & \
    sleep 3 && \
    yarn compile:contracts && \
    yarn deploy:contracts && \
    yarn start:ethernaut
