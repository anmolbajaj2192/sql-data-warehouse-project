-------------------------------------------crm_prd_info----------------------------------
use DataWareHouse;
DROP table bronze.crm_prd_info;

CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,
    prd_key      NVARCHAR(50),
    prd_nm       NVARCHAR(50),
    prd_cost     INT,
    prd_line     NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt   DATETIME
);

DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>> Inserting Data Into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\DELL\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

select * from bronze.crm_prd_info;
select * from silver.crm_prd_info;
insert into silver.crm_prd_info(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)
select 
prd_id,
REPLACE(SUBSTRING(prd_key,1,5), '-', '_') as cat_id,-- Extract category ID -- filter out unmatached data after applying transformation
SUBSTRING(prd_key, 7, len(prd_key)) as prd_key, --Extract Product Key
prd_nm,
ISNULL(prd_cost, 0) as prd_cost,
CASE UPPER(TRIM(prd_line)) -- Quick CASE when ideal for simple value mapping
	when 'M' then 'Mountain'
	when 'R' then 'Road'
	when 'S' then 'Other Sales'
	when 'T' then 'Touring'
	ELSE 'N/A'
END as prd_line, -- Map Product line codes to descriptive values -- Data Normalization
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(
		LEAD(prd_start_dt) OVER(
			Partition by prd_key 
			ORDER BY prd_start_dt
	)- 1 AS DATE
) AS prd_end_dt_test -- Calculate end date as one day before the next start date
from bronze.crm_prd_info;

--Derived Columns: Create new columns based on calculations or transformation of existing ones Eg. cat Id, prd key
-- Data Enrichment: Add new, relevant data to enhance the dataset for analysis


where SUBSTRING(prd_key, 7, len(prd_key)) as prd_key NOT IN(
	select sls_prd_key from bronze.crm_sales_details)
group by prd_id
having count(*) >1 or prd_id is null;

select distinct id from bronze.erp_px_cat_g1v2;
select * from bronze.crm_prd_info;

--QUALITY CHECK FOR SILVER TABLE
--check for unwanted spaces
-- Expectation: No results
select prd_nm
from silver.crm_prd_info
where prd_nm != TRIM(prd_nm);

-- check for nulls or negative numbers
-- Expectation: NO results
-- ISNULL(): Replaces NULL values with a specified replacement value
-- You can use COALESCE as well
select prd_cost
from silver.crm_prd_info
where prd_cost < 0 or prd_cost is NULL;

-- Data Standardization & Consistency
Select DISTINCT prd_line
FROM silver.crm_prd_info;

--Check for invalid data orders
-- End date must not be earlier than the start date
-- For complex transformations in SQL, I typically narrow it down to a specific example and brainstorm multiple solution approaches
-- Solution 1: Switch end data and start date
-- Issue in Solution 1: The dates are overlapping
-- Issue: Each Record must has a Start Date
-- Solution 2: Derive the End Date from the Start Date
-- End date = Start Date of the NEXT record - 1

select * 
from silver.crm_prd_info
where prd_end_dt < prd_start_dt

-- LEAD(): Access values from the next row within a window

select 
prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER(Partition by prd_key ORDER BY prd_start_dt) AS prd_end_dt_test
from bronze.crm_prd_info
where prd_key in ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')

