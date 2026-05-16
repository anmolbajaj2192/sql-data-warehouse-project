use DataWareHouse;
select * from bronze.erp_loc_a101;
select * from silver.erp_loc_a101;

truncate table bronze.erp_loc_a101; 
truncate table silver.erp_loc_a101;

DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\DELL\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';
insert into silver.erp_loc_a101(cid, cntry)
select 
Replace(cid, '-', '') as cid,
Case 
	when UPPER(TRIM(cntry)) in ('USA', 'United States', 'US') then 'United States of America'
	when UPPER(TRIM(cntry)) in ('DE', 'Germany') then 'Germany'
	when UPPER(TRIM(cntry)) is NULL or UPPER(TRIM(cntry)) = ' ' then 'N/A'
	else cntry
end as cntry
from bronze.erp_loc_a101;

-- Transformation - cntry - clean- data normalization
select distinct
cntry,

Case 
	when UPPER(TRIM(cntry)) in ('USA', 'United States', 'US') then 'United States of America'
	when UPPER(TRIM(cntry)) in ('DE', 'Germany') then 'Germany'
	when UPPER(TRIM(cntry)) is NULL or UPPER(TRIM(cntry)) = ' ' then 'N/A'
	else cntry
end as cntry
from silver.erp_loc_a101;

--check cid
select 
REPLACE(cid, '-', '') cid,
cntry
from silver.erp_loc_a101
where Replace(cid, '-', '') NOT in (select cst_key from silver.crm_cust_info);