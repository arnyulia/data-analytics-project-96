--общее кол-во визитов
SELECT
        count(visitor_id) count_distinct
    FROM sessions;

--кол-во уникальных визитов
select COUNT(distinct visitor_id) as distinct_visitors
from sessions;

--визиты по дням
   SELECT
        to_char(visit_date, 'YYYY-MM-DD') date,
        count(visitor_id)
    FROM sessions
    GROUP BY 1;

--визиты по неделям
SELECT
        to_char(date_trunc('week', visit_date), 'YYYY-MM-DD') weeks,
        count(visitor_id)
    FROM sessions
    GROUP BY 1;

--визиты по дням недели
select 
            extract(ISODOW FROM visit_date),
        to_char(date_trunc('day', visit_date), 'day')as day_of_week,
        count(visitor_id) as count_visitors
        from sessions
        group by 1,2;

--распределение визитов по источникам
WITH tab as (
SELECT
    TO_CHAR(visit_date, 'Month') AS Month,
    source,
    medium,
    COUNT(DISTINCT visitor_id) AS count_visitors,
    CASE
        WHEN source in ('yandex','vk') then source
        WHEN medium = 'organic' THEN 'free'
        ELSE 'other'
    END name_source 
FROM sessions
GROUP BY 1,2,3)
SELECT 
    Month,
    name_source,
    SUM(count_visitors)
FROM tab
GROUP BY 1, 2
order by 3 desc;

--Общее Количество уникальных лидов
SELECT
    TO_CHAR(created_at, 'Month'),
    COUNT(DISTINCT lead_id) count_leads
FROM leads
GROUP BY 1;

--Количество лидов по источникам
SELECT 
     TO_CHAR(created_at , 'Month') AS Month,
     source,
     COUNT(DISTINCT lead_id) AS count_leads
FROM leads l
INNER JOIN sessions s
on s.visitor_id=l.visitor_id 
AND visit_date <= created_at
GROUP BY 1, 2
ORDER BY 3 DESC;

--распределение лидов по источникам
SELECT 
         CASE
        WHEN source = 'yandex' THEN 'yandex'
        WHEN source = 'vk' THEN 'vk'
        WHEN medium = 'organic' THEN 'free'
        ELSE 'others'
    END name_source,
     COUNT(lead_id) AS count_leads
FROM leads l
INNER JOIN sessions s
on s.visitor_id=l.visitor_id 
AND visit_date <= created_at
GROUP BY 1 
order by 2;

--ежедневное распределение лидов по источникам
SELECT 
     TO_CHAR(created_at , 'YYYY-MM-DD') AS Day_of_month,
     source,
     COUNT(DISTINCT lead_id) AS count_leads
FROM leads
INNER JOIN sessions s
on s.visitor_id=l.visitor_id  
AND visit_date <= created_at
GROUP BY 1, 2
order by 1, 3 desc;


--визиты-лиды-клиенты по источникам
WITH tab AS (
SELECT
    DISTINCT ON (s.visitor_id) s.visitor_id,
    s.visit_date,
    s.source,
    lead_id,
    closing_reason,
    CASE 
        WHEN closing_reason = 'Успешная продажа'
        THEN 1 ELSE 0 
    END purchases,
    status_id   
FROM sessions s
LEFT JOIN leads l
ON s.visitor_id = l.visitor_id
AND visit_date <= created_at)
SELECT
     source,
     COUNT(visitor_id) AS count_visitors,
     COUNT(lead_id) AS count_leads,
     SUM(purchases) AS count_clients
FROM tab
GROUP BY TO_CHAR(visit_date, 'Month'), source
HAVING COUNT(DISTINCT lead_id) != 0
ORDER BY 4 DESC;

--Отношение клиентов к общему количеству лидов (Конверсия,%)
SELECT
    round(
        (sum(lead_amount) * 100.00 / count(lead_id)), 2
    ) AS "конверсия из лида в клиента",
    count(lead_id),
    sum(lead_amount)
FROM
    (
        SELECT DISTINCT
            s.visitor_id,
            l.lead_id,
            amount,
            closing_reason,
            CASE
                WHEN amount > 0 THEN 1
                ELSE 0
            END AS lead_amount
        FROM sessions AS s LEFT JOIN leads AS l
            ON s.visitor_id = l.visitor_id
            AND visit_date <= created_at
) AS c;

--Расходы в динамике по source / medium / campaign
SELECT
    date_trunc('day', campaign_date) AS visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    sum(daily_spent) expenses
FROM vk_ads
GROUP BY 1, 2, 3, 4
UNION ALL
SELECT
    date_trunc('day', campaign_date) AS visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    sum(daily_spent) expenses
FROM ya_ads
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 3, 4;

