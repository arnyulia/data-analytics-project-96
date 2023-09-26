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
WHERE medium <> 'organic'),
tab2 as (select
        tab.source as utm_source,
        tab.medium as utm_medium,
        tab.campaign as utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(case when status_id = 142 then 1 else 0 end) as purchases_count,
        sum(amount) as revenue,
        to_char(date_trunc('day', tab.visit_date), 'YY-MM-DD') as visit_date
    from tab
    where tab.rn = 1
    group by 1,2,3,8),
tab4 as (select
        to_char(campaign_date, 'YY-MM-DD') as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads 
    group by 1,2,3,4
    union all
    select
        to_char(campaign_date, 'YY-MM-DD') as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by 1,2,3,4)    
select
        tab2.visit_date,
        tab2.utm_source,
        tab2.utm_medium,
        tab2.utm_campaign,
        visitors_count,
        total_cost,
        leads_count,
        purchases_count,
        revenue
    from tab2 left join tab4 on tab2.visit_date=tab4.visit_date 
        AND tab2.utm_source = tab4.utm_source
        AND tab2.utm_medium = tab4.utm_medium
        AND tab2.utm_campaign = tab4.utm_campaign
     group by 1,2,3,4,5,6,7,8,9 
     order by revenue desc nulls last, visit_date, visitors_count desc, 2,3,4;
