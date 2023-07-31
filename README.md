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
RagdollR15 = require(RagdollR15)

ragdoll = RagdollR15.new(game:GetService("PlayerService").LocalPlayer)

ragdoll.Ragdolled.Event:Connect(function(isRagdolled)
    task.wait(3)
    if isRagdolled then ragdoll:Disable() end
end)

ragdoll:Enable()
```
