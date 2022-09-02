
-- ЗАПРОС №1
-- В каких городах больше одного аэропорта? 
/* Логика запроса:
   Выбираем из таблицы airports города, в которых находится больше одного аэропорта.
   Для этого делаем группировку по городам, функцией count() вычисляем количество
   аэропортов в каждом городе, выбираем города, где count() > 1 */

SELECT a.city, count(a.airport_code) as "Количество аэропортов"
FROM airports a
GROUP BY a.city
HAVING count(a.airport_code) > 1
ORDER BY a.city;


-- ЗАПРОС №2
-- В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
-- Необходимо использовать подзапрос.
/* Логика запроса:
	Для запроса используем 3 таблицы: перелетов (flights), аэропортов (airports), самолетов (aircrafts).
Подзапросом из таблицы aircrafts выбираем самолет с максимальной дальностью перелета.
В основном запросе присоединяем к таблице flights таблицу airports по кодам аэропорта вылета и аэропорта прилета. Присоединяем таблицу aircrafts по коду самолета. 
Фильтруем полученную таблицу по коду самолета с максимальной дальностью перелета (из подзапроса).
Выполняем группировку по коду аэропорта.
Сортируем по наименованию аэропорта.
Выводим полученный список аэропортов. */

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


-- ЗАПРОС №3
-- Вывести 10 рейсов с максимальным временем задержки вылета. 
-- Необходимо использовать оператор LIMIT.
/* Логика запроса:
	Для запроса используем таблицу перелетов (flights).
Из таблицы flights выводим номер рейса и время задержки вылета 
(разность между актуальным временем вылета и временем вылета по расписанию) 
для рейсов со статусом 'Arrived' или 'Departed'.
Выполняем сортировку по времени задержки вылета (по убыванию).
Оператором LIMIT выводим первые 10 строк с максимальным временем задержки. */

SELECT flight_no, 
	actual_departure - scheduled_departure AS flight_delay
FROM flights
WHERE status = 'Arrived' OR status = 'Departed'
ORDER BY flight_delay DESC
LIMIT 10;



-- ЗАПРОС №4
-- Были ли брони, по которым не были получены посадочные талоны?
-- Необходимо использовать верный тип JOIN.
/* Логика запроса:
	Для запроса используем 2 таблицы: билетов (tickets) и посадочных талонов (boarding_passes).
Так как в таблице tickets есть номер брони, присоединяем к таблице tickets 
оператором LEFT JOIN таблицу boarding_passes по номеру билета.
Фильтруем полученную таблицу, выбирая только строки со значением NULL 
для номера посадочного талона.
Из итоговой таблицы выводим уникальные номера брони, по которым не были получены посадочные талоны. */

SELECT DISTINCT t.book_ref, bp.boarding_no
FROM tickets t
LEFT JOIN boarding_passes bp ON bp.ticket_no = t.ticket_no
WHERE bp.boarding_no IS NULL;


-- ЗАПРОС №5
/* Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров 
из каждого аэропорта на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - 
сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день.
   В запросе необходимо использовать оконную функцию, подзапросы или CTE.
Логика запроса:
	Для запроса используем 3 таблицы: рейсы (flights), посадочные талоны (boarding_passes), 
места в самолете (seats).
Создаем CTE seats_count, в котором определяем общее количество посадочных мест all_seats 
для каждого типа самолета. 
В основном запросе присоединяем к таблице (flights) таблицу посадочных талонов (boarding_passes) 
и таблицу CTE seats_count.
Так как требуется определить количество уже вывезенных пассажиров, оператором WHERE фильтруем 
строки полученной таблицы по статусу рейса ('Arrived' или 'Departed').
Выполняем группировку по flight_id и all_seats.
Выводим для каждого перелета количество свободных мест в самолете (available_seats) = (all_seats) -  (boarding_no).
Вычисляем (percent_available_seats) - % отношение свободных мест к общему количеству мест в самолете.
С использованием оконной функции и SUM() добавляем столбец (sum_passengers) - накопительный итог
количества вывезенных пассажиров (departure_passengers) из каждого аэропорта вылета (departure_airport)
на каждую дату вылета (departupe_date).
Выполняем сортировку данных в итоговой таблице по аэропорту и дате вылета.
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



-- ЗАПРОС №6
-- Найдите процентное соотношение перелетов по типам самолетов от общего количества.
-- Необходимо использовать Подзапрос, оператор ROUND.
/* Логика запроса:
	Для запроса используем 2 таблицы: перелетов (flights) и самолетов (aircrafts). 
В подзапросе определяем из таблицы flights для каждого типа самолета количество перелетов (aircraft_flights)
и общее количество перелетов (sum_flights).
Затем к полученной таблице присоединяем таблицу aircrafts и выводим для каждого типа самолетов 
количество перелетов и их процентное соотношение от общего количества перелетов (percent_flights). */


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


