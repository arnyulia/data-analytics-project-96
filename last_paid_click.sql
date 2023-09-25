"last_paid_click"

WITH tab AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        s.content AS utm_content,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    FROM sessions s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at),
tab2 AS (
    SELECT DISTINCT ON (a.visitor_id)
        a.visitor_id,
        b.utm_campaign,
        b.utm_content,
        b.lead_id,
        b.created_at,
        b.amount,
        b.closing_reason,
        b.status_id,
        coalesce(b.visit_date, a.visit_date) AS visit_date,
        coalesce(b.utm_source, a.utm_source) AS utm_source,
        coalesce(b.utm_medium, a.utm_medium) AS utm_medium
    FROM tab AS a
    LEFT JOIN tab AS b
        ON a.visitor_id = b.visitor_id AND b.utm_medium != 'organic'
    ORDER BY a.visitor_id, b.visit_date DESC)
    SELECT *
FROM tab2
ORDER BY
    amount DESC NULLS LAST,
    date_trunc('day', visit_date),
    utm_source,
    utm_medium,
    utm_campaign;
