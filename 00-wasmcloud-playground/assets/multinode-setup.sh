curl -LO https://github.com/nats-io/nats-server/releases/download/v2.9.19/nats-server-v2.9.19-amd64.deb &
curl -LO https://github.com/nats-io/natscli/releases/download/v0.0.35/nats-0.0.35-amd64.deb &
curl -L https://raw.githubusercontent.com/nats-io/nsc/master/install.py | python

echo 'export PATH="$PATH:/root/.nsccli/bin"' >> $HOME/.bashrc
source $HOME/.bashrc
ln -s /root/.nsccli/bin/nsc /bin

wait
dpkg -i nats-server-v2.9.19-amd64.deb 
dpkg -i nats-0.0.35-amd64.deb 

export NATS_MAIN_URL="nats://0.0.0.0:4222"
export NATS_LEAF_URL="nats://0.0.0.0:4223"

nsc add operator --generate-signing-key --sys --name local
nsc edit operator --require-signing-keys \
  --account-jwt-server-url "$NATS_MAIN_URL"

nsc add account APP
nsc edit account APP --sk generate
nsc add user --account APP user
nsc add user --account APP wash

nats context save main-user \
  --server "$NATS_MAIN_URL" \
  --nsc nsc://local/APP/user 

nats context save main-sys \
  --server "$NATS_MAIN_URL" \
  --nsc nsc://local/SYS/sys

nats context save leaf-user \
  --server "$NATS_LEAF_URL"

nsc generate config --nats-resolver --sys-account SYS > resolver.conf

echo 'Creating the main server conf...'
cat <<- EOF > main.conf
port: 4222
leafnodes: {
  port: 7422
}

include resolver.conf
EOF

echo 'Creating the leaf node conf...'
cat <<- EOF > leaf.conf
port: 4223
leafnodes: {
  remotes: [
    {
      url: "nats-leaf://0.0.0.0:7422",
      credentials: "/root/.local/share/nats/nsc/keys/creds/local/APP/user.creds"
    }
  ]
}
EOF

nats-server -c main.conf 2> /dev/null &
MAIN_PID=$!

sleep 1

echo 'Pushing the account JWT...'
nsc push -a APP

nats-server -c leaf.conf 2> /dev/null &
LEAF_PID=$!