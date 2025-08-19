docker run --rm \
    -u $(id -u):$(id -g) \
    -v "$PWD":/work \
    -w /work \
    --entrypoint bash \
    ghcr.io/foundry-rs/foundry:latest \
    -lc 'forge fmt $(git ls-files "*.sol")'