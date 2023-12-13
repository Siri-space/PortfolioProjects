/*
Cleaning the Housingdata in SQL Queries
*/
SELECT * 
FROM HousingData$
WHERE PropertyAddress IS NULL

----------------------------------------------------------------------
/* 
Standardise SaleDate
*/
SELECT SaleDate, CONVERT(date, SaleDate)
FROM HousingData$;

UPDATE HousingData$
SET SaleDate = CONVERT(date, SaleDate);

ALTER TABLE HousingData$
ADD SaleDateConverted Date;

UPDATE HousingData$
SET SaleDateConverted = CONVERT(date, SaleDate);

----------------------------------------------------------------------
/* 
Populate Property Address Data
This is done using a self join to pupulate the addresses that are NULLs
*/
SELECT a.[UniqueID ], b.[UniqueID ], a.ParcelID, b.ParcelID, a.PropertyAddress, b.PropertyAddress
, ISNULL(b.PropertyAddress, a.PropertyAddress)
FROM HousingData$ a
JOIN HousingData$ b
		ON a.[UniqueID ] <> b.[UniqueID ]
		AND a.ParcelID = b.ParcelID
WHERE a.PropertyAddress IS NULL

-- Adding the cleaned column to the table

UPDATE a
SET PropertyAddress = ISNULL(b.PropertyAddress, a.PropertyAddress)
FROM HousingData$ a
JOIN HousingData$ b
		ON a.[UniqueID ] <> b.[UniqueID ]
		AND a.ParcelID = b.ParcelID
WHERE a.PropertyAddress IS NULL
----------------------------------------------------------------------

/*
Breaking out Propertyaddress into different columns i.e (address, city, state)
Using the CHARINDEX, LEFT and RIGHT Funtions
*/
SELECT LEFT(PropertyAddress, CHARINDEX(',', PropertyAddress,1) - 1) as Address,
RIGHT(PropertyAddress, LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress,1)-1) as City
FROM HousingData$

-- Adding the cleaned columns to the table

ALTER TABLE HousingData$
ADD PropertySplitAddress nVARCHAR(255);

UPDATE HousingData$
SET PropertySplitAddress = LEFT(PropertyAddress, CHARINDEX(',', PropertyAddress,1) - 1);

ALTER TABLE HousingData$
ADD PropertySplitCity nVARCHAR(255);

UPDATE HousingData$
SET PropertySplitCity = RIGHT(PropertyAddress, LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress,1)-1);

--Check Output to see if the result is what I expected
SELECT * 
FROM HousingData$

/*
Breaking out Owneraddress into different columns i.e (address, city, state)
Using the ParseName Function
Works with period(.) delimeter
*/

SELECT OwnerAddress, REPLACE(OwnerAddress, ',' , '.'),
PARSENAME(REPLACE(OwnerAddress, ',' , '.'),3) as Address, -- Starting from 3 as Parsename does things backward
PARSENAME(REPLACE(OwnerAddress, ',' , '.'),2) as City,
PARSENAME(REPLACE(OwnerAddress, ',' , '.'),1) as State
FROM HousingData$

-- Adding the cleaned columns to the table

ALTER TABLE HousingData$
ADD OwnerSplitAddress nVARCHAR(255);

UPDATE HousingData$
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',' , '.'),3);

ALTER TABLE HousingData$
ADD OwnerSplitCity nVARCHAR(255);

UPDATE HousingData$
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',' , '.'),2);

ALTER TABLE HousingData$
ADD OwnerSplitState nVARCHAR(255);

UPDATE HousingData$
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',' , '.'),1);

--Check Output to see if the result is what you expected
SELECT * 
FROM HousingData$

----------------------------------------------------------------------
/*
Change Y and N to Yes and No respectively in the SoldAsVacant field
Using Replace function and a Case statement
*/

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN REPLACE(SoldAsVacant,'Y', 'Yes')
	WHEN SoldAsVacant = 'N' THEN REPLACE(SoldAsVacant,'N', 'No')
	ELSE SoldAsVacant
	END as Cleaned_SoldAsVacant
FROM HousingData$

-- Adding the cleaned columns to the table

UPDATE HousingData$
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN REPLACE(SoldAsVacant,'Y', 'Yes')
					WHEN SoldAsVacant = 'N' THEN REPLACE(SoldAsVacant,'N', 'No')
					ELSE SoldAsVacant
					END;

--Check Output to see if the result is what I expected
Use portfolio1
SELECT * 
FROM HousingData$
WHERE SoldAsVacant IN ('Y', 'N')

----------------------------------------------------------------------
/*
Remove Duplicates
*/
SELECT *, 
ROW_NUMBER() OVER (
			PARTITION BY ParcelID, PropertyAddress, SalePrice, LegalReference
			ORDER BY UniqueID) Check_Row
FROM HousingData$
ORDER BY ParcelID

-- Use as a CTE

WITH CheckRowCTE AS (
SELECT *, 
ROW_NUMBER() OVER (
			PARTITION BY ParcelID, PropertyAddress, SalePrice, LegalReference
			ORDER BY UniqueID) Check_Row
FROM HousingData$
--ORDER BY ParcelID
)

SELECT * 
FROM CheckRowCTE
WHERE Check_Row > 1 -- This returns the duplicate rows
ORDER BY PropertyAddress

-- Delete the duplicate Rows
WITH CheckRowCTE AS (
SELECT *, 
ROW_NUMBER() OVER (
			PARTITION BY ParcelID, PropertyAddress, SalePrice, LegalReference
			ORDER BY UniqueID) Check_Row
FROM HousingData$
--ORDER BY ParcelID
)

DELETE 
FROM CheckRowCTE
WHERE Check_Row > 1
--ORDER BY PropertyAddress

----------------------------------------------------------------------


