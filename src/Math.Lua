-- 4thAxis
-- 6/1/21

local Library = {}


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

local StudsPerMeter = 3.57
local SpeedOfSoundMPS = 343 -- (Meters Per Second)

--------------------------------------------------------------------
---------------------------  Numerics  -----------------------------
--------------------------------------------------------------------


function Library.Near(Num1, Num2, OffBy)
	return math.abs(Num1 - Num2) <= (OffBy or 5)
end


function Library.NumberIsBetween(Number, Min, Max)
	return Number >= Min and Number <= Max
end


function Library.ExpandNumber(Number, Expansion)
	Expansion = math.max(1, Expansion or 1)	

	return math.round(Number/Expansion) * Expansion
end


function Library.Round(Number, Decimals)
	if not Number or Number < 0 then return Number end
	local Precision = math.max(1, 10 ^ math.max(1, Decimals or 1))

	return math.round(Number * Precision) / Precision
end


function Library.StudsToMeters(Studs)
	return (Studs or 1)/StudsPerMeter
end


function Library.StudsToKilometers(Studs)
	return (Studs or 1)/StudsPerMeter/1000
end


function Library.GetSoundDelaySeconds(Studs)
	return Library.StudsToMeters(Studs or 1)/SpeedOfSoundMPS
end


--------------------------------------------------------------------
----------------------------  Vectors  -----------------------------
--------------------------------------------------------------------

function Library.GetVectorComponents(Vector)
	Vector = Vector or Vector3.new()

	return Vector.X, Vector.Y, Vector.Z
end


function Library.RoundVector(Vector, ToDecimals)
	local Round = ToDecimals and Library.Round or math.round
	local X, Y, Z = Library.GetVectorComponents(Vector)

	return Vector3.new(Round(X), Round(Y), Round(Z))
end


function Library.ExpandVectorToGrid(Vector, Expansion)
	Vector = Vector or IdentityVector
	Expansion = Expansion or 1

	return Vector3.new (Library.ExpandNumber(Vector.X, Expansion), Library.ExpandNumber(Vector.Y, Expansion), Library.ExpandNumber(Vector.Z, Expansion)
	)
end


function Library.ElevationBetweenVectors(VectorA, VectorB)
	if not VectorA or not VectorB then return 0 end

	local Delta =  VectorB - VectorA
	local Hypotenuse = Delta.Magnitude
	local Angle = -math.asin(Delta.Y/Hypotenuse)

	return 180 * Angle/math.pi
end


function Library.GetClosest(Pos1, Pos2)
	return Pos1:Dot(Pos1) > Pos2:Dot(Pos2) and Pos1 or Pos2
end


--------------------------------------------------------------------
--------------------------  Orthogonals  ---------------------------
--------------------------------------------------------------------

function Library.DecomposeCFrameToVectors(Cframe)
	Cframe = Cframe or CFrame.new()

	return  {
		Cframe.LookVector,
		Cframe.BackVector,
		Cframe.RightVector,
		Cframe.LeftVector,
		Cframe.UpVector,
		Cframe.DownVector,
	}
end


function Library.GetClosestVector(Vectors, UnitVector)
	Vectors = Vectors or {}
	UnitVector = UnitVector or IdentityVector.Unit

	local BestAngle = -math.huge
	local Best

	for _, Vector in ipairs(Vectors) do
		local Angle = Vector:Dot(UnitVector)

		if Angle > BestAngle then
			BestAngle = Angle
			Best = Vector
		end
	end

	return Best
end


function Library.SnapCFrameTo(Cframe, snapToCFrame)
	Cframe = Cframe or IdentityCFrame

	local Options = Library.DecomposeCFrameToVectors(snapToCFrame or IdentityCFrame)
	local Right = Library.GetClosestVector(Options, Cframe.RightVector)
	local Up = Library.GetClosestVector(Options, Cframe.UpVector)

	if not Right or not Up then return warn("Failed to find Up or Right Vector:", RightVector, UpVector) end

	return CFrame.fromMatrix(Cframe.Position, Right, Up)
end

--------------------------------------------------------------------
--------------------------  Axis Angles  ---------------------------
--------------------------------------------------------------------


function Library.RotateFromAxisAngle(Vector, Axis, Angle)
	Axis = Axis.Unit
	
	local Projection = Axis:Dot(Vector) * Axis
	local Rotation = Vector - Projection

	return Projection + Rotation * math.cos(Angle) + Axis:Cross(Rotation) * math.sin(Angle)
end


function Library.AxisAngleToCFrame(AxisAngle, Position)
	Position = Position or IdentityVector

	return CFrame.fromAxisAngle(AxisAngle, AxisAngle.Magnitude) or CFrame.new(Position) + Position
