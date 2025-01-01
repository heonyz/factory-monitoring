#!/bin/sh

# Kafka Connect 준비 확인
echo "Waiting for Kafka Connect to be ready..."
while ! curl -sS http://kafka-connect:8083/connectors; do 
  echo "Kafka Connect not ready yet, retrying in 5 seconds..."
  sleep 5
done

# 커넥터 엔드포인트 확인
CONNECTOR_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://kafka-connect:8083/connectors)
while [ $CONNECTOR_CHECK -ne 200 ]; do
  echo "Connectors endpoint not available, retrying in 5 seconds..."
  sleep 5
  CONNECTOR_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://kafka-connect:8083/connectors)
done

echo "Kafka Connect is ready. Proceeding with connector registration."

# 커넥터 이름
CONNECTOR_NAME="mysql-connector"

# 커넥터 설정 JSON
CONNECTOR_CONFIG=$(cat <<EOF
{
  "name": "$CONNECTOR_NAME",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",
    "database.hostname": "mysql",
    "database.port": "3306",
    "database.user": "debezium",
    "database.password": "dbz",
    "database.server.id": "184054",
    "database.server.name": "cdc",
    "database.history.kafka.bootstrap.servers": "kafka:9092",
    "database.history.kafka.topic": "dbhistory.fullfillment",
    "database.allowPublicKeyRetrieval": "true",
    "include.schema.changes": "true",
    "table.include.list": "surface_inspection.users,surface_inspection.devices,surface_inspection.defects",
    "transforms": "unwrap",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "false",
    "transforms.unwrap.delete.handling.mode": "rewrite",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "false",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "snapshot.mode": "initial",
    "topic.prefix": "cdc"
  }
}
EOF
)

# 기존 커넥터 확인 및 등록 또는 업데이트
EXISTING_CONNECTOR=$(curl -s -o /dev/null -w "%{http_code}" -X GET http://kafka-connect:8083/connectors/$CONNECTOR_NAME)

if [ $EXISTING_CONNECTOR -eq 200 ]; then
  echo "Connector $CONNECTOR_NAME already exists. Updating..."
  curl -X PUT http://kafka-connect:8083/connectors/$CONNECTOR_NAME/config -H "Content-Type: application/json" -d "$CONNECTOR_CONFIG"
else
  echo "Creating new connector $CONNECTOR_NAME..."
  curl -X POST http://kafka-connect:8083/connectors -H "Content-Type: application/json" -d "$CONNECTOR_CONFIG"
fi
