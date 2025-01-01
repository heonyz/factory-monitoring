-- Users Stream 생성
CREATE STREAM users_stream (
  id INT,
  name STRING,
  email STRING,
  username STRING,
  password STRING,
  address STRING,
  phone STRING,
  created_at STRING
) WITH (
  KAFKA_TOPIC='cdc.surface_inspection.users',
  VALUE_FORMAT='JSON'
);

-- Users Table 생성
-- CREATE TABLE users_table AS
-- SELECT id,
--        name,
--        email,
--        username,
--        password,
--        address,
--        phone,
--        created_at
-- FROM users_stream
-- GROUP BY id;
CREATE TABLE users_table WITH (KAFKA_TOPIC='USERS_TABLE', PARTITIONS=1, REPLICAS=1) AS 
SELECT
  id,
  latest_by_offset(name) AS name,
  latest_by_offset(email) AS email,
  latest_by_offset(username) AS username,
  latest_by_offset(password) AS password,
  latest_by_offset(address) AS address,
  latest_by_offset(phone) AS phone,
  latest_by_offset(created_at) AS created_at
FROM users_stream
GROUP BY id
EMIT CHANGES;


-- Devices Stream 생성
CREATE STREAM devices_stream (
  id INT,
  user_id INT,
  devicename STRING,
  devicetype STRING,
  errorpath STRING,
  successcount INT,
  failcount INT,
  created_at STRING,
  updated_at STRING
) WITH (
  KAFKA_TOPIC='cdc.surface_inspection.devices',
  VALUE_FORMAT='JSON'
);

-- Devices Table 생성
-- CREATE TABLE devices_table AS
-- SELECT id,
--        user_id,
--        devicename,
--        devicetype,
--        errorpath,
--        successcount,
--        failcount,
--        created_at,
--        updated_at
-- FROM devices_stream
-- GROUP BY id;
CREATE TABLE devices_table WITH (KAFKA_TOPIC='DEVICES_TABLE', PARTITIONS=1, REPLICAS=1) AS 
SELECT
  id,
  latest_by_offset(user_id) AS user_id,
  latest_by_offset(devicename) AS devicename,
  latest_by_offset(devicetype) AS devicetype,
  latest_by_offset(errorpath) AS errorpath,
  latest_by_offset(successcount) AS successcount,
  latest_by_offset(failcount) AS failcount,
  latest_by_offset(created_at) AS created_at,
  latest_by_offset(updated_at) AS updated_at
FROM devices_stream
GROUP BY id
EMIT CHANGES;


-- Defects Stream 생성
CREATE STREAM defects_stream (
  id INT,
  device_id INT,
  image_path STRING,
  detected_at STRING
) WITH (
  KAFKA_TOPIC='cdc.surface_inspection.defects',
  VALUE_FORMAT='JSON'
);

-- Defects Table 생성
CREATE TABLE defects_table AS
SELECT id,
       device_id,
       image_path,
       detected_at
FROM defects_stream
GROUP BY id;

-- -- Click Events와 Users, Devices, Defects를 조인하여 확장된 데이터를 생성
-- CREATE STREAM enriched_click_events AS
-- SELECT c.user_id,
--        u.name AS user_name,
--        c.device_id,
--        d.devicename AS device_name,
--        c.defect_id,
--        f.image_path AS defect_image_path,
--        c.eventType,
--        c.eventData,
--        c.timestamp
-- FROM click_events_stream c
-- LEFT JOIN users_table u
--   ON c.user_id = u.id
-- LEFT JOIN devices_table d
--   ON c.device_id = d.id
-- LEFT JOIN defects_table f
--   ON c.defect_id = f.id;







--click_events_stream과 users_table, devices_table을 조인하여 확장된 데이터를 생성하는 쿼리는 아래와 같습니다. 이 쿼리는 결함 데이터는 제외하고 사용자와 디바이스 데이터를 조인합니다.
-- CREATE STREAM enriched_click_events WITH (KAFKA_TOPIC='ENRICHED_CLICK_EVENTS', PARTITIONS=1, REPLICAS=1) AS
-- SELECT 
--     c.user_id,
--     u.name AS user_name,
--     c.device_id,
--     d.devicename AS device_name,
--     c.eventType,
--     c.eventData,
--     c.timestamp
-- FROM 
--     click_events_stream c
-- LEFT JOIN 
--     users_table u
--     ON c.user_id = u.id
-- LEFT JOIN 
--     devices_table d
--     ON c.device_id = d.id
-- EMIT CHANGES;


CREATE STREAM enriched_click_events WITH (KAFKA_TOPIC='ENRICHED_CLICK_EVENTS', PARTITIONS=1, REPLICAS=1) AS
SELECT
    c.user_id,
    u.id AS u_id,  -- 사용자 ID를 포함합니다.
    u.name AS user_name,
    c.device_id,
    d.id AS d_id,  -- 디바이스 ID를 포함합니다.
    d.devicename AS device_name,
    c.eventType,
    c.eventData,
    c.timestamp
FROM
    click_events_stream c
LEFT JOIN
    users_table u
    ON CAST(c.user_id AS INTEGER) = u.id
LEFT JOIN
    devices_table d
    ON CAST(c.device_id AS INTEGER) = d.id
EMIT CHANGES;






-- Enriched Click Events Stream을 새로운 토픽에 출력
CREATE STREAM enriched_click_events_output
WITH (KAFKA_TOPIC='enriched_click_events',
      VALUE_FORMAT='JSON') AS
SELECT * FROM enriched_click_events;
