#!/usr/bin/env bash

CURDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../shell_config.sh
. "$CURDIR"/../shell_config.sh


$CLICKHOUSE_CLIENT --query "DROP TABLE IF EXISTS movement"

$CLICKHOUSE_CLIENT --query "CREATE TABLE movement (date DateTime('Asia/Istanbul')) Engine = MergeTree ORDER BY (toStartOfHour(date)) SETTINGS index_granularity = 8192, index_granularity_bytes = '10Mi';"

$CLICKHOUSE_CLIENT --query "insert into movement select toDateTime('2020-01-22 00:00:00', 'Asia/Istanbul') + number%(23*3600) from numbers(1000000);"

$CLICKHOUSE_CLIENT --query "OPTIMIZE TABLE movement FINAL"

$CLICKHOUSE_CLIENT --query "
SELECT
    count(),
    toStartOfHour(date) AS Hour
FROM movement
WHERE (date >= toDateTime('2020-01-22T10:00:00', 'Asia/Istanbul')) AND (date <= toDateTime('2020-01-22T23:00:00', 'Asia/Istanbul'))
GROUP BY Hour
ORDER BY Hour DESC
" | grep "16:00:00" | cut -f1


$CLICKHOUSE_CLIENT --query "alter table movement delete where date >= toDateTime('2020-01-22T16:00:00', 'Asia/Istanbul')  and date < toDateTime('2020-01-22T17:00:00', 'Asia/Istanbul') SETTINGS mutations_sync = 2"

$CLICKHOUSE_CLIENT --query "
SELECT
    count(),
    toStartOfHour(date) AS Hour
FROM movement
WHERE (date >= toDateTime('2020-01-22T10:00:00', 'Asia/Istanbul')) AND (date <= toDateTime('2020-01-22T23:00:00', 'Asia/Istanbul'))
GROUP BY Hour
ORDER BY Hour DESC
" | grep "16:00:00" | wc -l


$CLICKHOUSE_CLIENT --query "
SELECT
    count(),
    toStartOfHour(date) AS Hour
FROM movement
WHERE (date >= toDateTime('2020-01-22T10:00:00', 'Asia/Istanbul')) AND (date <= toDateTime('2020-01-22T23:00:00', 'Asia/Istanbul'))
GROUP BY Hour
ORDER BY Hour DESC
" | grep "22:00:00" | cut -f1


$CLICKHOUSE_CLIENT --query "
SELECT
    count(),
    toStartOfHour(date) AS Hour
FROM movement
GROUP BY Hour
ORDER BY Hour DESC
" | grep "22:00:00" | cut -f1


$CLICKHOUSE_CLIENT --query "DROP TABLE IF EXISTS movement"
