use DataWareHouse;
select COUNT(*) from bronze.crm_sales_details;
select COUNT(*) from silver.crm_sales_details;
truncate table bronze.crm_sales_details;
truncate table silver.crm_sales_details;
DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
 SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT '>> Inserting Data Into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\DELL\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';


-- First check: where sls_ord_num != TRIM(sls_ord_num);
-- Second check: where sls_prd_key NOT in (SELECT prd_key from silver.crm_prd_info);
-- third check: where sls_cust_id NOT in (SELECT cst_id from silver.crm_cust_info);
-- for above check integration model of silver
--------------------------------------------------
insert into silver.crm_sales_details(
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
)
select
sls_ord_num,
sls_prd_key,
sls_cust_id,
case 
	when sls_order_dt = 0 or len(sls_order_dt) !=8 then null
	else CAST(CAST(sls_order_dt as VARCHAR) as DATE)
	end as sls_order_dt,
case 
	when sls_ship_dt  = 0 or len(sls_ship_dt) != 8 then null
	else CAST(CAST(sls_ship_dt as VARCHAR) as DATE)
	end as sls_ship_dt,

case 
	when sls_due_dt  = 0 or len(sls_due_dt) !=8 then null
	else CAST(CAST(sls_due_dt as VARCHAR) as DATE)
	end as sls_due_dt,
case 
	when sls_sales <= 0 or sls_sales is null or sls_sales != sls_quantity* ABS(sls_price)
	then sls_quantity *  ABS(sls_price)
	else sls_sales
end as sls_sales,

sls_quantity,

case 
	when sls_price is null or sls_price <= 0
	then sls_sales/NULLIF(sls_quantity, 0)
	else sls_price
end as sls_price
from bronze.crm_sales_details;


-- check for invalid dates
-- first check: Negative numbers or zero cant be cast to date
--EX:where sls_order_dt < 0
-----------------------------------------------------------------
-- second check: where sls_order_dt <= 0
-- NULLIF(): Return NULL if two given values are equal; otherwise, it returns the first expression
-----------------------------------------------------------------
-- third check: In this scenario, the lenght of the date must be 9 
--EX: 20101229, 
-- where sls_order_dt <= 0  or len(sls_order_dt) != 8 
-- check for outliers by validating the boundaries of the date range


select 
NULLIF(sls_order_dt, 0) sls_order_dt
from bronze.crm_sales_details
where sls_order_dt <= 0  
or len(sls_order_dt) != 8 
or sls_order_dt > 20500101
or sls_order_dt < 19000101

-- check for invalid date orders
-- order date must always be earlier than the shipping date or due date
select 
*
from silver.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt;

-- Business Rules:
-- Sales = Quantity * Price
-- Negative, Zeros, Nulls are not allowed!
select DISTINCT
sls_sales ,
sls_quantity ,
sls_price 
from silver.crm_sales_details
where sls_sales != sls_quantity * sls_price
or sls_sales is NULL or sls_quantity is NULL or sls_price is null
or sls_sales <= 0 or sls_quantity <= 0  or sls_price <= 0

select * from silver.crm_sales_details;

-- In above situation we go to someone in the business or to the source system
-- Bases on discussion there might be two solutions which is mentioned below:
-- Solution 1: Data Issues will be fixed direct in source system
-- Solution 2: Data issues has to be fixed in data warehouse
-- Rules: If sales is negative, zero or null, derive it using quantity and price
--		  If price is zero or null, calculate it using Sales and Quantity
--		  If Price is negative, convert it to a positive value

-- AFTER inserting into silver table
