docker run --rm \
    -u $(id -u):$(id -g) \
    -v "$PWD":/work \
    -w /work \
    --entrypoint bash \
    ghcr.io/foundry-rs/foundry:latest \
    -lc 'git ls-files -z -- "*.sol" | xargs -0 -r forge fmt'