# Ragdoll
Simple yet robust ragdoll module for Roblox Humanoids.

Constructor:
```lua
ragdoll = Ragdoll.new(LocalPlayer or Player or Character)
```
Methods:
```lua
ragdoll:Enable()
ragdoll:Disable()
```
Events:
```lua
ragdoll.Ragdolled(boolean isRagdolled): RBXScriptSignal  
```

Example:
```lua
Ragdoll = require(RagdollR15)

ragdoller = Ragdoll.new(game:GetService("PlayerService").LocalPlayer)

ragdoller.Ragdolled:Connect(function(isRagdolled)
    task.wait(3)
    if isRagdolled then ragdoller:Disable() end
end)

ragdoller:Enable()
```
