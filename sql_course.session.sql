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
    ON company_dim.company_id = company_job_count.company_id
ORDER BY
    total_jobs DESC

/*
Identify the top 5 skills that are most frequently mentioned in job postings. Use a subquery to
find the skill IDs with the highest counts in the skills_job_dim table and then join this result
with the skills_dim table to get the skill names.
*/

WITH top_skills AS (
    SELECT 
        skill_id,
        COUNT(*) AS skill_count
    FROM 
        skills_job_dim
    GROUP BY 
        skill_id
    ORDER BY 
        skill_count DESC
    LIMIT 5
)
SELECT *
FROM     top_skills

WITH top_skills AS (
    SELECT 
        skill_id,
        COUNT(*) AS skill_count
    FROM 
        skills_job_dim
    GROUP BY 
        skill_id
    ORDER BY 
        skill_count DESC
    LIMIT 5
)
SELECT
    skills_dim.skill_id,
    skills_dim.skills,
    top_skills.skill_count
FROM 
    top_skills
JOIN skills_dim
    ON skills_dim.skill_id = top_skills.skill_id
ORDER BY skill_count DESC

/* Determine the size category ('Small', 'Medium', or 'Large') for each company by first identifying
the number of job postings they have. Use a subquery to calculate the total job postings per
company. A company is considered 'Small' if it has less than 10 job postings, 'Medium' if the
number of job postings is between 10 and 50, and 'Large' if it has more than 50 job postings.
Implement a subquery to aggregate job counts per company before classifying them based on
size. */


WITH company_job_count AS (
    SELECT
            company_id,
            COUNT (*) AS total_jobs
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
    name AS company_name,
    total_jobs,
    CASE
        WHEN total_jobs < 10 THEN 'Small'
        WHEN total_jobs BETWEEN 10 AND 50 THEN 'Medium'
        ELSE 'Large'
    END AS company_size
FROM company_dim
LEFT JOIN company_job_count AS job_counts
    ON company_dim.company_id = job_counts.company_id
ORDER BY total_jobs DESC;

/*
Find the count of the number of remote job postings per skill
    - Display the top 5 skills by their demand in remote jobs
    - Include skill ID, name, and count of postings requiring the skill
*/

WITH remote_job_skills AS (
    SELECT 
        skill_id,
        COUNT(*) AS skill_count
    FROM
        skills_job_dim AS skills_to_job
    INNER JOIN job_postings_fact AS job_postings 
        ON job_postings.job_id = skills_to_job.job_id
    WHERE
        job_postings.job_work_from_home = True AND
        job_postings.job_title_short = 'Data Analyst'
    GROUP BY
        skill_id
)

SELECT 
    skills.skill_id,
    skills AS skill_name,
    skill_count  
FROM remote_job_skills
INNER JOIN skills_dim AS skills ON skills.skill_id = remote_job_skills.skill_id
ORDER BY
    skill_count DESC
LIMIT 5;

/*
Find job postings from the first quarter that have a salary greater than $70K
- Combine job posting tables from the first quarter of 2023 (Jan-Mar)
- Gets job postings with an average yearly salary > $70,000 
- Filter for Data Analyst Jobs and order by salary
*/

SELECT
	job_title_short,
	job_location,
	job_via,
	job_posted_date::DATE,
    salary_year_avg
FROM (
    SELECT *
    FROM january_job
    UNION ALL
    SELECT *
    FROM february_job
    UNION ALL
    SELECT *
    FROM march_job
) AS quarter1_job_postings
WHERE
    salary_year_avg > 70000 AND
    job_title_short = 'Data Analyst'
ORDER BY
    salary_year_avg DESC

/*
· Get the corresponding skill and skill type for each job posting in q1
. Includes those without any skills, too
. Why? Look at the skills and the type for each job in the first quarter that has a salary > $70,000
*/

SELECT
    quarter1_job_postings.job_id,
    job_title_short,
    salary_year_avg,
    skills_dim.skills,
    skills_dim.type AS skill_type
FROM (
        SELECT *
        FROM january_job
        UNION ALL
        SELECT *
        FROM february_job
        UNION ALL
        SELECT *
        FROM march_job
        ) AS quarter1_job_postings
LEFT JOIN skills_job_dim
        ON skills_job_dim.job_id = quarter1_job_postings.job_id
LEFT JOIN skills_dim
        ON skills_dim.skill_id = skills_job_dim.skill_id
WHERE
    salary_year_avg > 70000 AND
    job_title_short = 'Data Analyst'
ORDER BY
    salary_year_avg DESC


 