--1 задание
--В каких городах больше одного аэропорта?

select city as "Город"
from airports 
group by city--группирую таблицу airports по городам
having count(*)>1--вывожу только те города, количество строк по которым более 1

--2 задание
--В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

select r.departure_airport ,r.departure_airport_name --вывожу аэропорты, откуда вылетают самолеты с максимальной дальностью
from routes r 
where r.aircraft_code = 
		(select aircraft_code--нахожу самолет с максимальной дальностью перелета
		from aircrafts
		where "range" = (select max("range")--нахожу максимальную дальность перелета
		from aircrafts a
		) )
group by r.departure_airport ,r.departure_airport_name
order by r.departure_airport_name 

--3 задание
--Вывести 10 рейсов с максимальным временем задержки вылета

select f.flight_id, f.flight_no, f.departure_airport_name, f.arrival_airport_name, f.scheduled_departure, f.actual_departure,
f.actual_departure - f.scheduled_departure as "delay_time"-- вычисляю время задержки вылета, вычитая планируемое время вылета из фактического
from flights_v f 
where f.actual_departure is not null--оставляю только фактически отправленные рейсы
order by delay_time desc--сортирую по времени задержки от большего к меньшему
limit 10--получаю 10 рейсов с макс. временем задержки вылета

--4 задание
--Были ли брони, по которым не были получены посадочные талоны?

select t.book_ref as "Брони без посадочных талонов"
from  tickets t
left join boarding_passes bp on (bp.ticket_no=t.ticket_no)--использую левый джойн чтобы подтянулись все данные по билетам (и полученные посадочные талоны, и отсутствие таковых)
where bp.boarding_no is null--оставляю только те строки, где не получены посадочные талоны
group by t.book_ref--группирую по номерам брони

--5 задание
--Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров
-- из каждого аэропорта на каждый день.
-- Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного
-- аэропорта на этом или более ранних рейсах за день.


--решение 5 задания (используя таблицу flights)
---------------------------------------
select t.flight_no as "номер рейса", t.departure_airport as "код аэропорта отправления", 
a.airport_name as "город аэропорта", t.actual_departure as  "фактическое время отправления",
all_seat-"count" as "свободные места",  round((all_seat-"count")::numeric /all_seat*100, 2) as "% свободных мест к общему кол-ву мест",
sum("count") over (partition by t.departure_airport, t.actual_departure::date order by t.actual_departure)
	as "Накопительно, сумма вывезенных пассажиров" --оконная функция, отсортированная по дате(без времени),подсчитывает накопительный итог за каждый день 
from
(select f.flight_id , f.flight_no ,f.aircraft_code , f.departure_airport, f.actual_departure , f.status , count(bp.seat_no)
from flights f 
join ticket_flights tf ON tf.flight_id =f.flight_id --соединяю таблицу рейсов с таблицей билет-рейс по flight_id (идентификатор рейса)
left join boarding_passes bp on (bp.ticket_no=tf.ticket_no) and (bp.flight_id = tf.flight_id ) --обогащаю данными из таблицы boarding_passes по колонкам с номером билета(ticket_no) и номером рейса(flight_id), чтобы однозначно найти посадочный талон.
where f.actual_departure is not null-- убираю планируемые рейсы, чтобы в итог попал только факт
group by f.flight_id) as t--подзапрос выводит количество занятых мест для каждого рейса
join (select s.aircraft_code , count(*) as "all_seat"
	from seats s               --подзапрос выводит общее количество посадочных мест по типам самолетов
	group by s.aircraft_code) sf on sf.aircraft_code =t.aircraft_code
join airports a on a.airport_code = t.departure_airport --обогащаю данными из таблицы airports, чтобы получить колонку с городом аэропорта
----------------------------------------------------

--решение 5 задания (используя представление flights_v)
select t.flight_no as "номер рейса", t.departure_airport as "код аэропорта отправления", 
t.arrival_airport_name as "город аэропорта", t.actual_departure as  "фактическое время отправления",
all_seat-"count" as "свободные места",  round((all_seat-"count")::numeric /all_seat*100, 2) as "% свободных мест к общему кол-ву мест",
sum("count") over (partition by t.departure_airport, t.actual_departure::date order by t.actual_departure)
	as "Накопительно, сумма вывезенных пассажиров"  --оконная функция, отсортированная по дате(без времени),подсчитывает накопительный итог за каждый день 
