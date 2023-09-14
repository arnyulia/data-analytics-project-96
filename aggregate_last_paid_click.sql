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
        tab.visitor_id,
        tab.source as utm_source,
        tab.medium as utm_medium,
        tab.campaign as utm_campaign,
        tab.created_at,
        tab.amount,
        tab.closing_reason,
        tab.status_id,
        date_trunc('day', tab.visit_date) as visit_date,
        lead_id
    from tab
    where tab.rn = 1),
tab3 as (select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(case when status_id = 142 then 1 else 0 end) as purchases_count,
        sum(amount) as revenue
    from tab2
    group by 1, 2, 3, 4),
tab4 as (select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads),
tab5 as (select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from tab4
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign),
tab6 as (select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        null as revenue,
        null as visitors_count,
        null as leads_count,
        null as purchases_count,
        total_cost
    from tab5
    union all
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from tab3)
select
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    sum(coalesce(visitors_count, 0)) as visitors_count,
    sum(coalesce(total_cost, 0)) as total_cost,
    sum(coalesce(leads_count, 0)) as leads_count,
    sum(coalesce(purchases_count, 0)) as purchases_count,
    sum(coalesce(revenue, 0)) as revenue from tab6
group by 1, 2, 3, 4
order by 9 desc, 1, 5 desc,2, 3, 4 limit 15;
