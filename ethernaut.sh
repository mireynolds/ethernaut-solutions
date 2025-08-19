docker build -f Ethernaut.dockerfile \
  --network host \
  --add-host=host.docker.internal:host-gateway \
  -t ethernaut .