--1 �������
--� ����� ������� ������ ������ ���������?

select city as "�����"
from airports 
group by city--��������� ������� airports �� �������
having count(*)>1--������ ������ �� ������, ���������� ����� �� ������� ����� 1

--2 �������
--� ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?

select r.departure_airport ,r.departure_airport_name --������ ���������, ������ �������� �������� � ������������ ����������
from routes r 
where r.aircraft_code = 
		(select aircraft_code--������ ������� � ������������ ���������� ��������
		from aircrafts
		where "range" = (select max("range")--������ ������������ ��������� ��������
		from aircrafts a
		) )
group by r.departure_airport ,r.departure_airport_name
order by r.departure_airport_name 

--3 �������
--������� 10 ������ � ������������ �������� �������� ������

select f.flight_id, f.flight_no, f.departure_airport_name, f.arrival_airport_name, f.scheduled_departure, f.actual_departure,
f.actual_departure - f.scheduled_departure as "delay_time"-- �������� ����� �������� ������, ������� ����������� ����� ������ �� ������������
from flights_v f 
where f.actual_departure is not null--�������� ������ ���������� ������������ �����
order by delay_time desc--�������� �� ������� �������� �� �������� � ��������
limit 10--������� 10 ������ � ����. �������� �������� ������

--4 �������
--���� �� �����, �� ������� �� ���� �������� ���������� ������?

select t.book_ref as "����� ��� ���������� �������"
from  tickets t
left join boarding_passes bp on (bp.ticket_no=t.ticket_no)--��������� ����� ����� ����� ����������� ��� ������ �� ������� (� ���������� ���������� ������, � ���������� �������)
where bp.boarding_no is null--�������� ������ �� ������, ��� �� �������� ���������� ������
group by t.book_ref--��������� �� ������� �����

--5 �������
--������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
--�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ����������
-- �� ������� ��������� �� ������ ����.
-- �.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� �������
-- ��������� �� ���� ��� ����� ������ ������ �� ����.


--������� 5 ������� (��������� ������� flights)
---------------------------------------
select t.flight_no as "����� �����", t.departure_airport as "��� ��������� �����������", 
a.airport_name as "����� ���������", t.actual_departure as  "����������� ����� �����������",
all_seat-"count" as "��������� �����",  round((all_seat-"count")::numeric /all_seat*100, 2) as "% ��������� ���� � ������ ���-�� ����",
sum("count") over (partition by t.departure_airport, t.actual_departure::date order by t.actual_departure)
	as "������������, ����� ���������� ����������" --������� �������, ��������������� �� ����(��� �������),������������ ������������� ���� �� ������ ���� 
from
(select f.flight_id , f.flight_no ,f.aircraft_code , f.departure_airport, f.actual_departure , f.status , count(bp.seat_no)
from flights f 
join ticket_flights tf ON tf.flight_id =f.flight_id --�������� ������� ������ � �������� �����-���� �� flight_id (������������� �����)
left join boarding_passes bp on (bp.ticket_no=tf.ticket_no) and (bp.flight_id = tf.flight_id ) --�������� ������� �� ������� boarding_passes �� �������� � ������� ������(ticket_no) � ������� �����(flight_id), ����� ���������� ����� ���������� �����.
where f.actual_departure is not null-- ������ ����������� �����, ����� � ���� ����� ������ ����
group by f.flight_id) as t--��������� ������� ���������� ������� ���� ��� ������� �����
join (select s.aircraft_code , count(*) as "all_seat"
	from seats s               --��������� ������� ����� ���������� ���������� ���� �� ����� ���������
	group by s.aircraft_code) sf on sf.aircraft_code =t.aircraft_code
join airports a on a.airport_code = t.departure_airport --�������� ������� �� ������� airports, ����� �������� ������� � ������� ���������
----------------------------------------------------

--������� 5 ������� (��������� ������������� flights_v)
select t.flight_no as "����� �����", t.departure_airport as "��� ��������� �����������", 
t.arrival_airport_name as "����� ���������", t.actual_departure as  "����������� ����� �����������",
all_seat-"count" as "��������� �����",  round((all_seat-"count")::numeric /all_seat*100, 2) as "% ��������� ���� � ������ ���-�� ����",
sum("count") over (partition by t.departure_airport, t.actual_departure::date order by t.actual_departure)
	as "������������, ����� ���������� ����������"  --������� �������, ��������������� �� ����(��� �������),������������ ������������� ���� �� ������ ���� 
