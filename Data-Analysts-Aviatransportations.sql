
-- ������ �1
-- � ����� ������� ������ ������ ���������? 
/* ������ �������:
   �������� �� ������� airports ������, � ������� ��������� ������ ������ ���������.
   ��� ����� ������ ����������� �� �������, �������� count() ��������� ����������
   ���������� � ������ ������, �������� ������, ��� count() > 1 */

SELECT a.city, count(a.airport_code) as "���������� ����������"
FROM airports a
GROUP BY a.city
HAVING count(a.airport_code) > 1
ORDER BY a.city;


-- ������ �2
-- � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?
-- ���������� ������������ ���������.
/* ������ �������:
	��� ������� ���������� 3 �������: ��������� (flights), ���������� (airports), ��������� (aircrafts).
����������� �� ������� aircrafts �������� ������� � ������������ ���������� ��������.
� �������� ������� ������������ � ������� flights ������� airports �� ����� ��������� ������ � ��������� �������. ������������ ������� aircrafts �� ���� ��������. 
��������� ���������� ������� �� ���� �������� � ������������ ���������� �������� (�� ����������).
��������� ����������� �� ���� ���������.
��������� �� ������������ ���������.
������� ���������� ������ ����������. */

SELECT 
     a.airport_name || '(' ||a.airport_code ||')' as airport
FROM flights f
JOIN airports a ON a.airport_code = f.departure_airport OR a.airport_code = f.arrival_airport
JOIN aircrafts a2 ON a2.aircraft_code = f.aircraft_code 
WHERE f.aircraft_code = (
       SELECT ac.aircraft_code
       FROM aircrafts ac
       ORDER BY ac."range" DESC
       limit 1
       )
GROUP BY a.airport_code 
ORDER BY a.airport_name;


-- ������ �3
-- ������� 10 ������ � ������������ �������� �������� ������. 
-- ���������� ������������ �������� LIMIT.
/* ������ �������:
	��� ������� ���������� ������� ��������� (flights).
�� ������� flights ������� ����� ����� � ����� �������� ������ 
(�������� ����� ���������� �������� ������ � �������� ������ �� ����������) 
��� ������ �� �������� 'Arrived' ��� 'Departed'.
��������� ���������� �� ������� �������� ������ (�� ��������).
���������� LIMIT ������� ������ 10 ����� � ������������ �������� ��������. */

SELECT flight_no, 
	actual_departure - scheduled_departure AS flight_delay
FROM flights
WHERE status = 'Arrived' OR status = 'Departed'
ORDER BY flight_delay DESC
LIMIT 10;



-- ������ �4
-- ���� �� �����, �� ������� �� ���� �������� ���������� ������?
-- ���������� ������������ ������ ��� JOIN.
/* ������ �������:
	��� ������� ���������� 2 �������: ������� (tickets) � ���������� ������� (boarding_passes).
��� ��� � ������� tickets ���� ����� �����, ������������ � ������� tickets 
���������� LEFT JOIN ������� boarding_passes �� ������ ������.
��������� ���������� �������, ������� ������ ������ �� ��������� NULL 
��� ������ ����������� ������.
�� �������� ������� ������� ���������� ������ �����, �� ������� �� ���� �������� ���������� ������. */

SELECT DISTINCT t.book_ref, bp.boarding_no
FROM tickets t
LEFT JOIN boarding_passes bp ON bp.ticket_no = t.ticket_no
WHERE bp.boarding_no IS NULL;


