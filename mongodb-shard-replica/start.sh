/entrypoint.sh mongod --replSet "${MONGO_REPLICASET_NAME}" &
pid=$!
sleep 20s
CONTAINER_IP=`curl http://rancher-metadata/latest/self/container/primary_ip`
SERVICE_NAME=`curl http://rancher-metadata/latest/self/service/name`
STACK_NAME=`curl http://rancher-metadata/latest/self/service/stack_name`
SERVICE_FQDN="${SERVICE_NAME}.${STACK_NAME}"

function add_shard {
  echo adding shard $CONTAINER_IP
  IS_MASTER=`mongo --host ${CONTAINER_IP} --eval "printjson(db.isMaster())" | grep 'ismaster'`
  if echo $IS_MASTER | grep "true"; then
    mongo ${MONGOS_SERVER_HOST}:${MONGOS_SERVER_PORT}/${MONGO_DATABASE} --eval "printjson(sh.addShard('${MONGO_REPLICASET_NAME}/${CONTAINER_IP}:27017'))"
  fi
  echo shard added
}

function master_started {
  dig ${SERVICE_FQDN} +short > ips.tmp
  for IP in $(cat ips.tmp); do
		IS_MASTER=`mongo --host $IP --eval "printjson(db.isMaster())" | grep 'ismaster'`
		if echo $IS_MASTER | grep "true"; then
			return 0
		fi
	done
	return 1
}

function find_master {
  dig ${SERVICE_FQDN} +short > ips.tmp
  for IP in $(cat ips.tmp); do
		IS_MASTER=`mongo --host $IP --eval "printjson(db.isMaster())" | grep 'ismaster'`
		if echo $IS_MASTER | grep "true"; then
			IP_MASTER=$IP
		fi
	done
}

function init_replica_set {
  echo "init replica set"
  sleep 10s
  mongo --eval "printjson(rs.initiate({_id:'${MONGO_REPLICASET_NAME}', members:[{_id:0, host:'${CONTAINER_IP}:27017'}]}))"
  #mongo --eval "printjson(rs.add('${CONTAINER_IP}:27017'))"
  sleep 20s
  echo "fin init replica set"
}

function add_in_replica_set {
  ADDED=0
  while [ ${ADDED} -eq 0 ]; do
    master_started
    if [ $? -eq 0 ]; then
      find_master
      echo "add to ${IP_MASTER}"
      mongo --host ${IP_MASTER} --eval "printjson(rs.add('${CONTAINER_IP}:27017'))"
      ADDED=1
    else
      sleep 10s
    fi
  done
}

CREATE_INDEX=`curl http://rancher-metadata/latest/self/container/create_index`
if [[ "${CREATE_INDEX}" == "1" ]]; then
  init_replica_set
  add_shard
else
  add_in_replica_set
fi


wait $pid
