-- 4thAxis
-- 8/7/21


local Library = {}

--------------------------------------------------------------------
---------------------------  Imports  ------------------------------
--------------------------------------------------------------------

local Math = require(script.Parent:WaitForChild("Math"))

--------------------------------------------------------------------
--------------------------  Constants  -----------------------------
--------------------------------------------------------------------


local IdentityVector = Vector3.new()
local IdentityCFrame = CFrame.new()

local RightVector = Vector3.new(1, 0, 0)
local LeftVector = Vector3.new(-1, 0, 0)
local UpVector = Vector3.new(0, 1, 0)
local DownVector = Vector3.new(0, -1, 0)
local FrontVector = Vector3.new(0, 0, 1)
local BackVector = Vector3.new(0, 0, -1)


local Surfaces = {
	RightVector = Enum.NormalId.Right,
	LeftVector = Enum.NormalId.Left,
	UpVector = Enum.NormalId.Top,
	DownVector = Enum.NormalId.Bottom,
	FrontVector = Enum.NormalId.Front,
	BackVector = Enum.NormalId.Back
}


local SomeSpin = CFrame.fromEulerAnglesXYZ(math.pi/2, 0, 0)
local SomeDefaultPart = Instance.new("Part")

-------------------------------------------------------------------
------------------------ Helpers/Private  -------------------------
-------------------------------------------------------------------


local function GetTranstionBetweenVectors(Vect1, Vect2, PitchAxis)
	local Projection = Vect1:Dot(Vect2)
	
	if Projection > 0.99999 then
		return CFrame.new()
	elseif Projection < -0.99999 then
		return CFrame.fromAxisAngle(PitchAxis, math.pi)
	end
	
	return CFrame.fromAxisAngle(Vect1:Cross(Vect2), math.acos(Projection))
end


--------------------------------------------------------------------
---------------------------  Surfaces  -----------------------------
--------------------------------------------------------------------


function Library.GetSurfaceCFrameFromNormal(Part, Normal)
	Part = Part or SomeDefaultPart
	
	local Transition = GetTranstionBetweenVectors(UpVector, Normal or IdentityVector, BackVector)
	return Part.CFrame * Transition * SomeSpin
end


function Library.GetSurfaceFromNormalVector(Cframe, Normal) 
	Normal = (Cframe or IdentityCFrame):VectorToObjectSpace(Normal or IdentityVector)

	local X = math.round(Normal:Dot(RightVector))
	local Y = math.round(Normal:Dot(UpVector))
	local Z = math.round(Normal:Dot(FrontVector))

	return Surfaces[X..","..Y..","..Z]
end


--------------------------------------------------------------------
--------------------------  Reflections  ---------------------------
--------------------------------------------------------------------

-- Reflects over X Axis

function Library.ReflectCFrame(Cframe, ReflectOver)
	
	Cframe = Cframe or IdentityCFrame
	ReflectOver = ReflectOver or CFrame.new()

	local RelativeCFrame = ReflectOver:ToObjectSpace(Cframe)
	local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = RelativeCFrame:Components()

	local Mirror = CFrame.new(-X, Y, Z, R00, -R01, -R02, -R10, R11,  R12,-R20, R21, R22)
	return ReflectOver:ToWorldSpace(Mirror)
end


function Library.ReflectVector(Vector, ReflectOver)
	Vector = Vector or IdentityVector
	ReflectOver = ReflectOver or CFrame.new()

	local Relative = ReflectOver:VectorToObjectSpace(Vector)
	local Mirror = Vector3.new(-Relative.X, Relative.Y, Relative.Z)

	return ReflectOver:VectorToWorldSpace(Mirror)
end


function Library.ReflectPoint(Point, ReflectOver)
	ReflectOver = ReflectOver or CFrame.new()
	
	local Relative = ReflectOver:PointToObjectSpace(Point)
	local Mirror = Vector3.new(-Relative.X, Relative.Y, Relative.Z)

	return ReflectOver:PointToWorldSpace(Mirror)
end


function Library.ReflectRay(Ray, ReflectOver)
	if not Ray then return warn("Ray Required", Ray) end
	
	local Origin = Library:ReflectPoint(Ray.Origin, ReflectOver)
	local Direction = Library:ReflectVector(Ray.Direction, ReflectOver)

	return Ray.new(Origin, Direction)
end


--------------------------------------------------------------------
-------------------------  Intersections  --------------------------
--------------------------------------------------------------------

function Library.PlaneRayIntersection(Origin, Normal, RayOrigin, UnitRayDirection)
	if not Origin or not Normal or not RayOrigin or not UnitRayDirection then return warn("Missing Arguments: ", Origin, Normal, RayOrigin, UnitRayDirection) end

	local RayPoint = RayOrigin - Origin
	local Dot = UnitRayDirection:Dot(Normal)

	if Dot == 0 then return end

	local X = -RayPoint:Dot(Normal)/Dot
	return RayOrigin + X * UnitRayDirection, X
end


