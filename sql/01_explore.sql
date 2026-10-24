-- Kiểm tra khả năng đọc dữ liệu Flood-It
SELECT
    event_date,
    event_name,
    user_pseudo_id
FROM
    `firebase-public-project.analytics_153293282.events_*`
WHERE
    _TABLE_SUFFIX BETWEEN '20180901' AND '20180930'
LIMIT 10;

SELECT
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_pseudo_id) AS total_users,
    COUNT(DISTINCT event_date) AS total_days
FROM
    `firebase-public-project.analytics_153293282.events_*`
WHERE
    _TABLE_SUFFIX BETWEEN '20180901' AND '20180930';

SELECT
    event_name,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_pseudo_id) AS total_users
FROM
    `firebase-public-project.analytics_153293282.events_*`
WHERE
    _TABLE_SUFFIX BETWEEN '20180901' AND '20180930'
GROUP BY
    event_name
ORDER BY
    total_events DESC;

SELECT
    event_name,
    ep.key AS parameter_name,
    COUNT(*) AS frequency
FROM
    `firebase-public-project.analytics_153293282.events_*`,
    UNNEST(event_params) AS ep
WHERE
    _TABLE_SUFFIX BETWEEN '20180901' AND '20180930'
GROUP BY
    event_name,
    parameter_name
ORDER BY
    event_name,
    frequency DESC;

SELECT
    event_name,
    ep.key AS parameter_name,
    ep.value.string_value AS string_value,
    ep.value.int_value AS int_value,
    ep.value.float_value AS float_value,
    ep.value.double_value AS double_value,
    COUNT(*) AS frequency
FROM
    `firebase-public-project.analytics_153293282.events_*`,
    UNNEST(event_params) AS ep
WHERE
    _TABLE_SUFFIX BETWEEN '20180901' AND '20180930'
    AND (
        (
            event_name IN ('level_start', 'level_complete')
            AND ep.key IN ('level', 'level_name')
        )
        OR (
            event_name = 'level_start_quickplay'
            AND ep.key = 'board'
        )
        OR (
            event_name = 'ad_reward'
            AND ep.key IN ('type', 'value')
        )
    )
GROUP BY
    event_name,
    parameter_name,
    string_value,
    int_value,
    float_value,
    double_value
ORDER BY
    event_name,
    parameter_name,
    frequency DESC;

SELECT
    MIN(table_name) AS first_table,
    MAX(table_name) AS last_table,
    COUNT(*) AS total_daily_tables
FROM
    `firebase-public-project.analytics_153293282.INFORMATION_SCHEMA.TABLES`
WHERE
    REGEXP_CONTAINS(table_name, r'^events_[0-9]{8}$');

-- Kiểm tra phạm vi và quy mô toàn bộ dữ liệu
SELECT
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS start_date,
    MAX(PARSE_DATE('%Y%m%d', event_date)) AS end_date,
    COUNT(DISTINCT event_date) AS total_days,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_pseudo_id) AS total_users
FROM
    `firebase-public-project.analytics_153293282.events_*`
WHERE
    _TABLE_SUFFIX BETWEEN '20180612' AND '20181003';

-- Kiểm tra số sự kiện và người dùng từng ngày
SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_day,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_pseudo_id) AS total_users
FROM
    `firebase-public-project.analytics_153293282.events_*`
WHERE
    _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
GROUP BY
    event_day
ORDER BY
    event_day;

-- Phân bố số sự kiện mỗi người dùng trong toàn bộ dataset
WITH user_events AS (
    SELECT
        user_pseudo_id,
        COUNT(*) AS event_count
    FROM
        `firebase-public-project.analytics_153293282.events_*`
    WHERE
        _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
        AND user_pseudo_id IS NOT NULL
    GROUP BY
        user_pseudo_id
)

SELECT
    COUNT(*) AS total_users,
    ROUND(AVG(event_count), 2) AS avg_events_per_user,
    APPROX_QUANTILES(event_count, 100)[OFFSET(50)] AS median_events,
    MAX(event_count) AS max_events
FROM
    user_events;

-- Tìm 10 mã người dùng có nhiều sự kiện nhất
SELECT
    user_pseudo_id,
    COUNT(*) AS total_events,
    COUNT(DISTINCT event_date) AS active_days,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_seen,
    MAX(PARSE_DATE('%Y%m%d', event_date)) AS last_seen
FROM
    `firebase-public-project.analytics_153293282.events_*`
WHERE
    _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
    AND user_pseudo_id IS NOT NULL
GROUP BY
    user_pseudo_id
ORDER BY
    total_events DESC
LIMIT 10;

-- Xem 100 sự kiện đầu tiên của một người dùng
SELECT
    event_date,
    TIMESTAMP_MICROS(event_timestamp) AS event_time_utc,
    event_name,

    (
        SELECT COALESCE(
            ep.value.int_value,
            SAFE_CAST(ep.value.double_value AS INT64)
        )
        FROM UNNEST(event_params) AS ep
        WHERE ep.key = 'level'
    ) AS level_number,

    (
        SELECT ep.value.string_value
        FROM UNNEST(event_params) AS ep
        WHERE ep.key = 'board'
    ) AS board

FROM
    `firebase-public-project.analytics_153293282.events_*`

WHERE
    _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
    AND user_pseudo_id = '959635567E419A061EECCCA478EDC718'

ORDER BY
    event_timestamp

LIMIT 100;