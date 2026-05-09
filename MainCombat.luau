--------------------------------------------

---Gilgamesh Gate Of Babylon Script

---By dev_raiden on Discord for HiddenDevs Application!

--------------------------------------------

-- [[ SERVICES ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

-- [[ PLAYER & CAMERA ]]
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootpart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- [[ ASSETS & MODULES ]]
local PortalTemplate = ReplicatedStorage.VFXFolder.Anime.GateOfBabylon:WaitForChild("Portal")
local vfxhelp = require(game.ReplicatedStorage.VFXHelper) -- Utility for emitting particles
local rock = require(game.ReplicatedStorage.Crater_Module) -- Handles ground/explosion debris
local shake = require(game.ReplicatedStorage.CameraShaker) -- Handles procedural camera shaking

-- [[ TWEEN CONFIGURATION ]]
-- Multiple TweenInfos used for different parts of the visual expansion and fading
local info4 = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local info5 = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

-- [[ CAMERA SHAKE INITIALIZATION ]]
local camShake = shake.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
	camera.CFrame = camera.CFrame * shakeCFrame
end)
camShake:Start()

-- Continuous loop to ensure camera shake is relative to the camera's current position
RunService.Heartbeat:Connect(function()
	camShake:SetReferencePosition(camera.CFrame.Position)
end)

-- [[ ABILITY ACTIVATION ]]
UIS.InputBegan:Connect(function(i, g)
	if g then return end -- Ignore input if player is typing in chat
	
	-- Checks if the key pressed matches the "Key" attribute assigned to the script
	if i.KeyCode == Enum.KeyCode[script:GetAttribute("Key")] then
		local root = rootpart.CFrame -- Current position/rotation of the player
		
		-- Loop to spawn 25 individual portals
		for i = 1, 25 do
			-- 1. SPATIAL MATH: Calculate random offsets for portal spawning (behind/above player)
			-- and random target offsets (where the swords should aim)
			local random1 = math.random(-120, 120)
			local random2 = math.random(20, 100)
			local random3 = math.random(-30, -120)
			local random4 = math.random(-65, 65)
			
			-- Portal CFrame math: Places portal in a shell around the player
			local randomcf = CFrame.new(random1, math.random(50, 150), random2)
			local randomcf2 = CFrame.new(random4, 0, random3)
			
			-- 2. PORTAL CREATION
			local portal = PortalTemplate:Clone()
			portal.Parent = workspace.Derbis
			-- Aim the portal from its random shell position toward the target area
			portal.PrimaryPart.CFrame = CFrame.lookAt((root * randomcf).Position, (root * randomcf2).Position)
			
			vfxhelp.Emit(portal) -- Play portal entry particles
			game.Debris:AddItem(portal, 8)
			
			-- Play portal appearance sound
			local sfx = game.ReplicatedStorage.SFX.Misc.Eerie.Appear:Clone()
			sfx.Parent = portal.PrimaryPart
			sfx.Volume = 4
			sfx:Play()
			
			local hit = false -- Variable to track if the projectile hits something
			
			-- 3. PROJECTILE FIRING (Delayed after portal opens)
			task.delay(2 + math.random() * 0.3, function()
				-- Firing SFX
				local sfxShoot = game.ReplicatedStorage.SFX.Combat.Swings.Shoot:Clone()
				sfxShoot.Parent = portal.PrimaryPart
				sfxShoot.Volume = 2.5
				sfxShoot:Play()
				
				-- SPIRAL VFX: Create a temporary mesh to visualize the projectile's "trail" or "muzzle flash"
				local meshvfx = game.ReplicatedStorage.Spiral:Clone()
				meshvfx.CFrame = portal.PrimaryPart.CFrame * CFrame.new(0, 0, -80) * CFrame.Angles(math.rad(-90), 0, 0)
				meshvfx.Parent = workspace.Derbis
				
				-- Tween the spiral trail to expand and fade
				local tween = game.TweenService:Create(meshvfx, TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
					Size = Vector3.new(45, 0, 45),
					Transparency = 1,
					CFrame = portal.PrimaryPart.CFrame * CFrame.new(0, 0, 10) * CFrame.Angles(math.rad(-90), 0, 0)
				})
				tween:Play()
				
				-- Localized camera shake for each fire event
				local shaketest = camShake:ShakeOnce(5, 5, 0, 0.35)
				shaketest.Position = portal.PrimaryPart.Position
				
				-- 4. SWORD PHYSICS
				local sword = game.ReplicatedStorage.VFXFolder.Anime.GateOfBabylon.Sword:Clone()
				sword.Parent = workspace.Derbis
				sword.PrimaryPart.CFrame = CFrame.lookAt(portal.PrimaryPart.Position, (root * randomcf2).Position) * CFrame.Angles(0, math.rad(180), math.rad(-180))
				sword.Sword.Anchored = false
				
				-- Apply velocity to propel the sword forward (multiplied by negative LookVector)
				local bv = Instance.new("BodyVelocity", sword.PrimaryPart)
				bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				bv.Velocity = (sword.PrimaryPart.CFrame.LookVector * -math.random(500, 1000))
				
				-- 5. COLLISION DETECTION (Heartbeat Loop)
				local rs
				local overpla = OverlapParams.new()
				overpla.FilterDescendantsInstances = {character, workspace.Derbis}
				overpla.FilterType = Enum.RaycastFilterType.Exclude
				
				local timeout = tick()
				rs = RunService.Heartbeat:Connect(function()
					-- Stop checking if projectile has lived longer than 2 seconds
					if tick() - timeout > 2 then rs:Disconnect() end
					
					-- Check if the sword hit any parts in a 15x15x15 box
					for _, v in pairs(workspace:GetPartBoundsInBox(sword.PrimaryPart.CFrame, Vector3.new(15, 15, 15), overpla)) do
						if v:IsA("BasePart") and v.CanTouch == true then
							hit = true
							rs:Disconnect()
							
							-- 6. IMPACT EFFECTS
							sword.Sword.Anchored = true
							bv:Destroy()
							
							-- Screen Flash VFX
							local screen = game.ReplicatedStorage.VFXFolder.ScreenEffect:Clone()
							screen.Parent = player.PlayerGui["Screen Effect"]
							local tw = game.TweenService:Create(screen, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {ImageTransparency = 1})
							tw:Play()
							
							-- Spiral Impact Mesh
							local impactSpiral = game.ReplicatedStorage.Spiral:Clone()
							impactSpiral.Position = sword.PrimaryPart.Position
							impactSpiral.Parent = workspace.Derbis
							local tweenImp = game.TweenService:Create(impactSpiral, TweenInfo.new(0.45), {Size = Vector3.new(70, 0, 70), Transparency = 1})
							tweenImp:Play()
							
							-- Ground/Debris Effect
							rock:ExplosionRocks({
								Position = sword.PrimaryPart.Position,
								Amount = 5,
								Trail = true
							})
							
							-- Sound & Camera Shake for Impact
							local sfxExp = game.ReplicatedStorage.SFX.Combat.Explosions["ULTRAKILL - EXPLOSION"]:Clone()
							sfxExp.Parent = sword.PrimaryPart
							sfxExp:Play()
							
							camShake:ShakeOnce(10, 10, 0, 0.35)
						end
					end
				end)
			end)
			-- Small staggered delay between each portal spawning for visual "flow"
			task.wait(0.03 + math.random() * 0.03)
		end
	end
end)