--Кампании не приносящие лидов
SELECT
    s.source AS utm_source,
    s.medium AS utm_medium,
    s.campaign AS utm_campaign,
    count(l.lead_id) AS lead_count
FROM leads l
RIGHT JOIN sessions s
    ON
        l.visitor_id = s.visitor_id
        AND l.created_at >= s.visit_date
GROUP BY 1, 2, 3
HAVING count(l.lead_id) = 0;

--Выручка
SELECT sum(amount) revenue
FROM
    (SELECT
        1 AS leed,
        amount,
        closing_reason,
        CASE
            WHEN amount > 0 THEN 1
            ELSE 0
        END AS leed_amount,
        to_char(created_at, 'YYYY-MM-DD')
    FROM leads) с;

--Общие расходы за июнь на vk и ya

select month, sum(spent) from
(SELECT
    TO_CHAR(campaign_date, 'Month') AS month,
    utm_source,
    utm_medium,
    utm_campaign,
    SUM(daily_spent) AS spent 
FROM vk_ads vk
GROUP BY 1,2,3,4
UNION ALL
SELECT
    TO_CHAR(campaign_date, 'Month') AS month,
    utm_source,
    utm_medium,
    utm_campaign,
    SUM(daily_spent) AS spent  
FROM ya_ads ya
GROUP BY 1,2,3,4
ORDER BY 1) c
group by 1;

--Воронка продаж

WITH visit_lead AS (
    SELECT DISTINCT ON (s.visitor_id)
        s.visitor_id,
        visit_date,
        lead_id,
        closing_reason,
        status_id,
        CASE
            WHEN closing_reason = 'Успешная продажа' OR status_id = 142
                THEN 1
            ELSE 0
        END AS purchases
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON
            s.visitor_id = l.visitor_id
            AND visit_date <= created_at
)

SELECT
    COUNT(DISTINCT visitor_id) AS count_visitors,
    COUNT(DISTINCT lead_id) AS count_leads,
    SUM(purchases)
FROM visit_lead
GROUP BY TO_CHAR(visit_date, 'Month');


--расчеты основных метрик на базе таблицы last_paid_click_arnyulia

-- Metrics by source

SELECT
   utm_source,
   ROUND(SUM(total_cost)/SUM(visitors_count), 2) AS CPU,
   ROUND(SUM(total_cost)/SUM(leads_count), 2) AS CPL,
   ROUND(SUM(total_cost)/SUM(purchases_count), 2) AS CPPU,
   ROUND((SUM(revenue) - SUM(total_cost))*100.00/SUM(total_cost), 2) AS ROI
FROM last_paid_click_arnyulia
GROUP BY utm_source
HAVING  SUM(total_cost) > 0
    AND SUM(visitors_count) > 0
    AND SUM(purchases_count) > 0
    AND SUM(revenue) > 0;

-- Metrics by source, medium and campaign

SELECT
   utm_source,
   utm_medium,
   utm_campaign,
   ROUND(SUM(total_cost)/SUM(visitors_count), 2) AS CPU,
   ROUND(SUM(total_cost)/SUM(leads_count), 2) AS CPL,
   ROUND(SUM(total_cost)/SUM(purchases_count), 2) AS CPPU,
   ROUND((SUM(revenue) - SUM(total_cost))*100.00/SUM(total_cost), 2) AS ROI
FROM last_paid_click_arnyulia
GROUP BY 1, 2, 3
HAVING  SUM(total_cost) > 0
    AND SUM(visitors_count) > 0
    AND SUM(purchases_count) > 0
    AND SUM(revenue) > 0;

--Metrics by paid-off campaigns

SELECT
   utm_source,
   utm_medium,
   utm_campaign,
   SUM(revenue) AS revenue,
   SUM(total_cost) AS total_cost,
  ROUND((SUM(revenue) - SUM(total_cost))*100.00/SUM(total_cost), 2) AS ROI
FROM last_paid_click_arnyulia
GROUP BY 1, 2, 3
HAVING  SUM(total_cost) > 0
AND (SUM(revenue) - SUM(total_cost))*100.00/SUM(total_cost) >= 0
ORDER BY 6 desc;

--Metrics by unprofitable campaigns

SELECT
   utm_source,
   utm_medium,
   utm_campaign,
   SUM(revenue) AS revenue,
   SUM(total_cost) AS total_cost,
  ROUND((SUM(revenue) - SUM(total_cost))*100.00/SUM(total_cost), 2) AS ROI
FROM last_paid_click_arnyulia
GROUP BY 1, 2, 3
HAVING  SUM(total_cost) > 0
AND (SUM(revenue) - SUM(total_cost))*100.00/SUM(total_cost) < 0
ORDER BY 6 DESC;


