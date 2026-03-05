local Acrylic = {};
Acrylic.__index = Acrylic;

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local CurrentCamera = workspace.CurrentCamera

local ActiveAcrylic = {}
local AcrylicParts = {}

local DepthOfFieldEffect = Instance.new("DepthOfFieldEffect")
DepthOfFieldEffect.FarIntensity = 0
DepthOfFieldEffect.NearIntensity = 0.3
DepthOfFieldEffect.InFocusRadius = 0
DepthOfFieldEffect.FocusDistance = 0.25
DepthOfFieldEffect.Parent = Lighting

function IntersectRay(Position, Normal, Origin, Direction)

	local _Normal = Normal
	local _Direction = Direction
	local _Origin = Origin - Position
	local _Numerator = _Normal.X * _Origin.X + _Normal.Y * _Origin.Y + _Normal.Z * _Origin.Z
	local _Denominator = _Normal.X * _Direction.X + _Normal.Y * _Direction.Y + _Normal.Z * _Direction.Z
	
	return Origin + (-_Numerator / _Denominator) * _Direction

end

function Acrylic.new(Options)
	
	Options = Options or {}

	local self = setmetatable({
		
		Object = Options.Object,
		Intensity = Options.Intensity or 0.3,
		
	}, Acrylic)

	assert(self.Object, "Acrylic requires an Object")

	local Frame = self.Object

	local IgnoreInset = false
	local Current = Frame
	
	while true do
		
		Current = Current.Parent
		
		if Current and Current:IsA("ScreenGui") then
			
			IgnoreInset = Current.IgnoreGuiInset
			
			break
			
		elseif Current == nil then
			
			break
			
		end
		
	end

	local Part = Instance.new("Part")
	Part.Anchored = true
	Part.CanCollide = false
	Part.CanTouch = false
	Part.Transparency = 1 - 1e-7
	Part.Material = Enum.Material.Glass
	Part.Size = Vector3.new(1, 1, 1) * 0.009
	Part.Parent = CurrentCamera

	local BlockMesh = Instance.new("BlockMesh")
	BlockMesh.Parent = Part

	self.Part = Part
	self.BlockMesh = BlockMesh
	self.IgnoreInset = IgnoreInset

	table.insert(ActiveAcrylic, self)
	table.insert(AcrylicParts, Part)

	return self
	
end

local function Update(Object)
	
	local Frame = Object.Object
	local Part = Object.Part
	local Mesh = Object.BlockMesh

	if not Frame.Visible then
		
		Part.Transparency = 1
		return
		
	end

	Part.Transparency = 1 - 1e-7

	local Corner0 = Frame.AbsolutePosition
	local Corner1 = Frame.AbsolutePosition + Frame.AbsoluteSize

	local Ray0, Ray1
	
	if Object.IgnoreInset then
		
		Ray0 = CurrentCamera:ViewportPointToRay(Corner0.X, Corner0.Y, 1)
		Ray1 = CurrentCamera:ViewportPointToRay(Corner1.X, Corner1.Y, 1)
		
	else
		
		Ray0 = CurrentCamera:ScreenPointToRay(Corner0.X, Corner0.Y, 1)
		Ray1 = CurrentCamera:ScreenPointToRay(Corner1.X, Corner1.Y, 1)
		
	end

	local _Origin = CurrentCamera.CFrame.Position + CurrentCamera.CFrame.LookVector * (0.05 - CurrentCamera.NearPlaneZ)
	local _Normal = CurrentCamera.CFrame.LookVector

	local Position0 = IntersectRay(_Origin, _Normal, Ray0.Origin, Ray0.Direction)
	local Position1 = IntersectRay(_Origin, _Normal, Ray1.Origin, Ray1.Direction)

	Position0 = CurrentCamera.CFrame:PointToObjectSpace(Position0)
	Position1 = CurrentCamera.CFrame:PointToObjectSpace(Position1)

	local Size   = Position1 - Position0
	local Center = (Position0 + Position1) / 2

	Mesh.Offset = Center
	Mesh.Scale  = Size / 0.01
	
end

function Acrylic.Update()
	
	DepthOfFieldEffect.FocusDistance = 0.25 - CurrentCamera.NearPlaneZ
	DepthOfFieldEffect.NearIntensity = ActiveAcrylic[1] and ActiveAcrylic[1].Intensity or 0.3

	for _, Object in ipairs(ActiveAcrylic) do
		
		Update(Object)
		
	end

	local CFrame = table.create(#AcrylicParts, CurrentCamera.CFrame)
	workspace:BulkMoveTo(AcrylicParts, CFrame, Enum.BulkMoveMode.FireCFrameChanged)
	
end

RunService:BindToRenderStep(
	
	"AcrylicUpdate",
	Enum.RenderPriority.Camera.Value + 1,
	Acrylic.Update
	
)

function Acrylic:Destroy()
	
	self.Part:Destroy()

	for i, v in ipairs(ActiveAcrylic) do
		
		if v == self then
			
			table.remove(ActiveAcrylic, i)
			
			break
			
		end
		
	end

	for i, v in ipairs(AcrylicParts) do
		
		if v == self.Part then
			
			table.remove(AcrylicParts, i)
			
			break
			
		end
		
	end
	
end

return Acrylic
