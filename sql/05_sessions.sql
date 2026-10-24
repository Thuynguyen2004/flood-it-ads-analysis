/*
Ước lượng phiên từ dữ liệu sự kiện.

- Phiên mới bắt đầu khi khoảng nghỉ lớn hơn 30 phút.
- Không tự tách phiên khi qua nửa đêm.
- Phiên được tính vào event_date của timestamp mở phiên.
- Nếu cùng mã và timestamp có nhiều event_date, chọn ngày nhỏ nhất để gán ngày.
- Độ dài phiên là khoảng thời gian từ sự kiện đầu đến cuối, không phải thời gian tương tác liên tục.
- Phiên có thể không chứa sự kiện gameplay.
- Phiên ở đầu/cuối cửa sổ dữ liệu có thể bị cắt.
- avg_sessions_per_user tính cho toàn bộ 114 ngày.
- Đầu vào mô hình quảng cáo dùng: SUM(sessions_started) / SUM(active_users), không lấy trung bình các tỷ lệ ngày đã làm tròn.
*/

-- Ước lượng phiên theo khoảng nghỉ hơn 30 phút
WITH event_times AS (
    -- Gộp các sự kiện cùng timestamp của một người
    SELECT DISTINCT
        user_pseudo_id,
        event_timestamp
    FROM
        `firebase-public-project.analytics_153293282.events_*`
    WHERE
        _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
        AND user_pseudo_id IS NOT NULL
        AND event_timestamp IS NOT NULL
        AND event_name NOT IN (
            'app_remove',
            'app_update',
            'os_update'
        )
),

previous_events AS (
    SELECT
        user_pseudo_id,
        event_timestamp,

        LAG(event_timestamp) OVER (
            PARTITION BY user_pseudo_id
            ORDER BY event_timestamp
        ) AS previous_timestamp

    FROM event_times
),

session_flags AS (
    SELECT
        *,
        CASE
            WHEN previous_timestamp IS NULL THEN 1
            WHEN event_timestamp - previous_timestamp
                 > 30 * 60 * 1000000 THEN 1
            ELSE 0
        END AS new_session
    FROM previous_events
),

numbered_sessions AS (
    SELECT
        *,
        SUM(new_session) OVER (
            PARTITION BY user_pseudo_id
            ORDER BY event_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS session_number
    FROM session_flags
),

sessions AS (
    SELECT
        user_pseudo_id,
        session_number,
        MIN(event_timestamp) AS start_time,
        MAX(event_timestamp) AS end_time
    FROM numbered_sessions
    GROUP BY
        user_pseudo_id,
        session_number
),

session_durations AS (
    SELECT
        user_pseudo_id,
        session_number,
        (end_time - start_time) / 60000000.0
            AS duration_minutes
    FROM sessions
)

SELECT
    COUNT(*) AS total_sessions,
    COUNT(DISTINCT user_pseudo_id) AS total_users,

    ROUND(
        SAFE_DIVIDE(
            COUNT(*),
            COUNT(DISTINCT user_pseudo_id)
        ), 2
    ) AS avg_sessions_per_user,

    ROUND(
        AVG(duration_minutes), 2
    ) AS avg_session_minutes,

    ROUND(
        APPROX_QUANTILES(
            duration_minutes, 100
        )[OFFSET(50)], 2
    ) AS median_session_minutes,

    COUNTIF(
        duration_minutes = 0
    ) AS zero_duration_sessions

FROM session_durations;

-- Số phiên bắt đầu và người dùng hoạt động theo ngày
WITH event_times AS (
    -- Gộp các sự kiện cùng timestamp của một người
    SELECT
        user_pseudo_id,
        event_timestamp,
        MIN(PARSE_DATE('%Y%m%d', event_date)) AS event_day
    FROM
        `firebase-public-project.analytics_153293282.events_*`
    WHERE
        _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
        AND user_pseudo_id IS NOT NULL
        AND event_timestamp IS NOT NULL
        AND event_name NOT IN (
            'app_remove',
            'app_update',
            'os_update'
        )
    GROUP BY
        user_pseudo_id,
        event_timestamp
),

previous_events AS (
    SELECT
        *,
        LAG(event_timestamp) OVER (
            PARTITION BY user_pseudo_id
            ORDER BY event_timestamp
        ) AS previous_timestamp
    FROM event_times
),

session_flags AS (
    SELECT
        *,
        CASE
            WHEN previous_timestamp IS NULL THEN 1
            WHEN event_timestamp - previous_timestamp
                 > 30 * 60 * 1000000 THEN 1
            ELSE 0
        END AS new_session
    FROM previous_events
),

daily_metrics AS (
    SELECT
        event_day,
        COUNT(DISTINCT user_pseudo_id) AS active_users,
        SUM(new_session) AS sessions_started
    FROM session_flags
    GROUP BY event_day
)

SELECT
    event_day,
    active_users,
    sessions_started,

    ROUND(
        SAFE_DIVIDE(sessions_started, active_users),
        4
    ) AS sessions_per_active_user

FROM daily_metrics
ORDER BY event_day;