FROM mongo:3.2

ENV MONGOS_SERVER_HOST ''
ENV MONGOS_SERVER_PORT ''
ENV MONGO_DATABASE ''

RUN apt-get update && apt-get install -y curl

ADD start.sh /usr/local/bin/start.sh
ADD mongo-shard.js /usr/share/mongo-shard.js

EXPOSE 27017
CMD /bin/bash /usr/local/bin/start.sh
