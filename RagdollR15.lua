--[[
	Ragdoll Module for SYNTIN
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
	LeftLowerArm = {
		Type = "BallSocketConstraint";
		AttachmentName = "LeftWristRigAttachment";
		AttachedTo = "LeftHand";
		Limits = false;
	};
	RightLowerArm = {
		Type = "BallSocketConstraint";
		AttachmentName = "RightWristRigAttachment";
		AttachedTo = "RightHand";
		Limits = false;
	};
	LeftUpperArm = {
		Type = "HingeConstraint";
		AttachmentName = "LeftElbowRigAttachment";
		AttachedTo = "LeftLowerArm";
		Limits = true;
		LowerAngle = 0;
		UpperAngle = 135;
	};
	RightUpperArm = {
		Type = "HingeConstraint";
		AttachmentName = "RightElbowRigAttachment";
		AttachedTo = "RightLowerArm";
		Limits = true;
		LowerAngle = 0;
		UpperAngle = 135;
	};
	LeftLowerLeg = {
		Type = "BallSocketConstraint";
		AttachmentName = "LeftAnkleRigAttachment";
		AttachedTo = "LeftFoot";
		Limits = false;
	};
	RightLowerLeg = {
		Type = "BallSocketConstraint";
		AttachmentName = "RightAnkleRigAttachment";
		AttachedTo = "RightFoot";
		Limits = false;
	};
	LeftUpperLeg = {
		Type = "HingeConstraint";
		AttachmentName = "LeftKneeRigAttachment";
		AttachedTo = "LeftLowerLeg";
		Limits = true;
		LowerAngle = -135;
		UpperAngle = 0;
	};
	RightUpperLeg = {
		Type = "HingeConstraint";
		AttachmentName = "RightKneeRigAttachment";
		AttachedTo = "RightLowerLeg";
		Limits = true;
		LowerAngle = -135;
		UpperAngle = 0;
	};
	LeftLowerTorso = {
		Parent = "LowerTorso";
		Type = "BallSocketConstraint";
		AttachmentName = "LeftHipRigAttachment";
		AttachedTo = "LeftUpperLeg";
		Limits = false;
	};
	RightLowerTorso = {
		Parent = "LowerTorso";
		Type = "BallSocketConstraint";
		AttachmentName = "RightHipRigAttachment";
		AttachedTo = "RightUpperLeg";
		Limits = false;
	};
	NeckUpperTorso = {
		Parent = "UpperTorso";
		Type = "BallSocketConstraint";
		AttachmentName = "NeckRigAttachment";
		AttachedTo = "Head";
		Limits = true;
		TwistLimits = true;
	};
	WaistUpperTorso = {
		Parent = "UpperTorso";
		Type = "BallSocketConstraint";
		AttachmentName = "WaistRigAttachment";
		AttachedTo = "LowerTorso";
		Limits = true;
		TwistLimits = true;
	};
	LeftUpperTorso = {
		Parent = "UpperTorso";
		Type = "BallSocketConstraint";
		AttachmentName = "LeftShoulderRigAttachment";
		AttachedTo = "LeftUpperArm";
		Limits = false;
	};
	RightUpperTorso = {
		Parent = "UpperTorso";
		Type = "BallSocketConstraint";
		AttachmentName = "RightShoulderRigAttachment";
		AttachedTo = "RightUpperArm";
		Limits = false;
	};
}

-- Non-collision-constraint references
local ncConstraints = { 
	{
		Part0 = "UpperTorso";
		Part1 = "RightUpperArm";
	};
	{
		Part0 = "UpperTorso";
		Part1 = "LeftUpperArm";
	};
	{
		Part0 = "UpperTorso";
		Part1 = "LowerTorso";
	};
	{
		Part0 = "UpperTorso";
		Part1 = "Head";
	};
	{
		Part0 = "LowerTorso";
		Part1 = "LeftUpperLeg";
	};
	{
		Part0 = "LowerTorso";
		Part1 = "RightUpperLeg";
	};
	{
		Part0 = "LeftUpperArm";
		Part1 = "LeftLowerArm";
	};
	{
		Part0 = "LeftLowerArm";
		Part1 = "LeftHand";
	};
	{
		Part0 = "RightUpperArm";
		Part1 = "RightLowerArm";
	};
	{
		Part0 = "RightLowerArm";
		Part1 = "RightHand";
	};
	{
		Part0 = "LeftUpperLeg";
		Part1 = "LeftLowerLeg";
	};
	{
		Part0 = "LeftLowerLeg";
		Part1 = "LeftFoot";
	};
	{
		Part0 = "RightUpperLeg";
		Part1 = "RightLowerLeg";
	};
	{
		Part0 = "RightLowerLeg";
		Part1 = "RightFoot";
	};
}

-- References to any attachments that need to be rotated
local attachmentOrients = {	
	{
		Parent = "UpperTorso";
		Name = "WaistRigAttachment";
		Orientation = Vector3.new(0, 90, -90);
	};
	{
		Parent = "LowerTorso";
		Name = "WaistRigAttachment";
		Orientation = Vector3.new(0, 90, -90);
	};
	{
		Parent = "UpperTorso";
		Name = "NeckRigAttachment";
		Orientation = Vector3.new(0, -90, 90);
	};
	{
		Parent = "Head";
		Name = "NeckRigAttachment";
		Orientation = Vector3.new(0, -90, 90);
	};
}

local ragdolledEvent

local Ragdoll = {}
Ragdoll.__index = Ragdoll


function Ragdoll.new(player)
	local self = setmetatable({}, Ragdoll)
	
	self._player = player:IsA("Player") and player
	self._character = player:IsA("Player") and player.Character or player
	print(self._player.Parent.Name)
	self._humanoid = player.Character:FindFirstChild("Humanoid")
	
	-- Declares and intializes the ragdolled event
	ragdolledEvent = Instance.new("BindableEvent")
	self.Ragdolled = ragdolledEvent.Event
	
	self._humanoid:SetAttribute("Ragdolled", false)
	
	return self
end


function Ragdoll:Enable()
	
	-- We won't re-ragdoll the player if they're already ragdolled
	if self._humanoid:GetAttribute("Ragdolled") then return end
	
	-- Fire the ragdolled event
	ragdolledEvent:Fire(true)
	
	-- Leaving this enabled would kill the player, oof
	self._humanoid.RequiresNeck = false 
	
	-- This essentially "disables" the self._humanoid, allowing us to enable collisions
	self._humanoid:ChangeState(Enum.HumanoidStateType.Physics) 
	self._humanoid.Sit = true
	
	self._humanoid:SetAttribute("Ragdolled", true)
	
	-- Declares and initializes up the non-collision-constraints
	for _, v in ncConstraints do 
		local ncc = Instance.new("NoCollisionConstraint", self._character:FindFirstChild(v.Part0))
		CollectionService:AddTag(ncc, "RagdollSys")
		ncc.Part0 = self._character:FindFirstChild(v.Part0)
		ncc.Part1 = self._character:FindFirstChild(v.Part1)
	end
	
	-- Reorientates attachments
	for _, v in attachmentOrients do 
		self._character:FindFirstChild(v.Parent):FindFirstChild(v.Name).Orientation = v.Orientation
	end
	
	-- Declares and initializes the various constraints required to ragdoll
	for k, v in constraints do 
		local Parent
		if v.Parent then Parent = v.Parent else Parent = k end

		local constraint = Instance.new(v.Type, self._character:FindFirstChild(Parent))
		CollectionService:AddTag(constraint, "RagdollSys")
		constraint.Attachment0 = constraint.Parent:FindFirstChild(v.AttachmentName)
		constraint.Attachment1 = self._character:FindFirstChild(v.AttachedTo):FindFirstChild(v.AttachmentName)
		
		-- Sets up any constraint limits
		if v.Limits then 
			constraint.LimitsEnabled = true
			if v.LowerAngle then
				constraint.LowerAngle = v.LowerAngle
				constraint.UpperAngle = v.UpperAngle
			end
			if v.TwistLimits then constraint.TwistLimitsEnabled = true end
		end
	end

	for _, v in self._character:GetChildren() do
		
		-- Welds the HRP to the UpperTorso and disables collisions for it
		if v.Name == "HumanoidRootPart" then 
			local weld = Instance.new("WeldConstraint", v)
			CollectionService:AddTag(weld, "RagdollSys")
			weld.Part0 = v
			weld.Part1 = self._character:WaitForChild("UpperTorso")
			v.CanCollide = false
			v.Anchored = false
			
		-- Disables the animation motors
		elseif v:IsA("MeshPart") or v:IsA("BasePart") then 
			v.CanCollide = true
			v:FindFirstChildWhichIsA("Motor6D").Enabled = false
		end
	end
end


function Ragdoll:Disable()	
	
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
	
	-- Reorientates attachments back to their original orientation
	for _, v in attachmentOrients do
		self._character:FindFirstChild(v.Parent):FindFirstChild(v.Name).Orientation = Vector3.new(0, 0, 0)
	end
	
	self._humanoid.RequiresNeck = true
	
	-- Re-enabling the self._humanoid
	self._humanoid.Sit = false
	self._humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	
	self._humanoid:SetAttribute("Ragdolled", false)
	
	ragdolledEvent:Fire(false)
end


return Ragdoll
