-- 4thAxis
-- 8/13/21

local Library = {}


-------------------------------------------------------------------
------------------------ Helpers/Private  -------------------------
-------------------------------------------------------------------

local function AddLengths(Lengths)
	local Total = 0
	
	for _, Length in pairs(Lengths) do
		Total += Length
	end

	return Total
end

--------------------------------------------------------------------
-----------------------  Rig Utilities  ----------------------------
--------------------------------------------------------------------

function Library.SearchForRigAttachment(Character, PartName, AttachmentName)
	local Part = Character:FindFirstChild(PartName) or Character:WaitForChild(PartName)
	if not Part then return end

	return Part:FindFirstChild(AttachmentName) or Part:WaitForChild(AttachmentName)
end


function Library.GetRootPartYOffset(Humanoid)
	local RootPart = Humanoid.RootPart
	if not RootPart then return end

	return Humanoid.HipHeight + RootPart.Size.Y/2
end


function Library.GetRigLength(Character, PartName, RigAttachment0, RigAttachment1)
	local Attachment0 = Library.SearchForRigAttachment(Character, PartName, RigAttachment0)
	local Attachment1 = Library.SearchForRigAttachment(Character, PartName, RigAttachment1)
	
	if not Attachment0 or not Attachment1 then return end

	return (Attachment0.Position - Attachment1.Position).Magnitude
end



function Library.GetUpperArmRigLength(Character, Side)
	return Library.GetRigLength(Character, Side.."UpperArm", Side.."ShoulderRigAttachment", Side.."ElbowRigAttachment")
end


function Library.GetLowerArmRigLength(Character, Side)
	return Library.GetRigLength(Character, Side.."LowerArm", Side.."ElbowRigAttachment", Side.."WristRigAttachment")
end


function Library.GetWristToGripLength(character, Side)
	return Library.GetRigLength(character, Side.."Hand", Side.."WristRigAttachment", Side.."GripAttachment")
end


function Library.GetArmRigToGripLength(Character, Side)
	return AddLengths {Library.GetUpperArmRigLength(Character, Side), Library.GetLowerArmRigLength(Character, Side),Library.GetWristToGripLength(Character, Side)}
end


return Library