from
(select f.flight_id , f.flight_no ,f.aircraft_code , f.departure_airport, f.arrival_airport_name, f.actual_departure , f.status , count(bp.seat_no)
from flights_v f 
join ticket_flights tf ON tf.flight_id =f.flight_id --�������� ������� ������ � �������� �����-���� �� flight_id (������������� �����)
left join boarding_passes bp on (bp.ticket_no=tf.ticket_no) and (bp.flight_id = tf.flight_id ) --�������� ������� �� ������� boarding_passes �� �������� � ������� ������(ticket_no) � ������� �����(flight_id), ����� ���������� ����� ���������� �����.
where f.actual_departure is not null-- ������ ����������� �����, ����� � ���� ����� ������ ����
group by f.flight_id , f.flight_no ,f.aircraft_code , f.departure_airport, f.arrival_airport_name, f.actual_departure , f.status) as t--��������� ������� ���������� ������� ���� ��� ������� �����
join (select s.aircraft_code , count(*) as "all_seat"
	from seats s               --��������� ������� ����� ���������� ���������� ���� �� ����� ���������
	group by s.aircraft_code) sf on sf.aircraft_code =t.aircraft_code
	

--6 �������
--������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.
	
select f.aircraft_code as "��� ��������" , a.model as "������ ��������",
	round(count(*)::numeric/(select count(*) from flights f )*100,2) --��������� � ����������� ������������ ����� ���-�� ���������
	as "% ��������� �� ����� ��������� �� ������ ����������"
from flights f
join aircrafts a on a.aircraft_code =f.aircraft_code 
group by f.aircraft_code, a.model --��������� �������� �� ����� ��������� ��� �������� ���������� ��������� �� �����
order by round(count(*)::numeric/(select count(*) from flights f )*100,2) desc--�������� �� �������� ��������

--7 �������
--���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?

select fv.arrival_city
from flights_v fv 
join
(with cte1 as
	(select tf.flight_id , max(tf.amount) as "max_econom"
	from ticket_flights tf  
	where tf.fare_conditions = 'Economy'
	group by tf.flight_id),--cte1 ������� ������������ ���� ������ ������-������ �� �����
cte2 as 
	(select tf.flight_id , min(tf.amount) as "min_business"
	from ticket_flights tf   
	where tf.fare_conditions = 'Business'
	group by tf.flight_id) --cte2 ������� ������������ ���� ������ ������-������ �� �����
select *
from cte1
join cte2 using(flight_id)
where min_business < max_econom) as t
on fv.flight_id = t.flight_id --��������� ��� ���������� cte �� ���� flight_id � ������� ��� ���. ���� ������-������ ������ ����. ���� ������-������ �� �����
group by fv.arrival_city--��������� �� ������ ��������
order by fv.arrival_city --�������� �� ������ ��������



--8 �������
--����� ������ �������� ��� ������ ������?

create view list_of_cities as--������ ������������� �� ������� ���������� ������� ����������
select fv.departure_city  as "�����"
from flights_v fv 
union 
select fv.arrival_city  
from flights_v fv

create view table_city_dep_city_arr as--������ ������������� �� ������� ���������� ��������� ����� ��������
select distinct r.departure_city , r.arrival_city 
from routes r 

select loc1."�����" as "�����1", loc2."�����" as "�����2"
from list_of_cities loc1, list_of_cities loc2-- ��������� ������������ ���� ������� ����������
where loc1."�����" !=loc2."�����"--�������� ����� �� ������ � ������ ����
except --������� ������������ �����
select *
from table_city_dep_city_arr
order by 1,2

--9 �������
--��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ ����������
-- ���������  � ���������, ������������� ��� ����� *

--������� � distinct (distinct ����������� ��� ��������� ���������� �������� �������� �����������-�������� ��������)
select distinct r.departure_airport , r.departure_airport_name, r.arrival_airport ,
r.arrival_airport_name, r.aircraft_code,
round(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude))*6371)  as "���������� (��)",
a3."range" as "��������� (��)", 
case
		when "range" > acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude))*6371 then '�������'
		else '����������'
	end
from routes r 
join airports a on a.airport_code =r.departure_airport--
join airports a2 on a2.airport_code =r.arrival_airport
join aircrafts a3 on a3.aircraft_code =r.aircraft_code
--������� sind, cosd ������������, ��� ��� ������ � ������� � ���� ������� � ��������
--��������� 6371 - ������ ����� � ��.
	
--������� � group by
select r.departure_airport , r.departure_airport_name, r.arrival_airport ,
r.arrival_airport_name, r.aircraft_code,
round(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude))*6371)  as "���������� (��)",
a3."range" as "��������� (��)", 
case
		when "range" > acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude))*6371 then '�������'
		else '����������'
	end
from routes r 
join airports a on a.airport_code =r.departure_airport
join airports a2 on a2.airport_code =r.arrival_airport
join aircrafts a3 on a3.aircraft_code =r.aircraft_code
group by r.departure_airport , r.departure_airport_name, r.arrival_airport ,
r.arrival_airport_name, r.aircraft_code, a.latitude, a2.latitude, a.longitude, a2.longitude, a3."range"
order by r.departure_airport 