end


function Library.AxisAngleFromCFrame(Cframe)
	Cframe = Cframe or IdentityCFrame
	local Axis, Angle = Cframe:ToAxisAngle()

	return Axis*Angle, Cframe.Position
end

--------------------------------------------------------------------
-----------------------------  Twists  -----------------------------
--------------------------------------------------------------------


function Library.SwingTwist(Cframe, Direction)
	Cframe = Cframe or CFrame.new()
	Direction = Direction or Vector3.new()

	local Axis, Theta = Cframe:ToAxisAngle()
	local W, V = math.cos(Theta/2), math.sin(Theta/2)*Axis

	local Projection = V:Dot(Direction)*Direction
	local Twist = CFrame.new(0, 0, 0, Projection.X, Projection.Y, Projection.Z, W)
	local Swing = Cframe * Twist:Inverse()

	return Swing, Twist
end


function Library.TwistAngle(Cframe, Direction)
	Cframe = Cframe or CFrame.new()
	Direction = Direction or Vector3.new()

	local Axis, Theta = Cframe:ToAxisAngle()
	local W, V = math.cos(Theta/2), math.sin(Theta/2)*Axis

	local Projection = V:Dot(Direction)*Direction
	local Twist = CFrame.new(0, 0, 0, Projection.X, Projection.Y, Projection.Z, W)

	return math.sign(V:Dot(Direction))*Twist:ToAxisAngle()
end


--------------------------------------------------------------------
----------------------------  Matrices  ----------------------------
--------------------------------------------------------------------

function Library.TransposeMatrix(XMatrix, YMatrix, ZMatrix)
	XMatrix = XMatrix or IdentityVector
	YMatrix = YMatrix or IdentityVector
	ZMatrix = ZMatrix or IdentityVector

	return Vector3.new(XMatrix.X, YMatrix.X, ZMatrix.X), 
		Vector3.new(XMatrix.Y, YMatrix.Y, ZMatrix.Y), 
		Vector3.new(XMatrix.Z, YMatrix.Z, ZMatrix.Z)
end


function Library.Determinant(XMatrix, YMatrix, ZMatrix)
	if XMatrix == IdentityVector or YMatrix == IdentityVector or ZMatrix == IdentityVector then return 0 end

	return XMatrix.X * YMatrix.Y * ZMatrix.Z + 
		XMatrix.Y * YMatrix.Z * ZMatrix.X + 
		XMatrix.Z * YMatrix.X * ZMatrix.Z - 
		XMatrix.Z * YMatrix.Y * ZMatrix.X - 
		XMatrix.Y * YMatrix.X * ZMatrix.Z - 
		XMatrix.X * YMatrix.Z * ZMatrix.Y
end


function Library.CoFactor(XMatrix, YMatrix, ZMatrix)
	local Determinant = Library.Determinant(XMatrix, YMatrix, ZMatrix)

	return Vector3.new((YMatrix.Y * ZMatrix.Z - ZMatrix.Y * YMatrix.Z) /Determinant,-(YMatrix.X * ZMatrix.Z - ZMatrix.X * YMatrix.Z) /Determinant,(YMatrix.X * ZMatrix.Y - ZMatrix.X * YMatrix.Y) /Determinant),
		   Vector3.new(-(XMatrix.Y * ZMatrix.Z - ZMatrix.Y * XMatrix.Z) /Determinant,(XMatrix.X * ZMatrix.Z - ZMatrix.X * XMatrix.Z) /Determinant,-(XMatrix.X * ZMatrix.Y - ZMatrix.X * XMatrix.Y) /Determinant),
	       Vector3.new((XMatrix.Y * YMatrix.Z - YMatrix.Y * XMatrix.Z) /Determinant,-(XMatrix.X * YMatrix.Z - YMatrix.X * XMatrix.Z) /Determinant,(XMatrix.X * YMatrix.Y - YMatrix.X * XMatrix.Y) /Determinant)
end


function Library.Inverse(XMatrix, YMatrix, ZMatrix)	
	return Library.Transpose(Library.CoFactor(XMatrix, YMatrix, ZMatrix))
end


function Library.MultiplyByMatrix(Vector, XMatrix, YMatrix, ZMatrix)
	return (XMatrix * Vector.X) + (YMatrix * Vector.Y) + (ZMatrix * Vector.Z)
end


function Library.PlusMatrix(TransXMatrix, TransYMatrix, TransZMatrix, XMatrix, YMatrix, ZMatrix)

	return Library.MultiplyByMatrix(XMatrix,  TransXMatrix, TransYMatrix, TransZMatrix),
		   Library.MultiplyByMatrix(YMatrix, TransXMatrix, TransYMatrix, TransZMatrix),
	       Library.MultiplyByMatrix(ZMatrix, TransXMatrix, TransYMatrix, TransZMatrix)
