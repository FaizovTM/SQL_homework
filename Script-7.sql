
1. В каких городах больше одного аэропорта?

select a.city, count (*) as "Количество аэрпортов" -- считаем общее количество аэропортов
from airports a -- исользуем таблицу аэропорты
group by a.city -- группируем для группировки
having count(*) > 1 -- ставим оператор для выбора конкретных строк которые имеет значение больше одного

2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

select a.airport_name -- выводим названия аэропортов
from airports a 
join flights f on f.departure_airport = a.airport_code -- соединяем полеты с кодами аэропорта
cross join(
	select max (range)
	from aircrafts) as t -- выполняем соединение для всех возможных сочетаний строк  
join aircrafts a2 on f.aircraft_code = a2.aircraft_code -- соединяем коды самолетов 
where range = max -- ставим условие что дальность полета должна быть максимальна
group by a.airport_name -- группируем для группировки

3. Вывести 10 рейсов с максимальным временем задержки вылета

select flight_no
from (
	select flights.flight_no, (actual_departure - scheduled_departure) as r -- находим разность вылета планированного и фактического, для получения положительного результат отнимает фактическое время от планированного
	from flights 
	where (actual_departure - scheduled_departure) is not null -- ставим условие чтобы разность не имела пустых значений, т.к. есть рейсы которые вылетели без задержек
	order by r desc -- сортируем по от обратного, для получения наибольших значения
) f
limit 10 -- устанавливаем лимит 10 строк

4. Были ли брони, по которым не были получены посадочные талоны?

select b.book_ref, bp.ticket_no -- запрашиваем номера брони и номера билетов
from bookings b 
full join tickets t on t.book_ref = b.book_ref -- соединяем все номера бронирований 
full join boarding_passes bp on bp.ticket_no = t.ticket_no -- соединяем полностью  № билетов 
where bp.ticket_no is null -- ставим условие где есть занчение null
group by b.book_ref, bp.ticket_no -- группировка для группировки
order by bp.ticket_no desc -- сортировка в обратную сторону

5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта 
на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело 
из данного аэропорта на этом или более ранних рейсах в течении дня.

6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.

select a.model, count(a.s) as "Колличество перелетов", sum(count(a.s)) over () as "Общая сумма перелетов", 
	round (count(a.s)::numeric * 100 / sum(count(a.s)) over ()::numeric, 2)
from(
	select a.model, -- создаем подзапрос для подсчета всех рейсов всех самолетов
		count(f.flight_id) over (order by a.model) as s
	from aircrafts a 
	join flights f on a.aircraft_code = f.aircraft_code -- соединяем код самолета с рейсов и самолетов
) a 
group by a.model, a.s -- группировка для группировки

7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?

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
cte.amount as "Цена эконом", cte1.amount as "Цена бизнес"
from cte1
join flights f on cte1.flight_id = f.flight_id
join airports a on a.airport_code = f.arrival_airport
join airports a2 on a2.airport_code = f.departure_airport
join cte on cte1.flight_id = cte.flight_id
where cte.amount > cte1.amount
group by a.city, cte1.fare_conditions, a2.city, cte.amount, cte1.amount

8. Между какими городами нет прямых рейсов? 
- Декартово произведение в предложении FROM
- Самостоятельно созданные представления (если облачное подключение, то без представления)
- Оператор EXCEPT

create view city_between_city as -- создаю представление чтобы получить города между которыми есть рейсы
select a.city arrival_airport, a2.city departure_airport 
from flights f 
join airports a on a.airport_code = f.arrival_airport -- соединяю аэропорт кода и аэропорт прибытия
join airports a2 on a2.airport_code = f.departure_airport --соединяю аэропорт кода и аэропорт отправления

select a.city arrival_airport, a2.city departure_airport  -- получаю город отправления и город прибытия
from airports a, airports a2 -- ставлю 2 аэропорта для получения декартового произведения всех городов
where a.city != a2.city -- ставлю условие неравенство 
except -- данным оператором нахожу разность двух запросов
select *
from city_between_city

9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы *
- Оператор RADIANS или использование sind/cosd
- CASE 

select a2.airport_name as "Вылет из", a.airport_name as "Вылет в", a3."range" as "Дальность самолета",
round((acos(sind(a2.latitude) * sind(a.latitude) + cosd(a2.latitude) * cosd(a.latitude) * cosd(a2.longitude - a.longitude))::dec * 6371), 2) as "Расстояние", -- находим по формуле расстояние между аэропортами
	case 
		when a3."range" < acos(sind(a2.latitude) * sind(a.latitude) + cosd(a2.latitude) * cosd(a.latitude) * cosd(a2.longitude - a.longitude)) * 6371 -- ставим условие - дальность самолета, меньше расстояния между аэропортов
		then 'Не долетитт'
		else 'Долетит' 
	end "Результат" 
from flights f 
join airports a on a.airport_code = f.arrival_airport -- присоеднияем код аэропорта с аэропортом прибытия
join airports a2 on a2.airport_code = f.departure_airport -- присоеднияем код аэропорта с аэрпортом отправления
join aircrafts a3 on a3.aircraft_code = f.aircraft_code -- присоединяем коды самолетов из табл. самолетов и полетов

 
