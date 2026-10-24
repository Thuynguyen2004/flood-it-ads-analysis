-- 1. Khám phá số người có bất kỳ sự kiện nào và first_open theo ngày
SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_day,

    COUNT(DISTINCT user_pseudo_id) AS users_with_any_event,

    COUNT(DISTINCT IF(
        event_name = 'first_open',
        user_pseudo_id,
        NULL
    )) AS new_users

FROM
    `firebase-public-project.analytics_153293282.events_*`

WHERE
    _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
    AND user_pseudo_id IS NOT NULL

GROUP BY
    event_day

ORDER BY
    event_day;

-- So sánh cơ cấu sự kiện của hai ngày
SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_day,
    event_name,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_pseudo_id) AS total_users
FROM
    `firebase-public-project.analytics_153293282.events_*`
WHERE
    _TABLE_SUFFIX IN ('20180617', '20180618')
GROUP BY
    event_day,
    event_name
ORDER BY
    event_name,
    event_day;

-- Mỗi dòng trung gian là một người dùng trong một ngày
WITH user_day AS (
    SELECT
        event_date,
        user_pseudo_id,

        COUNTIF(
            event_name != 'screen_view'
        ) AS other_events,

        COUNTIF(
            event_name IN (
                'level_start',
                'level_start_quickplay'
            )
        ) AS game_starts

    FROM
        `firebase-public-project.analytics_153293282.events_*`

    WHERE
        _TABLE_SUFFIX IN ('20180617', '20180618')
        AND user_pseudo_id IS NOT NULL

    GROUP BY
        event_date,
        user_pseudo_id
)

SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_day,
    COUNT(*) AS users_with_any_event,
    COUNTIF(other_events = 0) AS screen_view_only_users,
    COUNTIF(game_starts > 0) AS users_starting_game
FROM
    user_day
GROUP BY
    event_date
ORDER BY
    event_date;
    
-- 4. Bảng kết quả chính dùng cho dashboard Daily_Users
-- new_users: số mã có first_open trong từng ngày.
-- Không cộng số người theo ngày để suy ra người dùng duy nhất toàn kỳ.
SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_day,

    COUNT(DISTINCT user_pseudo_id) AS users_with_any_event,

    COUNT(DISTINCT IF(
        event_name IN ('level_start', 'level_start_quickplay'),
        user_pseudo_id,
        NULL
    )) AS users_starting_game,

    COUNT(DISTINCT IF(
        event_name = 'first_open',
        user_pseudo_id,
        NULL
    )) AS new_users

FROM
    `firebase-public-project.analytics_153293282.events_*`

WHERE
    _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
    AND user_pseudo_id IS NOT NULL

GROUP BY
    event_day

ORDER BY
    event_day;