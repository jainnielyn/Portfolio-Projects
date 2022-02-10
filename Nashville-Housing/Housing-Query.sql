/*

Cleaning Data in SQL Queries
Used: CONVERT, JOIN, SUBSTRING, PARSENAME, CASE, CTE, PARTITION

*/

Select *
From PortfolioProject..NashvilleHousing
order by 2

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

-- Method 1, convert existing column
Update NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate)

-- Method 2, add new column
ALTER TABLE NashvilleHousing
Add SaleDateConverted date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ] -- SaleDateConverted could also be used
Where a.PropertyAddress is null


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

Alter table NashvilleHousing
Add PropertySplitAddress nvarchar(255),
PropertySplitCity nvarchar(255);

Update NashvilleHousing
Set PropertySplitAddress = substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
PropertySplitCity = substring(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress));


-- Split out owner address

Alter table NashvilleHousing
Add OwnerSplitAddress nvarchar(255),
OwnerSplitCity nvarchar(255),
OwnerSplitState nvarchar(255);

Update NashvilleHousing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

Select DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
From PortfolioProject..NashvilleHousing
Group by SoldAsVacant
Order by 2

Update NashvilleHousing
Set SoldAsVacant = 
CASE 
	When SoldAsVacant = 'Y' Then 'Yes'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
	End 



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS (
Select *, ROW_NUMBER() OVER 
(
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID 
) as row_num
From PortfolioProject..NashvilleHousing
)
--Select * from RowNumCTE
DELETE From RowNumCTE
Where row_num > 1

---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict, SaleDate


-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
