use DataWareHouse;

--check for nulls or duplicates in primary key
--expectation: no result
select 
cst_id,
count(*)
from bronze.crm_cust_info
group by cst_id
having count(*) >1 or cst_id is null;

select * from bronze.crm_cust_info
where cst_id=29466;

select * 
from(
select *,
ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) as flag_last
from bronze.crm_cust_info) t 
where flag_last = 1 and cst_id = 29466;

--check for unwanted spaces
--if the original value is not equal to the same value after trimming it means
--there are spaces!
select cst_firstname
from bronze.crm_cust_info
where cst_firstname != TRIM(cst_firstname);

select cst_lastname
from bronze.crm_cust_info
where cst_lastname != TRIM(cst_lastname);

select cst_gndr
from bronze.crm_cust_info
where cst_gndr != TRIM(cst_gndr);

--solution: for transformation and order to clean up will write window function

--Data Standardization & Consistency:
-- Maps coded values to meaningful, user-friendly descriptions
--in our data warehouse we aim to store clear and meaningful values rather than using abbreviated terms
-- in our data warehouse we use the default value 'n/a' for missing value.
-- Apply UPPER() just in case mixed-case values appear later in your column.
select DISTINCT(cst_gndr)
from bronze.crm_cust_info;

select DISTINCT(cst_material_status) 
from bronze.crm_cust_info;

insert into silver.crm_cust_info(
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date)
select 
cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname) as cst_lastname,

case
	when UPPER(TRIM(cst_material_status)) = 'S' then 'Single'
	when UPPER(TRIM(cst_material_status)) = 'M' then 'Married'
	else 'N/A'
end cst_material_status, -- Normalize marital status values to readable format

case 
	when UPPER(TRIM(cst_gndr)) = 'M' then 'Male' 
	when UPPER(TRIM(cst_gndr)) = 'F' then 'Female'
	else 'N/A'
end cst_gndr, -- Normalize gender values to readable format
cst_create_date
from (
	select *,
	ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) as flag_last
from bronze.crm_cust_info
where cst_id is not null

)as t where flag_last=1; -- Remove Duplicates: Ensure only one record per entity by identifying and retaining the most relevant row.

-- Quality of silver
-- Re-run the quality check queries from the bronze layer to verify the quality of data in the silver layer. 

select * from silver.crm_cust_info;

select 
cst_id,
count(*)
from silver.crm_cust_info
group by cst_id
having count(*) >1 or cst_id is null;

select cst_firstname
from silver.crm_cust_info
where cst_firstname != TRIM(cst_firstname);

select cst_lastname
from silver.crm_cust_info
where cst_lastname != TRIM(cst_lastname);

select cst_gndr
from silver.crm_cust_info
where cst_gndr != TRIM(cst_gndr);

