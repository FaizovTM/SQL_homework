
1. � ����� ������� ������ ������ ���������?

select a.city, count (*) as "���������� ���������" -- ������� ����� ���������� ����������
from airports a -- ��������� ������� ���������
group by a.city -- ���������� ��� �����������
having count(*) > 1 -- ������ �������� ��� ������ ���������� ����� ������� ����� �������� ������ ������

2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?

select a.airport_name -- ������� �������� ����������
from airports a 
join flights f on f.departure_airport = a.airport_code -- ��������� ������ � ������ ���������
cross join(
	select max (range)
	from aircrafts) as t -- ��������� ���������� ��� ���� ��������� ��������� �����  
join aircrafts a2 on f.aircraft_code = a2.aircraft_code -- ��������� ���� ��������� 
where range = max -- ������ ������� ��� ��������� ������ ������ ���� �����������
group by a.airport_name -- ���������� ��� �����������

3. ������� 10 ������ � ������������ �������� �������� ������

select flight_no
from (
	select flights.flight_no, (actual_departure - scheduled_departure) as r -- ������� �������� ������ �������������� � ������������, ��� ��������� �������������� ��������� �������� ����������� ����� �� ��������������
	from flights 
	where (actual_departure - scheduled_departure) is not null -- ������ ������� ����� �������� �� ����� ������ ��������, �.�. ���� ����� ������� �������� ��� ��������
	order by r desc -- ��������� �� �� ���������, ��� ��������� ���������� ��������
) f
limit 10 -- ������������� ����� 10 �����

4. ���� �� �����, �� ������� �� ���� �������� ���������� ������?

select b.book_ref, bp.ticket_no -- ����������� ������ ����� � ������ �������
from bookings b 
full join tickets t on t.book_ref = b.book_ref -- ��������� ��� ������ ������������ 
full join boarding_passes bp on bp.ticket_no = t.ticket_no -- ��������� ���������  � ������� 
where bp.ticket_no is null -- ������ ������� ��� ���� �������� null
group by b.book_ref, bp.ticket_no -- ����������� ��� �����������
order by bp.ticket_no desc -- ���������� � �������� �������

5. ������� ���������� ��������� ���� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� 
�� ������ ����. �.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� 
�� ������� ��������� �� ���� ��� ����� ������ ������ � ������� ���.

6. ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.

select a.model, count(a.s) as "����������� ���������", sum(count(a.s)) over () as "����� ����� ���������", 
	round (count(a.s)::numeric * 100 / sum(count(a.s)) over ()::numeric, 2)
from(
	select a.model, -- ������� ��������� ��� �������� ���� ������ ���� ���������
		count(f.flight_id) over (order by a.model) as s
	from aircrafts a 
	join flights f on a.aircraft_code = f.aircraft_code -- ��������� ��� �������� � ������ � ���������
) a 
group by a.model, a.s -- ����������� ��� �����������

7. ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?

with 
	cte as (
	select amount, fare_conditions, flight_id
	from ticket_flights
	where fare_conditions = 'Economy'
	group by amount, fare_conditions, flight_id 
	),
	cte1 as (
	select tf.amount, tf.fare_conditions, tf.flight_id
	from ticket_flights tf
	join cte on tf.flight_id = cte.flight_id
	where tf.fare_conditions = 'Business'
	group by tf.amount, tf.fare_conditions, tf.flight_id
	)
select a.city arrival_city, a2.city departure_city, cte1.fare_conditions, 
cte.amount as "���� ������", cte1.amount as "���� ������"
from cte1
join flights f on cte1.flight_id = f.flight_id
join airports a on a.airport_code = f.arrival_airport
join airports a2 on a2.airport_code = f.departure_airport
join cte on cte1.flight_id = cte.flight_id
where cte.amount > cte1.amount
group by a.city, cte1.fare_conditions, a2.city, cte.amount, cte1.amount

8. ����� ������ �������� ��� ������ ������? 
- ��������� ������������ � ����������� FROM
- �������������� ��������� ������������� (���� �������� �����������, �� ��� �������������)
- �������� EXCEPT

create view city_between_city as -- ������ ������������� ����� �������� ������ ����� �������� ���� �����
select a.city arrival_airport, a2.city departure_airport 
from flights f 
join airports a on a.airport_code = f.arrival_airport -- �������� �������� ���� � �������� ��������
join airports a2 on a2.airport_code = f.departure_airport --�������� �������� ���� � �������� �����������

select a.city arrival_airport, a2.city departure_airport  -- ������� ����� ����������� � ����� ��������
from airports a, airports a2 -- ������ 2 ��������� ��� ��������� ����������� ������������ ���� �������
where a.city != a2.city -- ������ ������� ����������� 
except -- ������ ���������� ������ �������� ���� ��������
select *
from city_between_city

9. ��������� ���������� ����� �����������, ���������� ������� �������, 
�������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� ����� *
- �������� RADIANS ��� ������������� sind/cosd
- CASE 

select a2.airport_name as "����� ��", a.airport_name as "����� �", a3."range" as "��������� ��������",
round((acos(sind(a2.latitude) * sind(a.latitude) + cosd(a2.latitude) * cosd(a.latitude) * cosd(a2.longitude - a.longitude))::dec * 6371), 2) as "����������", -- ������� �� ������� ���������� ����� �����������
	case 
		when a3."range" < acos(sind(a2.latitude) * sind(a.latitude) + cosd(a2.latitude) * cosd(a.latitude) * cosd(a2.longitude - a.longitude)) * 6371 -- ������ ������� - ��������� ��������, ������ ���������� ����� ����������
		then '�� ��������'
		else '�������' 
	end "���������" 
from flights f 
join airports a on a.airport_code = f.arrival_airport -- ������������ ��� ��������� � ���������� ��������
join airports a2 on a2.airport_code = f.departure_airport -- ������������ ��� ��������� � ��������� �����������
join aircrafts a3 on a3.aircraft_code = f.aircraft_code -- ������������ ���� ��������� �� ����. ��������� � �������

 
