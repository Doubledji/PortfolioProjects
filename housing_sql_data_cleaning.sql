/*

Cleaning Data in SQL Queries 

*/


SELECT 
  *
FROM 
  nashville_housing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


SELECT 
  SaleDate, 
  CONVERT(date, SaleDate)
FROM 
  nashville_housing

UPDATE nashville_housing
SET SaleDate = CONVERT(date, SaleDate)

-- It didn't UPDATE properly, tried a different way

ALTER TABLE nashville_housing
ADD SaleDateConverted Date;

UPDATE nashville_housing
SET SaleDateConverted = CONVERT(Date, SaleDate)


 --------------------------------------------------------------------------------------------------------------------------

-- PropertyAddress has several duplicates and NULLs, however each property address has a specific ParcelID
-- Populate  missing Property Address data

SELECT 
  *
FROM 
  nashville_housing
-- WHERE PropertyAddress is null
ORDER BY 
  ParcelID


-- To achieve this we join the table on to itself, through a join on parcelID and on distinct uniqueIDs
-- Which are always unique even if the parcelID or property addresses are the same
-- In this query we find out which parcelIDs have NULL property addresses even when they have been previously populated with an address AND have different uniqueIDs

SELECT 
  a.ParcelID, 
  a.PropertyAddress, 
  b.ParcelID, 
  b.PropertyAddress, 
  ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM nashville_housing a
JOIN nashville_housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE 
  a.PropertyAddress IS NULL

-- After checking which property address fields are NULL, but have a replaceable alternative, we update the fields on our table, using one of the alieases in the previous join

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM nashville_housing a
JOIN nashville_housing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL




--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


SELECT 
  PropertyAddress
FROM 
  nashville_housing
--WHERE PropertyADDress is null
--ORDER BY ParcelID

-- Here we're using substrings to break down the address from the ","
-- The first part begins in index 1, goes up TO the comma in Property Address, removes it (-1) and creates a column
-- The second part, starts at the comma +1 index untill the length of the column (which is the end of the field) and places it in another column

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) AS Address

FROM nashville_housing


-- Let's create 2 new columns to place the split addresses, using the substring logic above
-- We will alter the table and update it just like before

ALTER TABLE nashville_housing
ADD PropertySplitAddress Nvarchar(255);

UPDATE nashville_housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE nashville_housing
ADD PropertySplitCity Nvarchar(255);

UPDATE nashville_housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))



-- Let's do the same for the Owner Address but a different way using PARSENAME function
-- Useful to split data that is delimited by ".", which is what it looks for to split the data
-- We can replace the commas by periods and use the function

SELECT 
  OwnerAddress
FROM 
  nashville_housing


SELECT
  PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
  PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
  PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM 
  nashville_housing

-- Add the new columns to the table, street address, city, and state
-- (columns created are placed backwards so number 3 is the first, and so on)

ALTER TABLE nashville_housing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE nashville_housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE nashville_housing
ADD OwnerSplitCity Nvarchar(255);

UPDATE nashville_housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


ALTER TABLE nashville_housing
ADD OwnerSplitState Nvarchar(255);

UPDATE nashville_housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)





--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field


SELECT 
  Distinct(SoldAsVacant), 
  Count(SoldAsVacant)
FROM 
  nashville_housing
GROUP BY 
  SoldAsVacant
ORDER BY 
  2



SELECT 
  SoldAsVacant, 
  CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM 
  nashville_housing


UPDATE nashville_housing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END






-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
-- To do this we will partition the data by parcelId, propertyaddress, sale price, sale date and legal reference columns
-- because if all these values are the same in 2 rows, then we can be very sure that row's data is unusable

WITH RowNumCTE AS
(
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY 
	ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference 
	ORDER BY UniqueID
	) row_num

FROM nashville_housing
-- We use a temp table to be able to access the the newly created column that is a product of a calculation
)
-- Swithed "SELECT *" with "DELETE" to remove the duplicate rows
SELECT
  *
FROM 
  RowNumCTE
WHERE 
  row_num > 1 -- This will show the duplicate rows 
ORDER BY PropertyAddress



---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns
-- Not best practice, just to showcase how to do it

SELECT 
  *
FROM 
  nashville_housing


ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
