docker build -f TestEthernaut.dockerfile \
  --network host \
  --add-host=host.docker.internal:host-gateway \
  -t ethernaut .