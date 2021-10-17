-- 4thAxis
-- 8/10/21


local Library = {}

--------------------------------------------------------------------
---------------------------  Imports  ------------------------------
--------------------------------------------------------------------

--------------------------------------------------------------------
--------------------------  Constants  -----------------------------
--------------------------------------------------------------------

local Epsilon = 1e-6
Library.WaterDensity = 1 -- (mass/volume)
Library.Gravity = workspace.Gravity
Library.PhysicsClock = os.clock

-------------------------------------------------------------------
------------------------ Helpers/Private  -------------------------
-------------------------------------------------------------------

local function GetConnectedParts(Part)
	local Parts = Part:GetConnectedParts(true); table.insert(Parts, Part)

	return Parts
end


local function OverDamping(Damp, Delta, PhaseAngle)
	PhaseAngle = PhaseAngle or 1

	local Decay1 = math.exp((-Damp + PhaseAngle) * Delta)/(2*PhaseAngle)
	local Decay2 = math.exp((-Damp - PhaseAngle) * Delta)/(2*PhaseAngle)

	return Decay1 + Decay2, Decay1 - Decay2
end


local function CriticalDamping(Damp, Delta) 
	local Decay = math.exp(-Damp*Delta)/1

	return Decay, Decay * Delta
end


local function UnderDamping(Damp, Delta, PhaseAngle)
	local Decay = math.exp(-Damp * Delta)/(PhaseAngle or 1)

	return Decay * math.cos(PhaseAngle * Delta), Decay * math.sin(PhaseAngle * Delta)
end


local function GetDampRatio(Damp, Delta)
	Delta = Delta or Library.PhysicsClock()

	local DampSquared = Damp^2
	local PhaseAngle, Sine, Cosine

	if DampSquared < 1 then
		PhaseAngle = math.sqrt(1 - DampSquared)
		Cosine, Sine = UnderDamping(Damp, Delta, PhaseAngle)
	elseif DampSquared == 1 then
		PhaseAngle = 1
		Cosine, Sine = CriticalDamping(Damp, Delta) 
	else
		PhaseAngle = math.sqrt(DampSquared - 1)
		Cosine, Sine = OverDamping(Damp, Delta, PhaseAngle)
	end

	return PhaseAngle, Sine, Cosine
end


local function CheckOscillationFromNumber(Direction, Velocity, CustomEpsilon)
	SpringEpsilon = CustomEpsilon or Epsilon

	return math.abs(Direction) > SpringEpsilon or math.abs(Velocity) > SpringEpsilon
end


local function CheckOscillationFromVector(Direction, Velocity, CustomEpsilon)
	local EpsilonSquared = (CustomEpsilon or Epsilon)^2 -- Compensation for square root removal

	return Direction:Dot(Direction) > EpsilonSquared or Velocity:Dot(Velocity) > EpsilonSquared
end


--------------------------------------------------------------------
---------------------------  Numerics  -----------------------------
--------------------------------------------------------------------

function Library.GetTotalMass(Parts)
	if not Parts then return warn("No parts sent:", Parts) end
	if Parts:IsA("Part") then return Parts:GetMass() end

	local Mass = 0
	for _, Part in ipairs(Parts) do
		Mass += Part:GetMass()
	end

	return Mass
end


function Library.EstimateBuoyancyContribution(Parts)
	if not Parts then return warn("No parts sent:", Parts) end

	local TotalMass = 0
	local TotalVolumeApplicable = 0
	local TotalFloat = 0

	for _, Part in ipairs(Parts) do
		local Mass = Part:GetMass()
		TotalMass += Mass
		TotalFloat = TotalFloat - Mass * Library.Gravity
		if not Part.CanCollide then continue end

		local Volume = Part.Size.X * Part.Size.Y * Part.Size.Z
		TotalFloat = TotalFloat + Volume * Library.WaterDensity * Library.Gravity
		TotalVolumeApplicable += Volume
	end

	return TotalFloat, TotalMass, TotalVolumeApplicable
end


function Library.GetCenterOfMass(Parts)
	if not Parts then return warn("No parts sent:", Parts) end

	local Mass = 0
	local WeightedSum = Vector3.new()

	for _, Part in ipairs(Parts) do
		Mass += Part:GetMass()
		WeightedSum += Part:GetMass() * Part.Position
	end

	return WeightedSum/Mass, Mass
end


function Library.GetMomentOfInertia(Part, Axis, Origin)
	if not Part or not Axis or not Origin then return warn("Incorrect parameters:", Part, Axis, Origin) end

	local Size = Part.Size
	local Position = Part.Position
	local Cframe = Part.CFrame
	local Mass = Part:GetMass()

	local Radius  = (Position - Origin):Cross(Axis)
	local Size2 = Size^2
	local SizeAxis = Cframe:VectorToObjectSpace(Axis)
	
	local InertiaPos = Mass * Radius:Dot(Radius)
	local InertiaDirection = (Vector3.new(Size2.Y+Size2.Z, Size2.Z+Size2.X, Size2.X+Size2.Y)):Dot(SizeAxis^2)*Mass/12

	return InertiaPos + InertiaDirection
