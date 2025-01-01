#!/bin/bash
echo "Waiting for KSQLDB to start..."

# Wait for KSQLDB to be ready
while ! curl -s http://ksqldb-server:8088/info; do
    echo "Waiting for ksqlDB to be available..."
    sleep 5
done

echo "KSQLDB is up and running! Executing ksql-init.sql..."

# Execute the SQL file
while IFS= read -r line
do
  echo "$line"
  curl -X POST http://ksqldb-server:8088/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -d "{\"ksql\": \"$line\", \"streamsProperties\": {}}"
done < "/docker-entrypoint-initdb.d/ksql-init.sql"