from
(select f.flight_id , f.flight_no ,f.aircraft_code , f.departure_airport, f.arrival_airport_name, f.actual_departure , f.status , count(bp.seat_no)
from flights_v f 
join ticket_flights tf ON tf.flight_id =f.flight_id --соединяю таблицу рейсов с таблицей билет-рейс по flight_id (идентификатор рейса)
left join boarding_passes bp on (bp.ticket_no=tf.ticket_no) and (bp.flight_id = tf.flight_id ) --обогащаю данными из таблицы boarding_passes по колонкам с номером билета(ticket_no) и номером рейса(flight_id), чтобы однозначно найти посадочный талон.
where f.actual_departure is not null-- убираю планируемые рейсы, чтобы в итог попал только факт
group by f.flight_id , f.flight_no ,f.aircraft_code , f.departure_airport, f.arrival_airport_name, f.actual_departure , f.status) as t--подзапрос выводит количество занятых мест для каждого рейса
join (select s.aircraft_code , count(*) as "all_seat"
	from seats s               --подзапрос выводит общее количество посадочных мест по типам самолетов
	group by s.aircraft_code) sf on sf.aircraft_code =t.aircraft_code
	

--6 задание
--Найдите процентное соотношение перелетов по типам самолетов от общего количества.
	
select f.aircraft_code as "код самолета" , a.model as "модель самолета",
	round(count(*)::numeric/(select count(*) from flights f )*100,2) --подзапрос в знаменателе подсчитывает общее кол-во перелетов
	as "% перелетов по типам самолетов от общего количества"
from flights f
join aircrafts a on a.aircraft_code =f.aircraft_code 
group by f.aircraft_code, a.model --группирую перелеты по типам самолетов для подсчета количества перелетов по типам
order by round(count(*)::numeric/(select count(*) from flights f )*100,2) desc--сортирую по убыванию значения

--7 задание
--Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?

select fv.arrival_city
from flights_v fv 
join
(with cte1 as
	(select tf.flight_id , max(tf.amount) as "max_econom"
	from ticket_flights tf  
	where tf.fare_conditions = 'Economy'
	group by tf.flight_id),--cte1 выводит максимальную цену билета эконом-класса по рейсу
cte2 as 
	(select tf.flight_id , min(tf.amount) as "min_business"
	from ticket_flights tf   
	where tf.fare_conditions = 'Business'
	group by tf.flight_id) --cte2 выводит минимальныую цену билета бизнес-класса по рейсу
select *
from cte1
join cte2 using(flight_id)
where min_business < max_econom) as t
on fv.flight_id = t.flight_id --объединяю две полученные cte по полю flight_id и условию что мин. цена бизнес-класса меньше макс. цены эконом-класса по рейсу
group by fv.arrival_city--группирую по городу прибытия
order by fv.arrival_city --сортирую по городу прибытия



--8 задание
--Между какими городами нет прямых рейсов?

create view list_of_cities as--создаю представление со списком уникальных городов аэропортов
select fv.departure_city  as "Город"
from flights_v fv 
union 
select fv.arrival_city  
from flights_v fv

create view table_city_dep_city_arr as--создаю представление со списком уникальных сообщений между городами
select distinct r.departure_city , r.arrival_city 
from routes r 

select loc1."Город" as "Город1", loc2."Город" as "Город2"
from list_of_cities loc1, list_of_cities loc2-- декартово произведение всех городов аэропортов
where loc1."Город" !=loc2."Город"--исключаю рейсы из города в самого себя
except --вычитаю существующие рейсы
select *
from table_city_dep_city_arr
order by 1,2

--9 задание
--Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью
-- перелетов  в самолетах, обслуживающих эти рейсы *

--вариант с distinct (distinct использован для получения уникальных значений аэропорт отправления-аэропорт прибытия)
select distinct r.departure_airport , r.departure_airport_name, r.arrival_airport ,
r.arrival_airport_name, r.aircraft_code,
round(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude))*6371)  as "Расстояние (км)",
a3."range" as "Дальность (км)", 
case
		when "range" > acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude))*6371 then 'долетит'
		else 'разобъется'
	end
from routes r 
join airports a on a.airport_code =r.departure_airport--
join airports a2 on a2.airport_code =r.arrival_airport
join aircrafts a3 on a3.aircraft_code =r.aircraft_code
--функции sind, cosd использованы, так как широта и долгота в базе указаны в градусах
--множитель 6371 - радиус Земли в км.
	
--вариант с group by
select r.departure_airport , r.departure_airport_name, r.arrival_airport ,
r.arrival_airport_name, r.aircraft_code,
round(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude))*6371)  as "Расстояние (км)",
a3."range" as "Дальность (км)", 
case
		when "range" > acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude))*6371 then 'долетит'
		else 'разобъется'
	end
from routes r 
join airports a on a.airport_code =r.departure_airport
join airports a2 on a2.airport_code =r.arrival_airport
join aircrafts a3 on a3.aircraft_code =r.aircraft_code
group by r.departure_airport , r.departure_airport_name, r.arrival_airport ,
r.arrival_airport_name, r.aircraft_code, a.latitude, a2.latitude, a.longitude, a2.longitude, a3."range"
order by r.departure_airport 

