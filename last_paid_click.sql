"last_paid_click"

with tab as (
    select
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
            over (partition by s.visitor_id order by visit_date desc)
        as rn
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and visit_date <= created_at
    where medium != 'organic'
)

select
    tab.visitor_id,
    TO_CHAR(tab.visit_date, 'YYYY-MM-DD') as visit_date
    tab.source as utm_source,
    tab.medium as utm_medium,
    tab.campaign as utm_campaign,
    tab.lead_id,
    tab.created_at,
    tab.amount,
    tab.closing_reason,
    tab.status_id
from tab
where tab.rn = 1
order by tab.amount desc nulls last, tab.visit_date asc, 4, 5, 6;
