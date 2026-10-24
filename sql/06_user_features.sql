/*
Phân bố ngày chơi và phân nhóm người dùng.

- Truy vấn 1 xét toàn bộ khoảng dữ liệu, chỉ gồm mã có ít nhất một sự kiện bắt đầu chơi.
- Truy vấn 2 và 3 xét mã có first_open đầu tiên quan sát được không muộn hơn 27/09/2018.
- Cửa sổ D0–D6 gồm đúng 7 ngày, tính cả ngày first_open.
- Nhóm 0 ngày nghĩa là không ghi nhận bắt đầu chơi trong cửa sổ này, không đồng nghĩa đã bỏ game.
- Các cột kết thúc bằng _pct có thang 0–100.
- ad_reward là sự kiện nhận thưởng, không phải tổng lượt hiển thị quảng cáo hoặc doanh thu.
- So sánh giữa các nhóm không chứng minh quảng cáo thưởng làm tăng mức độ gắn bó.
*/
-- Phân bố số ngày có sự kiện bắt đầu chơi
WITH user_play_days AS (
    SELECT
        user_pseudo_id,
        COUNT(DISTINCT event_date) AS active_play_days
    FROM
        `firebase-public-project.analytics_153293282.events_*`
    WHERE
        _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
        AND user_pseudo_id IS NOT NULL
        AND event_name IN (
            'level_start',
            'level_start_quickplay'
        )
    GROUP BY
        user_pseudo_id
)

SELECT
    active_play_days,
    COUNT(*) AS total_users,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS users_pct
FROM user_play_days
GROUP BY active_play_days
ORDER BY active_play_days;

-- Phân nhóm theo số ngày bắt đầu chơi trong D0–D6
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

new_users AS (
    SELECT
        user_pseudo_id,
        MIN(event_day) AS cohort_date
    FROM events
    WHERE event_name = 'first_open'
    GROUP BY user_pseudo_id
),

eligible_users AS (
    SELECT
        user_pseudo_id,
        cohort_date
    FROM new_users
    WHERE cohort_date <= DATE '2018-09-27'
),

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

user_features AS (
    SELECT
        n.user_pseudo_id,
        n.cohort_date,
        COUNT(p.event_day) AS active_play_days_7d
    FROM eligible_users AS n
    LEFT JOIN play_days AS p
        ON n.user_pseudo_id = p.user_pseudo_id
        AND p.event_day BETWEEN n.cohort_date
            AND DATE_ADD(n.cohort_date, INTERVAL 6 DAY)
    GROUP BY
        n.user_pseudo_id,
        n.cohort_date
),

segments AS (
    SELECT
        *,
        CASE
            WHEN active_play_days_7d = 0
                THEN '0 ngay'
            WHEN active_play_days_7d = 1
                THEN '1 ngay'
            WHEN active_play_days_7d BETWEEN 2 AND 3
                THEN '2-3 ngay'
            ELSE '4-7 ngay'
        END AS player_segment
    FROM user_features
)

SELECT
    player_segment,
    COUNT(*) AS total_users,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS users_pct,

    ROUND(
        AVG(active_play_days_7d),
        2
    ) AS avg_active_play_days_7d

FROM segments
GROUP BY player_segment
ORDER BY player_segment;

-- Quảng cáo thưởng theo nhóm ngày chơi trong D0–D6
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

new_users AS (
    SELECT
        user_pseudo_id,
        MIN(event_day) AS cohort_date
    FROM events
    WHERE event_name = 'first_open'
    GROUP BY user_pseudo_id
),

eligible_users AS (
    SELECT *
    FROM new_users
    WHERE cohort_date <= DATE '2018-09-27'
),

user_features AS (
    SELECT
        n.user_pseudo_id,

        COUNT(DISTINCT IF(
            e.event_name IN (
                'level_start',
                'level_start_quickplay'
            ),
            e.event_day,
            NULL
        )) AS active_play_days_7d,

        COUNTIF(
            e.event_name = 'ad_reward'
        ) AS ad_reward_events_7d

    FROM eligible_users AS n
    LEFT JOIN events AS e
        ON n.user_pseudo_id = e.user_pseudo_id
        AND e.event_day BETWEEN n.cohort_date
            AND DATE_ADD(n.cohort_date, INTERVAL 6 DAY)

    GROUP BY n.user_pseudo_id
),

segments AS (
    SELECT
        *,
        CASE
            WHEN active_play_days_7d = 0 THEN '0 ngay'
            WHEN active_play_days_7d = 1 THEN '1 ngay'
            WHEN active_play_days_7d BETWEEN 2 AND 3
                THEN '2-3 ngay'
            ELSE '4-7 ngay'
        END AS player_segment
    FROM user_features
)

SELECT
    player_segment,
    COUNT(*) AS total_users,

    COUNTIF(
        ad_reward_events_7d > 0
    ) AS users_with_ad_reward,

    ROUND(
        100.0 * SAFE_DIVIDE(
            COUNTIF(ad_reward_events_7d > 0),
            COUNT(*)
        ), 2
    ) AS users_with_ad_reward_pct,

    SUM(ad_reward_events_7d) AS total_ad_reward_events

FROM segments
GROUP BY player_segment
ORDER BY player_segment;