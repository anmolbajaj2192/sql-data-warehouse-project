use DataWareHouse;

select * from silver.erp_px_cat_g1v2;

truncate table bronze.erp_px_cat_g1v2; 
truncate table silver.erp_px_cat_g1v2;

DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\DELL\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';


insert into silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
select 
id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_g1v2;


-- for id:
-- In crm_prd_info there is prd_key which is reference for id in erp_px_cat_g1v2

-- Check for unwanted spaces

select * from bronze.erp_px_cat_g1v2
where cat != Trim(cat) or subcat != trim(subcat) or maintenance != Trim(maintenance);

-- Data standardization and consistency
select distinct
maintenance
from bronze.erp_px_cat_g1v2;