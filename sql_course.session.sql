SELECT
    job_schedule_type,
    AVG(salary_year_avg) AS avg_yearly_salary,
    AVG(salary_hour_avg) AS avg_hourly_salary
FROM job_postings_fact
WHERE job_posted_date > '2023-06-01'
GROUP BY job_schedule_type;

SELECT
    EXTRACT(MONTH FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST') AS month,
    COUNT(*) AS postings_count
FROM 
    job_postings_fact
WHERE 
    EXTRACT(YEAR FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST') = 2023
GROUP BY month
ORDER BY month;

SELECT
    company_name,
    job_title
FROM job_postings
WHERE health_insurance = TRUE
  AND EXTRACT(YEAR FROM job_posted_date) = 2023
  AND EXTRACT(QUARTER FROM job_posted_date) = 2;


SELECT
    company_id,
    job_title
FROM 
    job_postings_fact
WHERE job_health_insurance = TRUE
  AND EXTRACT(YEAR FROM job_posted_date) = 2023
  AND EXTRACT(QUARTER FROM job_posted_date) = 2;


-- January
CREATE TABLE january_job AS
SELECT *
FROM job_postings_fact
WHERE EXTRACT(MONTH FROM job_posted_date) = 1;

-- February
CREATE TABLE february_job AS
SELECT *
FROM job_postings_fact
WHERE EXTRACT(MONTH FROM job_posted_date) = 2;

-- March
CREATE TABLE march_job AS
SELECT *
FROM job_postings_fact
WHERE EXTRACT(MONTH FROM job_posted_date) = 3;

SELECT job_posted_date
FROM march_job;

SELECT
    job_title_short,
    job_location,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM job_postings_fact;

/*

Label new column as follows:
- 'Anywhere' jobs as 'Remote'
- 'New York, NY' jobs as 'Local'
Otherwise 'Onsite'

*/

SELECT
    COUNT (job_id) AS number_of_jobs,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY
    location_category;


SELECT
    job_title_short,
    salary_year_avg,
    CASE 
        WHEN salary_year_avg >= 120000 THEN 'High salary'
        WHEN salary_year_avg >= 70000 THEN 'Standard salary'
        ELSE 'Low salary'
    END AS salary_bucket
FROM
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
ORDER BY
    salary_year_avg DESC;


SELECT
    job_title,
    company_name,
    salary_year_avg,
    CASE 
        WHEN salary_year_avg >= 120000 THEN 'High salary'
        WHEN salary_year_avg >= 70000 THEN 'Standard salary'
        ELSE 'Low salary'
    END AS salary_bucket
FROM job_postings
WHERE LOWER(job_title) LIKE '%data analyst%'
ORDER BY salary_year_avg DESC;

SELECT *
FROM ( -- SubQuery starts here
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1
    )AS january_jobs;
-- SubQuery ends here 

WITH january_jobs AS ( -- CTE definition starts here
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1
) -- CTE definition ends here

SELECT *
FROM january_jobs;

SELECT 
    company_id,
    name AS company_name
FROM 
    company_dim
WHERE company_id IN (
    SELECT
        company_id
    FROM
        job_postings_fact
    WHERE
        job_no_degree_mention = true
    ORDER BY
        company_id
)

/*
Find the companies that have the most job openings.
- Get the total number of job postings per company id (job_posting_fact)
Return the total number of jobs with the company name (company_dim)
*/

WITH company_job_count AS (
    SELECT
            company_id,
            COUNT (*)
    FROM
        job_postings_fact
    GROUP BY
        company_id
)
SELECT *
FROM company_job_count

WITH company_job_count AS (
    SELECT
            company_id,
            COUNT (*) AS total_jobs
    FROM
        job_postings_fact
    GROUP BY
        company_id
)

SELECT 
    company_dim.name AS company_name,
    company_job_count.total_jobs
FROM company_dim
LEFT JOIN company_job_count
    ON company_job_count.company_id = company_dim.company_id
ORDER BY
    total_jobs DESC