end


function Library.ToMatrix(TransXMatrix, TransYMatrix, TransZMatrix, XMatrix, YMatrix, ZMatrix)
	local InverseXMatrix, InverseYMatrix, InverseZMatrix = Library.Inverse(XMatrix, YMatrix, ZMatrix)

	XMatrix,YMatrix,ZMatrix = Library.PlusMatrix(TransXMatrix, TransYMatrix, TransZMatrix, Library.PlusMatrix(InverseXMatrix, InverseYMatrix, InverseZMatrix, XMatrix,YMatrix,ZMatrix))

	return XMatrix, YMatrix, ZMatrix
end


function Library.MatrixFromVector(Vector)
	local XVectorLength = Vector3.new(Vector.Z, 0, Vector.X).Magnitude
	local ZMatrix = Vector
	local XMatrix = Vector3.new()

	if Vector.Z == 0 then 
		XMatrix = Vector.X == 0 and Vector3.new(Vector.Z/math.abs(Vector.Z), 0, 0) or Vector3.new(Vector.Z/XVectorLength, 0, -Vector.X/XVectorLength)

		return XMatrix, ZMatrix:Cross(XMatrix), ZMatrix 
	end

	XMatrix = Vector.X == 0 and RightVector or Vector3.new(0, 0, -Vector.X/math.abs(Vector.X))

	return XMatrix, ZMatrix:Cross(XMatrix), ZMatrix	
end


--------------------------------------------------------------------
------------------------  Transformations  -------------------------
--------------------------------------------------------------------

function Library.RotateFromX(RotX, TranXMatrix, TranYMatrix, TranZMatrix)
	local CosX = math.cos(RotX)
	local SinX = math.sin(RotX)

	local XMatrix = Library.MultiplyByMatrix(RightVector, TranXMatrix, TranYMatrix, TranZMatrix)
	local YMatrix = Library.MultiplyByMatrix(Vector3.new(0, CosX, SinX), TranXMatrix, TranYMatrix, TranZMatrix)
	local ZMatrix = Library.MultiplyByMatrix(Vector3.new(0, -SinX, CosX), TranXMatrix, TranYMatrix, TranZMatrix)

	return Library.ToMatrix(TranXMatrix, TranYMatrix, TranZMatrix, XMatrix, YMatrix, ZMatrix)
end


function Library.RotateFromY(RotY, TranXMatrix, TranYMatrix, TranZMatrix)
	local CosY = math.cos(RotY)
	local SinY = math.sin(RotY)

	local XMatrix = Library.MultiplyByMatrix(Vector3.new(CosY, 0, -SinY), TranXMatrix, TranYMatrix, TranZMatrix)
	local YMatrix = Library.MultiplyByMatrix(UpVector, TranXMatrix, TranYMatrix, TranZMatrix)
	local ZMatrix = Library.MultiplyByMatrix(Vector3.new(SinY, 0, CosY), TranXMatrix, TranYMatrix, TranZMatrix)

	return Library.ToMatrix(TranXMatrix, TranYMatrix, TranZMatrix, XMatrix, YMatrix, ZMatrix)
end


function Library.RotateZ(RotZ, TranXMatrix, TranYMatrix, TranZMatrix)
	local CosZ = math.cos(RotZ)
	local SinZ = math.sin(RotZ)

	local XMatrix = Library.MultiplyByMatrix(Vector3.new(CosZ, SinZ, 0), TranXMatrix,TranYMatrix, TranZMatrix)
	local YMatrix = Library.MultiplyByMatrix(Vector3.new(-SinZ, CosZ, 0), TranXMatrix, TranYMatrix, TranZMatrix)
	local ZMatrix = Library.MultiplyByMatrix(FrontVector, TranXMatrix, TranYMatrix, TranZMatrix)

	return Library.ToMatrix(TranXMatrix, TranYMatrix, TranZMatrix, XMatrix, YMatrix, ZMatrix)
end


--------------------------------------------------------------------
-----------------------------  Rays  -------------------------------
--------------------------------------------------------------------

function Library.GetRayReflection(Vector, Normal) 
	if not Vector and not Normal then return 0 end

	return -2 * Vector.Unit:Dot(Normal) * Normal + Vector
end


function Library.GetClosestPointOnRay(Vector, VectorOrigin, Point)
	return VectorOrigin + Vector.Unit * (Vector:Dot(Point - VectorOrigin))
end


return Library

