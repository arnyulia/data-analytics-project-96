"last_paid_click"

with tab as (select
    s.visitor_id,
    visit_date,
    source,
    medium,
    campaign,
    created_at,
    amount,
    closing_reason,
    status_id,
    lead_id,
    ROW_NUMBER()
        over (partition by s.visitor_id order by visit_date desc) as rn
from sessions s
left join leads l
    on s.visitor_id = l.visitor_id
    and visit_date <= created_at
WHERE medium <> 'organic')
select
        visitor_id,
        visit_date,
        source as utm_source,
        medium as utm_medium,
        campaign as utm_campaign,
        lead_id,
        created_at,
        amount,
        closing_reason,
        status_id
    from tab
    where tab.rn = 1
   order by amount desc NULLS LAST, visit_date, 4,5,6;
