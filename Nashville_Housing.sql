--Inspect data
SELECT *
FROM Portfolio_Nashville_Housing..NashvilleHousing

--CONVERT SALEDATE FORMAT TO DATE
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM Portfolio_Nashville_Housing..NashvilleHousing

ALTER TABLE NashvilleHousing ALTER COLUMN SaleDate DATE

------------------------
--PROPERTY ADDRESS DATA
--Looking for NULL values
SELECT *
FROM Portfolio_Nashville_Housing..NashvilleHousing
WHERE PropertyAddress is NULL

--ParcelID serves as unique identifier for PropertyAddress
SELECT *
FROM Portfolio_Nashville_Housing..NashvilleHousing
ORDER BY ParcelID

--Fill missing values
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio_Nashville_Housing..NashvilleHousing AS a
JOIN Portfolio_Nashville_Housing..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio_Nashville_Housing..NashvilleHousing AS a
JOIN Portfolio_Nashville_Housing..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL

-------------------------------------------------------
--SEPARATE ADDRESS FIELDS INTO STREET, CITY (AND STATE)
--Looking at table to identify comma purely used as delimiter
SELECT PropertyAddress, OwnerAddress
FROM Portfolio_Nashville_Housing..NashvilleHousing
ORDER BY PropertyAddress

--Separating fields for PropertyAddress
SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Street,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress)) AS City
FROM Portfolio_Nashville_Housing..NashvilleHousing

ALTER TABLE NashvilleHousing 
ADD PropertyStreet NVARCHAR(255), PropertyCity NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertyStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1), 
	PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress))

--Separating fields for OwnerAddress
SELECT 
	TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)) AS OwnerState,
	TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)) AS OwnerCity,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerStreet
FROM Portfolio_Nashville_Housing..NashvilleHousing

ALTER TABLE NashvilleHousing 
ADD OwnerAddressStreet NVARCHAR(255), OwnerAddressCity NVARCHAR(255), OwnerAddressState NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerAddressStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), 
	OwnerAddressCity = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)),
	OwnerAddressState = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1))

-----------------------
--CLEAN UP SOLDASVACANT
--Looking at all values and how often they occur
SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM Portfolio_Nashville_Housing..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No' 
		 ELSE SoldAsVacant
		 END
FROM Portfolio_Nashville_Housing..NashvilleHousing

--Replacing all Ys with YES and all Ns with No
UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No' 
		 ELSE SoldAsVacant
		 END

-------------------
--REMOVE DUPLICATE ENTRIES
WITH duplicates AS(
SELECT *, 
	ROW_NUMBER() OVER(
		PARTITION BY ParcelID, 
					 PropertyAddress,
					 SaleDate,
					 SalePrice,
					 LegalReference
		ORDER BY UniqueID
		) AS row_num
FROM Portfolio_Nashville_Housing..NashvilleHousing
)
--SELECT * 
DELETE
FROM duplicates
WHERE row_num > 1