-- 4thAxis
-- 8/13/21


local Library = {}

--------------------------------------------------------------------
----------------------------  Tables  ------------------------------
--------------------------------------------------------------------


function Library.GetLengthOfTable(Table)
	if not Table then return 0 end

	local Length = 0; for _ in pairs(Table) do
		Length += 1
	end

	return Length
end


function Library.ShallowMergeTables(Table1, Table2)
	Table1 = Table1 or {}
	Table2 = Table2 or {}
	
	local Merge = table.create(#Table1 + #Table2)
	
	for Index = 1, #math.max(Table1, Table2) do
		local ElementFromTable1, ElementFromTable2 = Table1[Index], Table2[Index]
		
		if ElementFromTable1 then 
			table.insert(Merge, ElementFromTable1)
			
		elseif ElementFromTable2 then
			table.insert(Merge, ElementFromTable2)
		
		end
		
	end
end


function Library.TableToArray(Table)
	if not Table then return {} end
	
	local Array = {}
	
	for _, Element in pairs(Table) do
		table.insert(Array, Element)
	end
	
	return Array
end


--------------------------------------------------------------------
------------------------------  Sets  ------------------------------
--------------------------------------------------------------------

function Library.Union(Set, OtherSet)
	Set = Set or {}
	OtherSet = OtherSet or {}
	
	local UnionSet = table.create(#Set + #OtherSet)
	
	for Index = 1, math.max(#Set, #OtherSet) do
		local NextElementFromSet, NextElementFromOtherSet = Set[Index], OtherSet[Index]

		if NextElementFromSet then 
			table.insert(UnionSet, NextElementFromSet)

		elseif NextElementFromOtherSet then
			table.insert(UnionSet, NextElementFromOtherSet)

		end
	end
	

	return UnionSet
end


function Library.Intersection(Set, OtherSet)
	Set = Set or {}
	OtherSet = OtherSet or {}
	
	local Intersection = table.create(#OtherSet)
	
	for Index in ipairs(Set) do
		if OtherSet[Index] then
			Set[Index] = true
		end
	end
	
	return Intersection
end




return Library
