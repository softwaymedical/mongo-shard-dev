/entrypoint.sh mongod &
pid=$!
sleep 20s
CONTAINER_IP=`curl http://rancher-metadata/latest/self/container/primary_ip`
echo adding shard $CONTAINER_IP
mongo ${MONGOS_SERVER_HOST}:${MONGOS_SERVER_PORT}/${MONGO_DATABASE} --eval 'var containerIp = "'${CONTAINER_IP}'"' /usr/share/mongo-shard.js
echo shard added
wait $pid
