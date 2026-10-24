-- Retention quay lại chơi D1/D7 theo cohort first_open
WITH events AS (
    SELECT
        PARSE_DATE('%Y%m%d', event_date) AS event_day,
        user_pseudo_id,
        event_name
    FROM
        `firebase-public-project.analytics_153293282.events_*`
    WHERE
        _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
        AND user_pseudo_id IS NOT NULL
),

-- Mỗi mã người dùng chỉ thuộc một cohort
new_users AS (
    SELECT
        user_pseudo_id,
        MIN(event_day) AS cohort_date
    FROM events
    WHERE event_name = 'first_open'
    GROUP BY user_pseudo_id
),

-- Mỗi người chỉ được tính một lần trong mỗi ngày chơi
play_days AS (
    SELECT DISTINCT
        user_pseudo_id,
        event_day
    FROM events
    WHERE event_name IN (
        'level_start',
        'level_start_quickplay'
    )
),

cohort_counts AS (
    SELECT
        n.cohort_date,
        COUNT(DISTINCT n.user_pseudo_id) AS cohort_size,

        COUNT(DISTINCT IF(
            p.event_day = DATE_ADD(n.cohort_date, INTERVAL 1 DAY),
            n.user_pseudo_id,
            NULL
        )) AS returned_d1,

        COUNT(DISTINCT IF(
            p.event_day = DATE_ADD(n.cohort_date, INTERVAL 7 DAY),
            n.user_pseudo_id,
            NULL
        )) AS returned_d7

    FROM new_users AS n
    LEFT JOIN play_days AS p
        ON n.user_pseudo_id = p.user_pseudo_id
        AND p.event_day IN (
            DATE_ADD(n.cohort_date, INTERVAL 1 DAY),
            DATE_ADD(n.cohort_date, INTERVAL 7 DAY)
        )
    GROUP BY n.cohort_date
)

SELECT
    cohort_date,
    cohort_size,

    IF(
        cohort_date <= DATE '2018-10-02',
        returned_d1,
        NULL
    ) AS returned_d1,

    IF(
        cohort_date <= DATE '2018-10-02',
        ROUND(100.0 * SAFE_DIVIDE(returned_d1, cohort_size), 2),
        NULL
    ) AS d1_retention_pct,

    IF(
        cohort_date <= DATE '2018-09-26',
        returned_d7,
        NULL
    ) AS returned_d7,

    IF(
        cohort_date <= DATE '2018-09-26',
        ROUND(100.0 * SAFE_DIVIDE(returned_d7, cohort_size), 2),
        NULL
    ) AS d7_retention_pct

FROM cohort_counts
ORDER BY cohort_date;

-- Retention quay lại chơi D1/D7 tổng hợp
WITH events AS (
    SELECT
        PARSE_DATE('%Y%m%d', event_date) AS event_day,
        user_pseudo_id,
        event_name
    FROM
        `firebase-public-project.analytics_153293282.events_*`
    WHERE
        _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
        AND user_pseudo_id IS NOT NULL
),

-- Xác định ngày first_open đầu tiên của mỗi mã
new_users AS (
    SELECT
        user_pseudo_id,
        MIN(event_day) AS cohort_date
    FROM events
    WHERE event_name = 'first_open'
    GROUP BY user_pseudo_id
),

-- Danh sách ngày bắt đầu chơi của mỗi mã
play_days AS (
    SELECT DISTINCT
        user_pseudo_id,
        event_day
    FROM events
    WHERE event_name IN (
        'level_start',
        'level_start_quickplay'
    )
),

