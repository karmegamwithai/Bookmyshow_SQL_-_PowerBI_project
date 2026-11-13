-- ============================================================
-- BOOKMYSHOW - SQL BUSINESS ANALYSIS
-- 20 BUSINESS QUESTIONS
-- ============================================================


-- SECTION 1: CUSTOMER ANALYSIS
-- ============================================================

-- Q1. What is the total number of registered users?
-- Write your SQL query below:

select count(name) from users;


-- Q2. How many customers belong to each age group (18-25, 26-35, 36-45, 46+)?
-- Also calculate the percentage of customers in each age group.
-- Write your SQL query below:

WITH userAges AS (
    SELECT
        TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) AS age
    FROM users
),
ageGroups AS (
    SELECT
        CASE
            WHEN age BETWEEN 18 AND 25 THEN '18-25'
            WHEN age BETWEEN 26 AND 35 THEN '26-35'
            WHEN age BETWEEN 36 AND 45 THEN '36-45'
            WHEN age >= 46 THEN '46+'
        END AS age_range
    FROM userAges
    WHERE age >= 18
)
SELECT
    age_range,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),
        2
    ) AS percentage
FROM ageGroups
WHERE age_range IS NOT NULL
GROUP BY age_range
ORDER BY
    CASE age_range
        WHEN '18-25' THEN 1
        WHEN '26-35' THEN 2
        WHEN '36-45' THEN 3
        WHEN '46+' THEN 4
    END;


-- Q3. Who are the repeat customers?
-- Find customers who have made more than 3 bookings.
-- Display user_id, customer name, total bookings, and total tickets booked.
-- Write your SQL query below:

select u.user_id, u.name,count(b.booking_date)as total_bookings,coalesce(sum(b.total_tickets),0) as total_tickets
from users as u
join bookings as b	
	on u.user_id = b.user_id
group by b.user_id,u.name 
having count(b.booking_date) > 3;
    




-- SECTION 2: MOVIE PERFORMANCE ANALYSIS
-- ============================================================

-- Q4. How many movies are available in each genre?
-- Display genre and total movie count.
-- Write your SQL query below:

show tables;
select * from movies;
select genre, count(genre) as total_movie from movies
group by genre
order by total_movie desc;


-- Q5. How many movies are available in each language?
-- Display language and total movie count.
-- Write your SQL query below:

show tables;
select language,count(language) as total_movies from movies
group by language
order by total_movies desc;


-- Q6. What are the top 10 highest-rated movies?
-- Display movie title, genre, language, and rating.
-- Write your SQL query below:

show tables;
select * from movies;
select title,genre,language,rating from movies
order by rating desc
limit 10;


-- Q7. What are the 10 most popular movies based on ticket bookings?
-- Display movie title, total bookings, and total tickets sold.
-- Write your SQL query below:

show tables;
select * from shows;
select * from movies;
select * from bookings;
SELECT 
    m.title, 
    count(b.booking_date) as total_bookings, 
    sum(b.total_tickets) as total_tickets_sold
FROM movies AS m
JOIN shows AS s
    ON s.movie_id = m.movie_id
JOIN bookings AS b
    ON b.show_id = s.show_id
where b.payment_status = "Completed"
	group by m.title
    order by total_bookings desc
    limit 10;


-- Q8. Which movie genres generate the highest revenue?
-- Display genre, total tickets sold, and total revenue.
-- Write your SQL query below:

select m.genre,sum(b.total_tickets) as total_tickets,sum(s.price_per_ticket) as total_revenue
	from movies as m
    join shows as s
		on s.movie_id = m.movie_id
	join bookings as b
		on s.show_id = b.show_id
	where b.payment_status = 'completed'
	group by m.genre;





-- SECTION 3: THEATER AND SHOW ANALYSIS
-- ============================================================

-- Q9. How many theaters are available in each city?
-- Display city, state, and total theater count.
-- Write your SQL query below:

select * from theaters;
select city, state, count(city) as total_theater from theaters
group by city,state
order by total_theater desc;


-- Q10. Which are the top 5 revenue-generating theaters?
-- Display theater name, city, total bookings, tickets sold, and revenue.
-- Write your SQL query below:

select t.name,t.city,count(b.booking_date) as total_bookings,sum(b.total_tickets) as tickets_sold,sum(b.total_tickets*s.price_per_ticket) as total_revenue
	from theaters as t
	join shows as s
		on t.theater_id = s.theater_id
	join bookings as b
		on b.show_id = s.show_id
	group by t.name, t.city;


-- Q11. Which show timings are the most popular?
-- Display show start time, total shows, and total tickets booked.
-- Write your SQL query below:

select s.start_time, count(s.show_date) as total_shows,sum(b.total_tickets) as total_tickets_booked
	from shows as s
    join bookings as b
		on b.show_id = s.show_id
	group by s.start_time
    order by total_shows desc;
    

-- Q12. What is the seat occupancy percentage for each theater?
-- Display theater name, total seats, booked seats, available seats,
-- and occupancy percentage.
-- Write your SQL query below:

show tables;
select * from seats;
select * from shows;
select * from theaters;
select 
	t.name as theater_name,
	count(v.seat_id) as total_seats,
	sum(case when v.status = 'booked' then 1 else 0 end) as booked_seats,
    sum(case when v.status = 'available' then 1 else 0 end) as available_seats,
      ROUND(
        SUM(CASE WHEN v.status = 'booked' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(v.seat_id), 0),
        2
    ) AS occupancy_percentage
from theaters as t
join shows as s
	on t.theater_id = s.theater_id
join seats as v
	on s.screen_id = v.screen_id
group by t.name;


-- Q13. Which are the top 10 shows based on seat occupancy?
-- Display show ID, movie title, theater name, show date,
-- screen capacity, booked seats, and occupancy percentage.
-- Write your SQL query below:

select 
	s.show_id,
    m.title,
    t.name,
    s.show_date,
    sum(p.screen_number) as screen_capacity,
    count(case when v.status = 'booked' then 1 else 0 end) as booked_seats,
	ROUND(
        SUM(CASE WHEN v.status = 'booked' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(v.seat_id), 0),
        2
    ) AS occupancy_percentage
    from shows as s
    join movies as m
		on m.movie_id = s.movie_id
	join theaters as t
		on t.theater_id = s.theater_id
	join screens as p
		on p.screen_id = s.screen_id
	join seats as v
		on v.screen_id = p.screen_id
	group by 
		s.show_id,
		m.title,
		t.name,
		s.show_date;

-- SECTION 4: REVENUE AND PAYMENT ANALYSIS
-- ============================================================

-- Q14. What is the total revenue generated from successful payments?
-- Also calculate total tickets sold and total successful payments.
-- Write your SQL query below:

show tables;
select * from shows;
select * from bookings;
select * from payments;

select sum(b.total_tickets) as total_tickets, sum(b.total_tickets*s.price_per_ticket) as total_successful_payments
	from shows as s
	join bookings as b
		on b.show_id = s.show_id
	join payments as p
		on p.booking_id = b.booking_id
	where p.transaction_status = 'success' and b.payment_status = 'completed';


-- Q15. Which payment methods are most commonly used by customers?
-- Display payment method, transaction status, and transaction count.
-- Write your SQL query below:

select payment_method,transaction_status,count(user_id) as transaction_count from payments
	group by payment_method,transaction_status
    order by transaction_count desc;


-- Q16. What are the monthly booking trends?
-- Display month, total bookings, total tickets booked, and revenue.
-- Write your SQL query below:

show tables;
select * from bookings;
select * from shows;
select monthname(b.booking_date) as months,count(b.user_id) as total_bookings,sum(b.total_tickets)as total_tickets_booked,sum(b.total_tickets*s.price_per_ticket) as revenue
	from bookings as b
    join shows as s
		on b.show_id = s.show_id
	where b.payment_status = 'completed'
	group by months
   ;


-- SECTION 5: CUSTOMER SATISFACTION AND BUSINESS ANALYSIS
-- ============================================================

-- Q17. What is the average customer review rating for each movie?
-- Display movie title, total reviews, and average review rating.
-- Write your SQL query below:

show tables;
select * from movies;
select 
	m.title as movie_title,
    count(r.review_text) as total_reviews,
    avg(m.rating) as avg_review_rating
    from movies as m
	join reviews as r
		on m.movie_id = r.movie_id
	group by movie_title
    order by total_reviews desc;


-- Q18. How does movie popularity compare with customer ratings?
-- Display movie title, total tickets booked, average review rating,
-- and total review count.
-- Write your SQL query below:

select 
	m.title as movie_title,
	sum(b.total_tickets),
    avg(r.rating),
    count(r.review_id)
    from reviews as r
    join bookings as b
		on b.user_id = r.user_id
	join movies as m
		on m.movie_id = r.movie_id
	where b.payment_status = 'completed'
	group by movie_title;


-- Q19. Which cities generate the highest business?
-- Display city, total theaters, total bookings, tickets sold, and revenue.
-- Write your SQL query below:

WITH cte AS (
    SELECT
        user_id,
        show_id,
        total_tickets
    FROM bookings
    WHERE payment_status = 'completed'
)
SELECT
    t.city,
    COUNT(DISTINCT t.theater_id) AS total_theaters,
    COUNT(*) AS total_bookings,
    SUM(c.total_tickets) AS tickets_sold,
    SUM(c.total_tickets * s.price_per_ticket) AS total_revenue
FROM theaters AS t
JOIN shows AS s
    ON t.theater_id = s.theater_id
JOIN cte AS c
    ON s.show_id = c.show_id
GROUP BY t.city
ORDER BY total_revenue DESC;


-- Q20. What is the overall business performance of BookMyShow?
-- Calculate total users, movies, theaters, shows, bookings,
-- tickets sold, successful payments, total revenue,
-- average movie rating, and average seat occupancy.
-- Write your SQL query below:

WITH
user_summary AS (
    SELECT COUNT(*) AS total_users
    FROM users
),

movie_summary AS (
    SELECT
        COUNT(*) AS total_movies,
        ROUND(AVG(rating), 2) AS average_movie_rating
    FROM movies
),

theater_summary AS (
    SELECT COUNT(*) AS total_theaters
    FROM theaters
),

show_summary AS (
    SELECT COUNT(*) AS total_shows
    FROM shows
),

booking_summary AS (
    SELECT
        COUNT(*) AS total_bookings,
        COALESCE(SUM(total_tickets), 0) AS tickets_sold
    FROM bookings
    WHERE payment_status = 'completed'
),

payment_summary AS (
    SELECT COUNT(*) AS successful_payments
    FROM payments
    WHERE transaction_status = 'success'
),

revenue_summary AS (
    SELECT
        COALESCE(
            SUM(b.total_tickets * s.price_per_ticket), 0
        ) AS total_revenue
    FROM bookings AS b
    JOIN shows AS s
        ON b.show_id = s.show_id
    WHERE b.payment_status = 'completed'
),

occupancy_summary AS (
    SELECT
        ROUND(
            SUM(
                CASE
                    WHEN seat.status = 'booked' THEN 1
                    ELSE 0
                END
            ) * 100.0 /
            NULLIF(SUM(sc.total_seats), 0),
            2
        ) AS average_seat_occupancy
    FROM shows AS sh
    JOIN screens AS sc
        ON sh.screen_id = sc.screen_id
    LEFT JOIN seats AS seat
        ON seat.screen_id = sc.screen_id
)

SELECT
    us.total_users,
    ms.total_movies,
    ts.total_theaters,
    ss.total_shows,
    bs.total_bookings,
    bs.tickets_sold,
    ps.successful_payments,
    rs.total_revenue,
    ms.average_movie_rating,
    os.average_seat_occupancy
FROM user_summary AS us
CROSS JOIN movie_summary AS ms
CROSS JOIN theater_summary AS ts
CROSS JOIN show_summary AS ss
CROSS JOIN booking_summary AS bs
CROSS JOIN payment_summary AS ps
CROSS JOIN revenue_summary AS rs
CROSS JOIN occupancy_summary AS os;

    
-- ============================================================
-- END OF BUSINESS ANALYSIS QUESTIONS
-- ============================================================