end


function Library.GetBodyMomentOfInertia(Parts, Axis, Origin)
	if not Parts or not Axis or not Origin then return warn("Incorrect parameters:", Parts, Axis, Origin) end

	local TotalBodyInertia = 0
	for _, Part in ipairs(Parts) do
		TotalBodyInertia +=  Library.GetMomentOfInertia(Part, Axis, Origin)
	end

	return TotalBodyInertia
end


--------------------------------------------------------------------
----------------------------  Forces  ------------------------------
--------------------------------------------------------------------

function Library.ApplyForce(Part, Force, ForcePosition)
	ForcePosition = ForcePosition or Part.Position
	
	local Parts = GetConnectedParts(Part)
	local CenterOfMass, Mass = Library.GetCenterOfMass(Parts)
	local Offset = (CenterOfMass - ForcePosition)
	local Torque = Offset:Cross(Force)

	local MomentOfInertia = Library.GetBodyMomentOfInertia(Parts, Torque, CenterOfMass)
	local Acceleration = Force/Mass
	local RotAcceleration

	RotAcceleration = MomentOfInertia ~= 0 and Torque/MomentOfInertia or Vector3.new()
	Part.RotVelocity += RotAcceleration
	Part.Velocity += Acceleration
end


function Library.AcceleratePart(Part, EmittingPart, Acceleration)
	local Force = Acceleration * Part:GetMass()
	local Position = Part.Position

	Library.ApplyForce(Part, Force, Position)
	Library.ApplyForce(EmittingPart, -Force, Position)
end


--------------------------------------------------------------------
------------------------  Harmonic Motions  ------------------------
--------------------------------------------------------------------


function Library.CreateSpringObject(InitialTarget, Damp, Speed, Velocity)
	InitialTarget = InitialTarget or 1

	return {
		Target = InitialTarget,
		Damp = Damp or 1,
		Speed = Speed or 1,
		Velocity = Velocity or 0,
		Position = InitialTarget,
		Time = Library.PhysicsClock(),
	}
end


function Library.GetSpringOscillation(SpringObject, Now)
	SpringObject = SpringObject or Library.NewSpringObject()

	local Position = SpringObject.Position
	local Velocity = SpringObject.Velocity
	local Target = SpringObject.Target
	local Damp = SpringObject.Damp
	local Speed = SpringObject.Speed

	local Delta = Speed * ((Now or Library.PhysicsClock()) - SpringObject.Time)
	local PhaseAngle, Sine, Cosine = GetDampRatio(Damp, Delta)

	local A1 = PhaseAngle * Cosine + Damp * Sine
	local A2 = 1 - (PhaseAngle * Cosine + Damp * Sine)
	local A3 = Sine/Speed

	local B1 = -Speed * Sine
	local B2 = Speed * Sine
	local B3 = PhaseAngle * Cosine - Damp * Sine

	return A1 * Position + A2 * Target + A3 * Velocity, B1 * Position + B2 * Target + B3 * Velocity
end


function Library.GetVelocityAdjustment(Velocity, Dampen, Speed) 
	Velocity = Velocity or 1
	Dampen = Dampen or 1
	Speed = Speed or 1

	return Velocity*(2*Dampen/Speed)
end


function Library.ImpulseSpringVelocity(SpringObject, Velocity)
	(SpringObject or Library.NewSpringObject()).Velocity += Velocity
end


function Library.SkipOscillation(SpringObject, Delta)
	local Time = Library.PhysicsClock()
	local Position, Velocity = Library.CalculateSpringOscillation(Time + Delta or Library.PhysicsClock())
	
	SpringObject.Position = Position
	SpringObject.Velocity = Velocity
	SpringObject.Time = Time
end


function Library.IsSpringAtEquilibrium(SpringObject, CustomEpsilon)
	SpringObject = SpringObject or Library.NewSpringObject()

	local Velocity = SpringObject.Velocity or 0
	local Target = SpringObject.Target
	local Position = SpringObject.Position
	local Direction = math.abs(Position - Target)
	local Oscillating

	if typeof(Target) == "Vector3" then 
		Oscillating = CheckOscillationFromVector(Direction, Velocity, SpringEpsilon)
	elseif type(Target) == "number" then
		Oscillating = CheckOscillationFromNumber(Direction, Velocity, SpringEpsilon)
	end

	return Oscillating, Oscillating and Position or Target
end


return Library
