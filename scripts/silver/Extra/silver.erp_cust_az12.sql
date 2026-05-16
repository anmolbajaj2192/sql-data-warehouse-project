use DataWareHouse;

truncate table bronze.erp_cust_az12;
DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\DELL\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';
insert into silver.erp_cust_az12(cid, bdate, gen)
select 
CASE
	WHEN cid LIKE 'NAS%' then SUBSTRING(cid, 4, len(cid)) -- Remove 'NAS' prefix if present
	else cid
end cid,
CASE 
	WHEN bdate > getdate() then null
	else bdate
end as bdate, -- Set future birthdates to NULL
case
	when UPPER(TRIM(gen)) in ('F', 'Female') then 'Female'
	when UPPER(TRIM(gen)) in ('M', 'Male') then 'Male'
	else 'N/A'
end as gen -- Normalize gender values and handle unknown cases
from bronze.erp_cust_az12


where case when cid like 'NAS%' then substring(cid, 4, len(cid))
	else cid
end not in (select distinct cst_key from silver.crm_cust_info);

-- Identify out of ranges dates

select distinct 
bdate
from silver.erp_cust_az12
where bdate < '1924-01-01' or bdate > GETDATE();

-- Data standardization and consistency
select distinct gen,
case
	when UPPER(TRIM(gen)) in ('F', 'Female') then 'Female'
	when UPPER(TRIM(gen)) in ('M', 'Male') then 'Male'
	else 'N/A'
end as gen
from silver.erp_cust_az12;

select * from silver.erp_cust_az12;