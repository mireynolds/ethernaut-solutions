docker build -f Test.dockerfile \
  --network host \
  --add-host=host.docker.internal:host-gateway \
  -t ethernaut .