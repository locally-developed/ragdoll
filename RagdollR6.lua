--[[
	Ragdoll Module
	Author: KasperPajak
	Date: 08/15/22
	Description:
	
		Handles ragdolling for both players and NPCs (characters).
		If called by the server, you must manually disable the
		player's movement before ragdolling. This module only
		disables the player controller if called on the client.
	
	-----------------------------------------------
	
	Constructor:
	
		ragdoll = Ragdoll.new(LocalPlayer or Player or Character)
		
	Methods:
		
		ragdoll:Enable()
		> Ragdolls the player/character
		
		ragdoll:Disable()
		> Stops ragdolling and resets the player/character
		
	Methods:
	
		ragdoll.Ragdolled(boolean)
		> Fires when a player's ragdoll state changes
			> Passes a boolean whether the player is
			  entering or leaving the ragdolled state
		
	-----------------------------------------------
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- Constraints used for ragdolling
local constraints = { 
	{
		Attachments = {
			{
				Part = "Torso";
				Position = Vector3.new(-1, 0.5, 0);
				Orientation = Vector3.new(0, 180, 0);
			};
			{
				Part = "Left Arm";
				Position = Vector3.new(0.5, 0.5, 0);
				Orientation = Vector3.new(0, 180, 0);
			};
		};
		TwistLowerAngle = 45;
		TwistUpperAngle = -180;
	};
	{
		Attachments = {
			{
				Part = "Torso";
				Position = Vector3.new(1, 0.5, 0);
				Orientation = Vector3.new(0, 0, 0);
			};
			{
				Part = "Right Arm";
				Position = Vector3.new(-0.5, 0.5, 0);
				Orientation = Vector3.new(0, 0, 0);
			};
		};
		TwistLowerAngle = -45;
		TwistUpperAngle = 180;
	};
	{
		Attachments = {
			{
				Part = "Torso";
				Position = Vector3.new(-1, -1, 0);
				Orientation = Vector3.new(0, 90, -90);
			};
			{
				Part = "Left Leg";
				Position = Vector3.new(-0.5, 1, 0);
				Orientation = Vector3.new(0, 90, -90);
			};
		};
		TwistLowerAngle = -45;
		TwistUpperAngle = 45;
	};
	{
		Attachments = {
			{
				Part = "Torso";
				Position = Vector3.new(1, -1, 0);
				Orientation = Vector3.new(0, 90, -90);
			};
			{
				Part = "Right Leg";
				Position = Vector3.new(0.5, 1, 0);
				Orientation = Vector3.new(0, 90, -90);
			};
		};
		TwistLowerAngle = -45;
		TwistUpperAngle = 45;
	};
	{
		Attachments = {
			{
				Part = "Torso";
				Position = Vector3.new(0, 1, 0);
				Orientation = Vector3.new(0, -90, 90);
			};
			{
				Part = "Head";
				Position = Vector3.new(0, -0.5, 0);
				Orientation = Vector3.new(0, -90, 90);
			};
		};
		TwistLowerAngle = -45;
		TwistUpperAngle = 45;
	};
}

-- Non-collision-constraint references
local ncConstraints = { 
	{
		Part0 = "Torso";
		Part1 = "Left Arm";
	};
	{
		Part0 = "Torso";
		Part1 = "Right Arm";
	};
	{
		Part0 = "Torso";
		Part1 = "Left Leg";
	};
	{
		Part0 = "Torso";
		Part1 = "Right Leg";
	};
	{
		Part0 = "Torso";
		Part1 = "Head";
	};
}

local ragdolledEvent

local Ragdoll = {}
Ragdoll.__index = Ragdoll


function Ragdoll.new(player)
	local self = setmetatable({}, Ragdoll)
	
	self._player = player:IsA("Player") and player
	self._character = player:IsA("Player") and player.Character or player
	self._humanoid = player.Character:FindFirstChild("Humanoid")
	
	-- Declares and intializes the ragdolled event
	ragdolledEvent = Instance.new("BindableEvent")
	self.Ragdolled = ragdolledEvent.Event
	
	self._humanoid:SetAttribute("Ragdolled", false)
	
	return self
end


function Ragdoll:Enable(collidable)
	collidable = collidable or false
	
	-- We won't re-ragdoll the player if they're already ragdolled
	if self._humanoid:GetAttribute("Ragdolled") then return end
	
	-- Fire the ragdolled event
	ragdolledEvent:Fire(true)
	
	-- Leaving this enabled would kill the player, oof
	self._humanoid.RequiresNeck = false 
	
	-- This essentially "disables" the self._humanoid, allowing us to enable collisions
	
	if collidable then
		self._humanoid:ChangeState(Enum.HumanoidStateType.Physics) 
		self._humanoid.Sit = true
	end
	
	self._humanoid:SetAttribute("Ragdolled", true)
	
	-- Declares and initializes up the non-collision-constraints
	for _, v in ncConstraints do 
		local ncc = Instance.new("NoCollisionConstraint", self._character:FindFirstChild(v.Part0))
		CollectionService:AddTag(ncc, "RagdollSys")
		ncc.Part0 = self._character:FindFirstChild(v.Part0)
		ncc.Part1 = self._character:FindFirstChild(v.Part1)
	end
	
	-- Declares and initializes the various constraints required to ragdoll
	for _, v in constraints do 
		local constraint = Instance.new("BallSocketConstraint", self._character:FindFirstChild(v.Attachments[1].Part))
		CollectionService:AddTag(constraint, "RagdollSys")
		
		local Attach0 = Instance.new("Attachment", self._character:FindFirstChild(v.Attachments[1].Part))
		local Attach1 = Instance.new("Attachment", self._character:FindFirstChild(v.Attachments[2].Part))
		CollectionService:AddTag(Attach0, "RagdollSys")
		CollectionService:AddTag(Attach1, "RagdollSys")
		
		Attach0.Position = v.Attachments[1].Position
		Attach0.Orientation = v.Attachments[1].Orientation
		
		Attach1.Position = v.Attachments[2].Position
		Attach1.Orientation = v.Attachments[2].Orientation
		
		constraint.Attachment0 = Attach0
		constraint.Attachment1 = Attach1
		
		-- Sets up constraint limits
		constraint.LimitsEnabled = true
		constraint.TwistLimitsEnabled = true
		
		constraint.TwistLowerAngle = v.TwistLowerAngle
		constraint.TwistUpperAngle = v.TwistUpperAngle
	end
	
	for _, v in self._character:GetChildren() do

		-- Welds the HRP to the UpperTorso and disables collisions for it
		if v.Name == "HumanoidRootPart" then 
			local weld = Instance.new("WeldConstraint", v)
			CollectionService:AddTag(weld, "RagdollSys")
			weld.Name = "RagdollWeld"
			weld.Part0 = v
			weld.Part1 = self._character:WaitForChild("Torso")
			v.CanCollide = false
			v.Anchored = false
			
		-- Enables collisions
		elseif v:IsA("BasePart") then 
			v.CanCollide = true
			
			-- Disables the animation motors
			if v.Name == "Torso" then
				for _, w in v:GetChildren() do
					if w:IsA("Motor6D") then w.Enabled = false end
				end
			end
		end
	end
end


function Ragdoll:Disable()	
	
	-- Prevents the player from standing up if knocked-out
	if self._humanoid:GetAttribute("Unconscious") then return end
	
	-- Here we delete everything we added in, along with re-enabling the animation motors and turning on collisions for the HRP
	for _, v in self._character:GetDescendants() do
		if table.find(CollectionService:GetTags(v), "RagdollSys") then
			v:Destroy()
		elseif v:IsA("Motor6D") then
			v.Enabled = true
		elseif v.Name == "HumanoidRootPart" then
			v.CanCollide = true
		end
	end
	
	self._humanoid.RequiresNeck = true
	
	-- Re-enabling the self._humanoid
	self._humanoid.Sit = false
	self._humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	
	self._humanoid:SetAttribute("Ragdolled", false)
	
	ragdolledEvent:Fire(false)
end


return Ragdoll
