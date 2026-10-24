/*
Phân tích hoàn thành theo level, không phải funnel tuần tự.

- Chỉ số hoàn thành tính theo người dùng tại từng level.
- Không phải tỷ lệ thắng theo lượt chơi hoặc tỷ lệ bỏ game.
- Level không đọc được và level ngoài 1–30 không được đưa
  vào truy vấn tính tỷ lệ hoàn thành.
- Người bắt đầu gần cuối dataset có ít thời gian theo dõi hơn.
- observed_completion_pct có thang 0–100.
  Ví dụ: 36.39 nghĩa là 36,39%.
*/
-- Kiểm tra tham số level của các sự kiện gameplay
WITH gameplay AS (
    SELECT
        event_name,
        user_pseudo_id,

        (
            SELECT COALESCE(
                ep.value.int_value,
                SAFE_CAST(ep.value.double_value AS INT64)
            )
            FROM UNNEST(event_params) AS ep
            WHERE ep.key = 'level'
        ) AS level_number

    FROM
        `firebase-public-project.analytics_153293282.events_*`

    WHERE
        _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
        AND event_name IN (
            'level_start',
            'level_end',
            'level_complete',
            'level_fail'
        )
)

SELECT
    event_name,
    COUNT(*) AS total_events,
    COUNTIF(level_number IS NULL) AS events_without_level,
    MIN(level_number) AS min_level,
    MAX(level_number) AS max_level,
    COUNT(DISTINCT user_pseudo_id) AS total_users
FROM gameplay
GROUP BY event_name
ORDER BY event_name;

-- Người bắt đầu và hoàn thành sau lần bắt đầu đầu tiên được quan sát
WITH gameplay AS (
    SELECT
        user_pseudo_id,
        event_name,
        event_timestamp,

        (
            SELECT COALESCE(
                ep.value.int_value,
                SAFE_CAST(ep.value.double_value AS INT64)
            )
            FROM UNNEST(event_params) AS ep
            WHERE ep.key = 'level'
        ) AS level_number

    FROM
        `firebase-public-project.analytics_153293282.events_*`

    WHERE
        _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
        AND user_pseudo_id IS NOT NULL
        AND event_name IN ('level_start', 'level_complete')
),

-- Mỗi dòng là một người dùng tại một level
user_level AS (
    SELECT
        user_pseudo_id,
        level_number,

        MIN(IF(
            event_name = 'level_start',
            event_timestamp,
            NULL
        )) AS first_start,

        MAX(IF(
            event_name = 'level_complete',
            event_timestamp,
            NULL
        )) AS last_complete

    FROM gameplay
    WHERE level_number BETWEEN 1 AND 30
    GROUP BY
        user_pseudo_id,
        level_number
)

SELECT
    level_number,

    COUNTIF(first_start IS NOT NULL) AS users_started,

    COUNTIF(
        first_start IS NOT NULL
        AND last_complete > first_start
    ) AS users_completed_after_start,

    ROUND(
        100.0 * SAFE_DIVIDE(
            COUNTIF(
                first_start IS NOT NULL
                AND last_complete > first_start
            ),
            COUNTIF(first_start IS NOT NULL)
        ), 2
    ) AS observed_completion_pct

FROM user_level
GROUP BY level_number
ORDER BY level_number;

-- Kiểm tra sự kiện tại các level quanh 27 và 29
WITH gameplay AS (
    SELECT
        user_pseudo_id,
        event_name,

        (
            SELECT COALESCE(
                ep.value.int_value,
                SAFE_CAST(ep.value.double_value AS INT64)
            )
            FROM UNNEST(event_params) AS ep
            WHERE ep.key = 'level'
        ) AS level_number

    FROM
        `firebase-public-project.analytics_153293282.events_*`

    WHERE
        _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
        AND user_pseudo_id IS NOT NULL
        AND event_name IN (
            'level_start',
            'level_complete',
            'level_fail',
            'level_retry',
            'level_reset'
        )
)

SELECT
    level_number,
    event_name,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_pseudo_id) AS total_users
FROM gameplay
WHERE level_number BETWEEN 25 AND 30
GROUP BY
    level_number,
    event_name
ORDER BY
    level_number,
    event_name;