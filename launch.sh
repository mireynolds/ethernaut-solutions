docker run --rm \
    -it \
    -p 3000:3000 \
    -p 8545:8545 \
    -v "$PWD":/addresses $(docker build -f LaunchEthernaut.dockerfile -q .)