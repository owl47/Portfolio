-- Data Cleaning

Select *
from Nashville_Housing_Data_for_Data_Cleaning

-- Date format Standardization, dd-mm-yyyy format
update Nashville_Housing_Data_for_Data_Cleaning
set saledate = str_to_date(saledate, '%M %e, %Y')
where saledate is not null;

alter table Nashville_Housing_Data_for_Data_Cleaning
modify column saledate date;

select saledate, date_format(saledate, '%d-%m-%Y') AS Sale_Date
FROM Nashville_Housing_Data_for_Data_Cleaning;


-- confirming date formatting and standardization
DESCRIBE Nashville_Housing_Data_for_Data_Cleaning;


-- Property Address data population

update Nashville_Housing_Data_for_Data_Cleaning  -- turning blanks and trailing spaces to NULLS
set PropertyAddress = NULL
WHERE trim(PropertyAddress) = '';

Select *
from Nashville_Housing_Data_for_Data_Cleaning
-- where PropertyAddress is null
order by ParcelID 


-- Looking at property addresses with NULLS
Select a.ParcelID , a.PropertyAddress , b.ParcelID , b.PropertyAddress, ifnull (a.PropertyAddress, b.PropertyAddress)
from Nashville_Housing_Data_for_Data_Cleaning a
join Nashville_Housing_Data_for_Data_Cleaning b
	on a.ParcelID  = b.ParcelID 
	and
	a.UniqueID  <> b.UniqueID
where a.PropertyAddress is null

-- populating nulls in Property Address

update Nashville_Housing_Data_for_Data_Cleaning a
join Nashville_Housing_Data_for_Data_Cleaning b
	on a.ParcelID  = b.ParcelID 
	and
	a.UniqueID  <> b.UniqueID
set a.PropertyAddress = b.PropertyAddress 
where a.PropertyAddress is null 


-- Drilling down Property Address into separate columns (Address, City, State)

select propertyaddress
from Nashville_Housing_Data_for_Data_Cleaning

SELECT 
    substring(propertyaddress, 1, locate(',', propertyaddress) - 1) as Address,
    substring(propertyaddress, locate(',', propertyaddress) + 1, LENGTH(propertyaddress)) as Address
FROM Nashville_Housing_Data_for_Data_Cleaning;




alter table Nashville_Housing_Data_for_Data_Cleaning
add propertysplitaddress varchar(255);

update Nashville_Housing_Data_for_Data_Cleaning
set propertysplitaddress = substring(propertyaddress, 1, locate(',', propertyaddress) - 1);

alter table Nashville_Housing_Data_for_Data_Cleaning
add propertysplitcity varchar(255);

update Nashville_Housing_Data_for_Data_Cleaning
set propertysplitcity = substring(propertyaddress, locate(',', propertyaddress) + 1, LENGTH(propertyaddress));

-- breaking out the owner address to separate columns 
Select substring_index(replace(owneraddress,',','.'),'.',-3)
, substring_index(replace(owneraddress,',','.'),'.',-2)
, substring_index(replace(owneraddress,',','.'),'.',-1)
from Nashville_Housing_Data_for_Data_Cleaning

alter table Nashville_Housing_Data_for_Data_Cleaning
add ownersplitaddress varchar(255);

update Nashville_Housing_Data_for_Data_Cleaning
set ownersplitaddress = substring_index(replace(owneraddress,',','.'),'.',1)

alter table Nashville_Housing_Data_for_Data_Cleaning
add ownersplitcity varchar(255);

update Nashville_Housing_Data_for_Data_Cleaning
set ownersplitcity = substring_index(substring_index(replace(owneraddress,',','.'),'.',2), '.',-1)

alter table Nashville_Housing_Data_for_Data_Cleaning
add ownersplitstate varchar(255);

update Nashville_Housing_Data_for_Data_Cleaning
set ownersplitstate = substring_index(replace(owneraddress,',','.'),'.',-1)


-- Unifying Booleans in "Sold as vacant field" from Y and N to Yes and No
-- Yes = 4623 rows, No = 51,403 rows, Y = 52 rows, N = 399 rows
Select distinct(Soldasvacant), Count(soldasvacant)
from Nashville_Housing_Data_for_Data_Cleaning
group by SoldAsVacant 
order by 2


Select SoldAsVacant,
CASE
	when SoldAsVacant = 'Y' Then 'Yes'
	when SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
	END
from Nashville_Housing_Data_for_Data_Cleaning

-- updating the column with the new values

UPDATE Nashville_Housing_Data_for_Data_Cleaning
SET SoldAsVacant = CASE
	when SoldAsVacant = 'Y' Then 'Yes'
	when SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
	END;



-- Removing Duplicates

-- CTE to temporarily view all duplicated data
-- Row_Number function to assign it an integer for each row in the set, with each unique row
-- getting assigned 1, if a duplicate exists, is assigned a 2, if a 3rd is found
-- it is assigned a 3, and so on.
With RowNumCTE AS ( 
Select *,
Row_number() over( 
			 partition by ParcelID, PropertyAddress, saleprice, saledate, legalreference
			 order by
			 UniqueID)
			 row_num
from Nashville_Housing_Data_for_Data_Cleaning
)

-- Viewing duplicates
Select * from RowNumCTE
where row_num >1
order by propertyaddress

-- Deleting duplicates
-- extra nesting due to MYSQL not allowing referencing same table in a subquery
-- inside a DELETE
DELETE from Nashville_Housing_Data_for_Data_Cleaning 
where uniqueID in (
	Select uniqueid from (
		Select uniqueid, Row_number() over(
			Partition by parcelid, propertyaddress, saleprice, saledate, legalreference
			order by uniqueid) AS row_num
		from Nashville_Housing_Data_for_Data_Cleaning) as subquery
		where row_num >1
		);


-- Removing unused columns

alter table Nashville_Housing_Data_for_Data_Cleaning
drop column Owneraddress, 
drop column taxdistrict,
drop column propertyaddress,
drop column saledate;















