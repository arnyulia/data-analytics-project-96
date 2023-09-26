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
),

tab2 as (
    select
        tab.source as utm_source,
        tab.medium as utm_medium,
        tab.campaign as utm_campaign,
        COUNT(visitor_id) as visitors_count,
        COUNT(lead_id) as leads_count,
        COUNT(status_id) as purchases_count,
        SUM(amount) as revenue,
        TO_CHAR(DATE_TRUNC('day', tab.visit_date), 'YY-MM-DD') as visit_date
    from tab
    where tab.rn = 1
    group by 1, 2, 3, 8
),

tab4 as (
    select
        TO_CHAR(campaign_date, 'YY-MM-DD') as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) as total_cost
    from vk_ads
    group by 1, 2, 3, 4
    union all
    select
        TO_CHAR(campaign_date, 'YY-MM-DD') as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) as total_cost
    from ya_ads
    group by 1, 2, 3, 4
)

select
    tab2.visit_date,
    visitors_count,
    tab2.utm_source,
    tab2.utm_medium,
    tab2.utm_campaign,
    total_cost,
    leads_count,
    purchases_count,
    revenue
from tab2 left join tab4
    on
        tab2.visit_date = tab4.visit_date
        and tab2.utm_source = tab4.utm_source
        and tab2.utm_medium = tab4.utm_medium
        and tab2.utm_campaign = tab4.utm_campaign
group by 1, 2, 3, 4, 5, 6, 7, 8, 9
order by revenue desc nulls last, visit_date asc, visitors_count desc, 3, 4, 5;