-- ������ �5
/* ������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� 
�� ������� ��������� �� ������ ����. �.�. � ���� ������� ������ ���������� ������������� ����� - 
������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ �� ����.
   � ������� ���������� ������������ ������� �������, ���������� ��� CTE.
������ �������:
	��� ������� ���������� 3 �������: ����� (flights), ���������� ������ (boarding_passes), 
����� � �������� (seats).
������� CTE seats_count, � ������� ���������� ����� ���������� ���������� ���� all_seats 
��� ������� ���� ��������. 
� �������� ������� ������������ � ������� (flights) ������� ���������� ������� (boarding_passes) 
� ������� CTE seats_count.
��� ��� ��������� ���������� ���������� ��� ���������� ����������, ���������� WHERE ��������� 
������ ���������� ������� �� ������� ����� ('Arrived' ��� 'Departed').
��������� ����������� �� flight_id � all_seats.
������� ��� ������� �������� ���������� ��������� ���� � �������� (available_seats) = (all_seats) -  (boarding_no).
��������� (percent_available_seats) - % ��������� ��������� ���� � ������ ���������� ���� � ��������.
� �������������� ������� ������� � SUM() ��������� ������� (sum_passengers) - ������������� ����
���������� ���������� ���������� (departure_passengers) �� ������� ��������� ������ (departure_airport)
�� ������ ���� ������ (departupe_date).
��������� ���������� ������ � �������� ������� �� ��������� � ���� ������.
.*/

WITH seats_count AS (
	SELECT aircraft_code, count(seat_no) AS all_seats
	FROM seats
	GROUP BY aircraft_code
)
SELECT f.flight_id, 
	sc.all_seats - count(bp.boarding_no) as available_seats,
	ROUND((sc.all_seats - count(bp.boarding_no)) / sc.all_seats::numeric * 100, 2) AS percent_available_seats,
	f.departure_airport, 
	f.actual_departure,
	count(bp.boarding_no),
	sum(count(bp.boarding_no)) OVER(partition by f.departure_airport, f.actual_departure::date 
	order by count(bp.boarding_no), f.actual_departure) as sum_passengers
from flights f
join boarding_passes bp on bp.flight_id = f.flight_id
join seats_count sc on sc.aircraft_code = f.aircraft_code 
WHERE f.status = 'Arrived' OR f.status = 'Departed'
group by f.flight_id, sc.all_seats
order by f.departure_airport, f.actual_departure::date;



-- ������ �6
-- ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.
-- ���������� ������������ ���������, �������� ROUND.
/* ������ �������:
	��� ������� ���������� 2 �������: ��������� (flights) � ��������� (aircrafts). 
� ���������� ���������� �� ������� flights ��� ������� ���� �������� ���������� ��������� (aircraft_flights)
� ����� ���������� ��������� (sum_flights).
����� � ���������� ������� ������������ ������� aircrafts � ������� ��� ������� ���� ��������� 
���������� ��������� � �� ���������� ����������� �� ������ ���������� ��������� (percent_flights). */


SELECT a.model AS aircraft_type, 
	t.aircraft_flights, 
	ROUND(t.aircraft_flights / t.sum_flights * 100, 2) AS percent_flights
FROM (
	SELECT aircraft_code, 
		count(*) AS aircraft_flights,
		SUM(count(*)) over() AS sum_flights
	FROM flights f
	GROUP BY aircraft_code
) t 
JOIN aircrafts a on a.aircraft_code = t.aircraft_code	
ORDER BY percent_flights;


-- ������ �7
-- ���� �� ������, � ������� �����  ��������� ������ - ������� �������, 
-- ��� ������-������� � ������ ��������?
-- ���������� ������������ CTE.
/* ������ �������:
	��� ������� ���������� 3 �������: �������_��������� (ticket_flights), 
��������� (flights), ���������� (airports).
������� 2 CTE, � ������� ���������� �� ������� ticket_flights ��� ������� ��������: 
� CTE1 - ����������� ��������� �������� ������-�������;
� CTE2 - ������������ ��������� �������� ������-�������.
����� � �������� ������� � CTE2 ������������ (���������� JOIN) CTE1 �� �������������� �����,
������������ ������� flights �� �������������� �����, � ������� airports �� ���� ��������� 
� ��������� ������� ������� flights.
���������� ������� ��������� �� �������: ��������� �������� ������-������� ������ 
��������� �������� ������-������� � ������� ������ �������, � ������� ����� ��������� 
������-������� �������, ��� ������-������� � ������ ��������.
� ���������� ���������� ������ �������, ������������� ����� ������� ���. */