-- ЗАПРОС №7
-- Были ли города, в которые можно  добраться бизнес - классом дешевле, 
-- чем эконом-классом в рамках перелета?
-- Необходимо использовать CTE.
/* Логика запроса:
	Для запроса используем 3 таблицы: билетов_перелетов (ticket_flights), 
перелетов (flights), аэропортов (airports).
Создаем 2 CTE, в которых определяем из таблицы ticket_flights для каждого перелета: 
в CTE1 - минимальную стоимость перелета бизнес-классом;
в CTE2 - максимальную стоимость перелета эконом-классом.
Затем в основном запросе к CTE2 присоединяем (оператором JOIN) CTE1 по идентификатору рейса,
присоединяем таблицу flights по идентификатору рейса, и таблицу airports по коду аэропорта 
и аэропорту прилета таблицы flights.
Полученную таблицу фильтруем по условию: стоимость перелета эконом-классом больше 
стоимости перелета бизнес-классом и выводим список городов, в которые можно добраться 
бизнес-классом дешевле, чем эконом-классом в рамках перелета.
В результате получается пустая таблица, следовательно таких городов нет. */

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



-- ЗАПРОС №8
-- Между какими городами нет прямых рейсов?
-- Необходимо использовать: Декартово произведение в предложении FROM, Самостоятельно созданные 
-- представления, Оператор EXCEPT.
/* Логика запроса:
	Для запроса используем 2 таблицы: перелетов (flights) и аэропортов (airports). 
Создаем представление city_flight_direct, выводящее города, между которыми есть прямые рейсы.
Для этого используем декартово произведение городов вылета и прилета из таблиц flights и airports,
при условии, что код аэропорта вылета в таблице flights равен коду аэропорта в таблице airports и
код аэропорта прилета в таблице flights равен коду аэропорта в таблице airports.
Создаем представление city_flight, выводящее все возможные сочетания городов из таблицы airports,
и исключаем строки с одинаковыми городами.
В итоговом запросе из результатов представления city_flight оператором EXCEPT исключаем результаты
представления city_flight_direct.
Сортируем полученный результат - города, между которыми нет прямых рейсов.  */

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



-- ЗАПРОС №9
-- Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой 
-- максимальной дальностью перелетов в самолетах, обслуживающих эти рейсы.
-- Необходимо использовать: Оператор RADIANS или sind/cosd, Оператор CASE.
/* Логика запроса:
	Для запроса используем 3 таблицы: перелетов (flights), аэропортов (airoports), 
самолетов (aircrafts). 
В подзапросе получаем таблицу аэропортов, связанных прямыми рейсами, 
и определяем расстояние между этими аэропортами (distance) по формуле, приведенной в задании.
Затем, в основном запросе, присоединяем к полученной таблице таблицу aircrafts и выводим 
столбец note, в котором сравниваем расстояние между аэропортами и допустимую 
максимальную дальность перелетов в самолетах, обслуживающих эти рейсы.
Сортируем итоговую таблицу по городам вылета и прилета.
*/


SELECT t.departure_city, t.arrival_city, t.distance, 
	CASE
		WHEN a."range" > t.distance THEN 'Долетит'
		ELSE 'Не долетит' 
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

 






















