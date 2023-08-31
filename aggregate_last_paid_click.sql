*витрина данных*

with tab as (
    select
        s.visitor_Id,
        DATE_TRUNC('day', s.visit_date) as visit_date,
        source as utm_source,
        medium as utm_medium,
        campaign AS utm_campaign,
        lead_id,
        created_at,
        amount,
        closing_reason,
        status_id,
        COALESCE(vk.daily_spent, 0) as vk_ads_daily_spent,
        COALESCE(ya.daily_spent, 0) as ya_ads_daily_spent,
        COALESCE(vk.daily_spent, 0) + COALESCE(ya.daily_spent, 0) as total_cost,
        case when closing_reason = 'Успешная продажа' then 1 end as purchases_count,
        row_number() over (partition by lead_id order by visit_date desc) as rn
    from sessions s
    left join leads l on s.visitor_Id = l.visitor_id
    left join vk_ads vk on 
    	DATE_TRUNC('day', s.visit_date) = DATE_TRUNC('day', vk.campaign_date) and
    	s.source = vk.utm_source and
    	s.medium = vk.utm_medium and 
    	s.campaign = vk.utm_campaign
	left join ya_ads ya on 
    	DATE_TRUNC('day', s.visit_date) = DATE_TRUNC('day', ya.campaign_date) and
    	s.source = ya.utm_source and
    	s.medium = ya.utm_medium and 
    	s.campaign = ya.utm_campaign
    where s.medium <> 'organic'
),
	tab2 as 
        (select * from tab where rn = 1)
    select
	TO_CHAR(visit_Date, 'YYYY-MM-DD') as visit_date,
	utm_source,utm_medium,utm_campaign,
    COUNT(visitor_id) as visitors_count,
    SUM(total_cost) as total_cost,
    COUNT(lead_id) as leads_count,
    SUM(purchases_count) as purchases_count,
    SUM(amount) as revenue
from tab2
group by visit_date, utm_source, utm_medium, utm_campaign
order by visit_date, visitors_count desc,utm_source, utm_medium, utm_campaign;


*топ-15 записей по purchases_count*

with tab as (
    select
        s.visitor_Id,
        TO_CHAR(visit_date, 'YYYY-MM-DD') as visit_date,
        source as utm_source,
        medium as utm_medium,
        campaign as utm_campaign,
        lead_id,
        created_at,
        amount,
        closing_reason,
        status_id,
        COALESCE(vk.daily_spent, 0) as vk_ads_daily_spent,
        COALESCE(ya.daily_spent, 0) as ya_ads_daily_spent,
        COALESCE(vk.daily_spent, 0) + COALESCE(ya.daily_spent, 0) as total_cost,
        case when closing_reason = 'Успешная продажа' then 1 end as purchases_count,
        row_number() over (partition by lead_id order by visit_date desc) as rn
    from sessions s
    left join leads l on s.visitor_Id = l.visitor_id
    left join vk_ads vk on 
    	DATE_TRUNC('day', s.visit_date) = DATE_TRUNC('day', vk.campaign_date) and
    	s.source = vk.utm_source and
    	s.medium = vk.utm_medium and 
    	s.campaign = vk.utm_campaign
	left join ya_ads ya on 
    	DATE_TRUNC('day', s.visit_date) = DATE_TRUNC('day', ya.campaign_date) and
    	s.source = ya.utm_source and
    	s.medium = ya.utm_medium and 
    	s.campaign = ya.utm_campaign
    where s.medium <> 'organic'
),
	tab2 as 
        (select * from tab where rn = 1)
    select
	visit_date,
	utm_source,
    utm_medium,
    utm_campaign,
    COUNT(visitor_id) as visitors_count,
    SUM(total_cost) as total_cost,
    COUNT(lead_id) as leads_count,
    SUM(purchases_count) as purchases_count,
    SUM(amount) as revenue
from tab2
group by visit_date, utm_source, utm_medium, utm_campaign
order by purchases_count desc NULLS last
limit 15;