WITH cte1 AS (
	SELECT tf.flight_id, MIN(tf.amount) as amount
	FROM ticket_flights tf
	WHERE tf.fare_conditions = 'Business'
	GROUP BY tf.flight_id
), cte2 AS (
	SELECT tf.flight_id, MAX(tf.amount) AS amount
	FROM ticket_flights tf
	WHERE tf.fare_conditions = 'Economy'
	GROUP BY tf.flight_id
)
SELECT a.city 
FROM cte2
JOIN cte1 ON cte1.flight_id = cte2.flight_id
JOIN flights f ON f.flight_id = cte2.flight_id
JOIN airports a ON a.airport_code = f.arrival_airport
WHERE cte2.amount > cte1.amount; 



-- ������ �8
-- ����� ������ �������� ��� ������ ������?
-- ���������� ������������: ��������� ������������ � ����������� FROM, �������������� ��������� 
-- �������������, �������� EXCEPT.
/* ������ �������:
	��� ������� ���������� 2 �������: ��������� (flights) � ���������� (airports). 
������� ������������� city_flight_direct, ��������� ������, ����� �������� ���� ������ �����.
��� ����� ���������� ��������� ������������ ������� ������ � ������� �� ������ flights � airports,
��� �������, ��� ��� ��������� ������ � ������� flights ����� ���� ��������� � ������� airports �
��� ��������� ������� � ������� flights ����� ���� ��������� � ������� airports.
������� ������������� city_flight, ��������� ��� ��������� ��������� ������� �� ������� airports,
� ��������� ������ � ����������� ��������.
� �������� ������� �� ����������� ������������� city_flight ���������� EXCEPT ��������� ����������
������������� city_flight_direct.
��������� ���������� ��������� - ������, ����� �������� ��� ������ ������.  */

CREATE VIEW city_flight_direct AS
	SELECT DISTINCT  
    	dep.city AS departure_city,
    	arr.city AS arrival_city
	FROM flights f, airports dep, airports arr
	WHERE f.departure_airport = dep.airport_code AND f.arrival_airport = arr.airport_code;

CREATE VIEW city_flight AS
	SELECT  
    	a1.city AS dep_city,
    	a2.city AS arr_city
	FROM airports a1, airports a2
	WHERE a1.city != a2.city;

SELECT * FROM city_flight
EXCEPT 
SELECT * from city_flight_direct
ORDER BY dep_city, arr_city;



-- ������ �9
-- ��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� 
-- ������������ ���������� ��������� � ���������, ������������� ��� �����.
-- ���������� ������������: �������� RADIANS ��� sind/cosd, �������� CASE.
/* ������ �������:
	��� ������� ���������� 3 �������: ��������� (flights), ���������� (airoports), 
��������� (aircrafts). 
� ���������� �������� ������� ����������, ��������� ������� �������, 
� ���������� ���������� ����� ����� ����������� (distance) �� �������, ����������� � �������.
�����, � �������� �������, ������������ � ���������� ������� ������� aircrafts � ������� 
������� note, � ������� ���������� ���������� ����� ����������� � ���������� 
������������ ��������� ��������� � ���������, ������������� ��� �����.
��������� �������� ������� �� ������� ������ � �������.
*/


SELECT t.departure_city, t.arrival_city, t.distance, 
	CASE
		WHEN a."range" > t.distance THEN '�������'
		ELSE '�� �������' 
	END as note
FROM (
	SELECT DISTINCT   
		dep.city AS departure_city,
		arr.city AS arrival_city,
		f.aircraft_code,
		ROUND((acos(sin(RADIANS(dep.latitude)) * sin(RADIANS(arr.latitude)) + 
		cos(RADIANS(dep.latitude)) * cos(RADIANS(arr.latitude)) * 
		cos(RADIANS(arr.longitude - dep.longitude))) * 6371)::numeric, 2) AS distance
	FROM flights f, airports dep, airports arr
	WHERE f.departure_airport = dep.airport_code AND f.arrival_airport = arr.airport_code
) t 
LEFT JOIN aircrafts a ON a.aircraft_code = t.aircraft_code
ORDER BY t.departure_city, t.arrival_city;

 






