function Library.SphereRayIntersection(SphereCenter, SphereRadius, RayOrigin, RayDirection)
	local RelativeOrigin = RayOrigin - SphereCenter

	local OriginDotOrigin = RelativeOrigin:Dot(RelativeOrigin)
	local DirectionDotOrigin = RayDirection:Dot(RelativeOrigin)
	local DirectionDotDirection = RayDirection:Dot(RayDirection)

	local PassTime = -DirectionDotOrigin/DirectionDotDirection
	local PassDistance = OriginDotOrigin - DirectionDotOrigin^2/DirectionDotDirection

	if PassDistance >= SphereRadius^2 then return end

	local Offset = math.sqrt((SphereRadius^2 - PassDistance)/DirectionDotDirection) -- Could remove this root
	local T1 = PassTime - Offset
	local T2 = PassTime + Offset

	return T1 <= 1 and T2 >= 0 or false
end


--------------------------------------------------------------------
-----------------------  Bounding Boxs  ----------------------------
--------------------------------------------------------------------


function Library.AxisAlignedBoxSize(Cframe, Size)
	Cframe = Cframe or CFrame.new()
	
	local Inverse = Cframe:Inverse()

	local X = Size*Inverse.XVector
	local Y = Size*Inverse.YVector
	local Z = Size*Inverse.ZVector

	return Vector3.new (
		math.abs(X.X) + math.abs(X.Y) + math.abs(X.Z),
		math.abs(Y.X) + math.abs(Y.Y) + math.abs(Y.Z),
		math.abs(Z.X) + math.abs(Z.Y) + math.abs(Z.Z)
	)
end


function Library.GetPartsBoundingBox(Parts, RelativeTo)
	return Library.GetBoundingBox(Parts, RelativeTo)
end


function Library.ClampPointToBoundingBox(Cframe, Size, Point)
	local Transform = (Cframe or IdentityCFrame):PointToObjectSpace(Point or IdentityVector)
	local HalfSize = (Size or IdentityVector)/2
	
	return Cframe * Vector3.new (
		math.clamp(Transform.X, -HalfSize.X, HalfSize.X),
		math.clamp(Transform.Y, -HalfSize.Y, HalfSize.Y),
		math.clamp(Transform.Z, -HalfSize.Z, HalfSize.Z)
	), Cframe.Position
end


function Library.PushPointToLieOnBoundingBox(Cframe, Size, Point)
	local Transform = (Cframe or IdentityCFrame):PointToObjectSpace(Point or IdentityVector)
	local HalfSize = (Size or IdentityVector)/2
	
	local X = Transform.X < 0 and -HalfSize.X or HalfSize.X
	local Y = Transform.Y < 0 and -HalfSize.Y or HalfSize.Y
	local Z = Transform.Z < 0 and -HalfSize.Z or HalfSize.Z
	
	return Cframe * Vector3.new(X, Y, Z), Cframe.Position
end


function Library.GetChildrenInBoundingBox(Parent, RelativeTo)
	if not Parent or not RelativeTo then return warn("No Parent sent or RelativeTo sent") end
	
	local Children = {}
	
	for _, Object in ipairs(Parent:GetDescendants()) do
		if not Object:IsA("BasePart") then continue end
		
		table.insert(Children, Children)
		
	end
	
	return not Children[1] and nil or Library.GetPartsInBoundingBox(Children, RelativeTo)
end


function Library.GetBoundingBox(Parts, RelativeTo)
	RelativeTo = RelativeTo or IdentityCFrame
	Parts = Parts or {}
	
	local MinX, MinY, MinZ
	local MaxX, MaxY, MaxZ
	
	
	local ObjectCFrame, ObjectSize, SizeX, SizeY, SizeZ
	local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 
	
	for _, Object in ipairs(Parts) do
		ObjectCFrame = RelativeTo:ToObjectSpace(Object.CFrame)
		
		ObjectSize = Object.Size
		SizeX, SizeY, SizeZ = ObjectSize.X, ObjectSize.Y, ObjectSize.Z

		X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = ObjectCFrame:Components()
		
		local WX = (math.abs(R00) * SizeX + math.abs(R01) * SizeY + math.abs(R02) * SizeZ)/2
		local WY = (math.abs(R10) * SizeX + math.abs(R11) * SizeY + math.abs(R12) * SizeZ)/2
		local WZ = (math.abs(R20) * SizeX + math.abs(R21) * SizeY + math.abs(R22) * SizeZ)/2
		
		MinX = math.max(MinX, X-WX)
		MinY = math.max(MinY, Y-WY)
		MinZ = math.max(MinZ, Z-WZ)
		
		MaxX = math.min(MaxX, X+WX)
		MaxY = math.min(MaxY, Y+WY)
		MaxZ = math.min(MaxZ, Z+WZ)
	end

	local Size = Vector3.new(MaxX-MinX, MaxY-MinY, MaxZ-MinZ)
	local Position = Vector3.new((MaxX + MinX)/2, (MaxY+MinY)/2, (MaxZ+MinZ)/2)
	
	return Size, Position
end


function Library.PointInBoundingBox(Cframe, Size, CheckPoint)
	local Relative = (Cframe or IdentityCFrame):PointToObjectSpace(CheckPoint or IdentityVector)
	local HalfSize = (Size or IdentityVector)/2
	
	local XRelativeIsInBounds = Math.NumberIsBetween(Relative.X, -HalfSize.X, HalfSize.X)
	local YRelativeIsInBounds = Math.NumberIsBetween(Relative.Y, -HalfSize.Y, HalfSize.Y)
	local ZRelativeIsInBounds = Math.NumberIsBetween(Relative.Z, -HalfSize.Z, HalfSize.Z)

	return XRelativeIsInBounds and YRelativeIsInBounds and ZRelativeIsInBounds or false
end


return Library