-- Tính quy mô và số người quay lại của từng cohort
cohort_counts AS (
    SELECT
        n.cohort_date,
        COUNT(DISTINCT n.user_pseudo_id) AS cohort_size,

        COUNT(DISTINCT IF(
            p.event_day = DATE_ADD(n.cohort_date, INTERVAL 1 DAY),
            n.user_pseudo_id,
            NULL
        )) AS returned_d1,

        COUNT(DISTINCT IF(
            p.event_day = DATE_ADD(n.cohort_date, INTERVAL 7 DAY),
            n.user_pseudo_id,
            NULL
        )) AS returned_d7

    FROM new_users AS n
    LEFT JOIN play_days AS p
        ON n.user_pseudo_id = p.user_pseudo_id
        AND p.event_day IN (
            DATE_ADD(n.cohort_date, INTERVAL 1 DAY),
            DATE_ADD(n.cohort_date, INTERVAL 7 DAY)
        )
    GROUP BY n.cohort_date
)

-- Tổng hợp các cohort đủ thời gian theo dõi
SELECT
    SUM(IF(
        cohort_date <= DATE '2018-10-02',
        cohort_size, 0
    )) AS eligible_users_d1,

    SUM(IF(
        cohort_date <= DATE '2018-10-02',
        returned_d1, 0
    )) AS returned_users_d1,

    ROUND(
        100.0 * SAFE_DIVIDE(
            SUM(IF(
                cohort_date <= DATE '2018-10-02',
                returned_d1, 0
            )),
            SUM(IF(
                cohort_date <= DATE '2018-10-02',
                cohort_size, 0
            ))
        ), 2
    ) AS d1_retention_pct,

    SUM(IF(
        cohort_date <= DATE '2018-09-26',
        cohort_size, 0
    )) AS eligible_users_d7,

    SUM(IF(
        cohort_date <= DATE '2018-09-26',
        returned_d7, 0
    )) AS returned_users_d7,

    ROUND(
        100.0 * SAFE_DIVIDE(
            SUM(IF(
                cohort_date <= DATE '2018-09-26',
                returned_d7, 0
            )),
            SUM(IF(
                cohort_date <= DATE '2018-09-26',
                cohort_size, 0
            ))
        ), 2
    ) AS d7_retention_pct

FROM cohort_counts;

-- 3. Đường hoạt động D0–D29 phục vụ mô hình doanh thu
-- Khác retention gameplay ở trên:
-- hoạt động được xác định theo bộ lọc dùng cho phiên.
-- activity_rate trả về tỷ lệ 0–1, chưa nhân 100.

WITH events AS (
    SELECT
        PARSE_DATE('%Y%m%d', event_date) AS event_day,
        user_pseudo_id,
        event_name,
        event_timestamp
    FROM
        `firebase-public-project.analytics_153293282.events_*`
    WHERE
        _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
        AND user_pseudo_id IS NOT NULL
),

new_users AS (
    SELECT
        user_pseudo_id,
        MIN(event_day) AS cohort_date
    FROM events
    WHERE event_name = 'first_open'
    GROUP BY user_pseudo_id
),

-- Đủ cửa sổ D0–D29 trước khi dữ liệu kết thúc ngày 03/10
eligible_users AS (
    SELECT
        user_pseudo_id,
        cohort_date
    FROM new_users
    WHERE cohort_date <= DATE '2018-09-04'
),

active_days AS (
    SELECT DISTINCT
        user_pseudo_id,
        event_day
    FROM events
    WHERE
        event_timestamp IS NOT NULL
        AND event_name NOT IN (
            'app_remove',
            'app_update',
            'os_update'
        )
),

day_numbers AS (
    SELECT day_number
    FROM UNNEST(GENERATE_ARRAY(0, 29)) AS day_number
)

SELECT
    d.day_number,
    COUNT(*) AS cohort_users,
    COUNT(a.user_pseudo_id) AS active_users,

    SAFE_DIVIDE(
        COUNT(a.user_pseudo_id),
        COUNT(*)
    ) AS activity_rate

FROM eligible_users AS n
CROSS JOIN day_numbers AS d
LEFT JOIN active_days AS a
    ON n.user_pseudo_id = a.user_pseudo_id
    AND a.event_day = DATE_ADD(
        n.cohort_date,
        INTERVAL d.day_number DAY
    )

GROUP BY d.day_number
ORDER BY d.day_number;