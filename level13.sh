docker run --rm \
    -it \
    --add-host host.docker.internal:host-gateway \
    --entrypoint /bin/bash ethernaut \
    -lc 'forge test --debug --match-test "testLevel13" --fork-url http://host.docker.internal:8545'