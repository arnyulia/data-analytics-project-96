"last_paid_click"

with tab as(
select distinct on (s.visitor_id) s.visitor_id, visit_date, source as utm_source, medium as utm_medium, campaign as utm_campaign, 
lead_id, created_at, amount, closing_reason, status_id
from sessions s
left join leads l
on s.visitor_id=l.visitor_id 
where medium <> 'organic'
order by s.visitor_id, visit_date desc) 
select * from tab 
order by visit_date, utm_source, utm_medium, utm_campaign;