----------------------------

---MAIN COMBAT SCRIPT

---dev_raiden on Discord

----------------------------

-- [[ SERVICES & MODULES ]]
local Events = game.ReplicatedStorage.Events
local Hitbox = require(game.ReplicatedStorage.Modules.EzHitbox)

-- [[ STATE MANAGEMENT ]]
-- Stores the timestamp of the last punch for each character model to handle combo resets
local LastPunch = {}

-- [[ LOGIC FUNCTIONS ]]

--- Handles the logic for cycling through the 4-hit combo sequence.
--- It uses attributes on the Character model to sync state across the server.
function ChangeCombo(Char: Model)
	-- Initialize combo attribute if it doesn't exist
	if not Char:GetAttribute('Combo') then
		Char:SetAttribute('Combo', 1)
	end

	local currentTime = tick()

	if LastPunch[Char] then
		-- Reset combo to 1 if the player waits too long (1.5s cooldown window)
		if (currentTime - LastPunch[Char]) >= 1.5 then
			Char:SetAttribute('Combo', 1)
		else
			-- Advance the combo or reset it back to 1 if the 4th hit was reached
			if Char:GetAttribute('Combo') >= 4 then
				Char:SetAttribute('Combo', 1)
			else
				Char:SetAttribute('Combo', Char:GetAttribute('Combo') + 1)
			end
		end
	else
		-- First time punching
		Char:SetAttribute('Combo', 1)
	end

	-- Update the character's last activity timestamp
	LastPunch[Char] = currentTime

	return Char:GetAttribute('Combo')
end

--- Utility function to create "State Tags". 
--- By parenting an Accessory (acting as a tag) to the Character, other scripts 
--- can check for "Stunned" or "NoM1" status using FindFirstChild.
function CreateInst(Name, P, T)
	local C = Instance.new("Accessory")
	C.Parent = P
	C.Name = Name
	game.Debris:AddItem(C, T) -- Automatically cleans up the tag after T seconds
end

-- [[ MAIN EVENT HANDLER ]]

Events.Punch.OnServerEvent:Connect(function(player)
	-- 1. VALIDATION: Ensure the character and its core components exist before proceeding
	local Char = player.Character
	if not Char then return end

	local Humanoid = Char.Humanoid
	if not Humanoid then return end

	local RootPart = Char.HumanoidRootPart
	if not RootPart then return end

	local Animator = Humanoid.Animator
	if not Animator then return end

	-- 2. DEBOUNCE/STUN CHECK: Prevent attacking if already mid-swing, stunned, or on "NoM1" cooldown
	if Char:GetAttribute("Attacking") == true or Char:FindFirstChild("NoM1") or Char:FindFirstChild("Stunned") then 
		return 
	end

	-- 3. COMBO CALCULATION: Determine which swing in the sequence to play
	local currentCombo = ChangeCombo(Char)

	-- If this is the "finisher" (Hit 4), apply a 1-second lockout (NoM1)
	if currentCombo >= 4 then
		CreateInst("NoM1", Char, 1)
	end

	-- 4. ANIMATION HANDLING: Fetch the corresponding animation from ServerStorage
	local animation = game.ServerStorage.M1s[currentCombo]
	if not animation then return end

	local Anim = Animator:LoadAnimation(animation):: AnimationTrack
	if not Anim then return end

	-- Set 'Attacking' attribute to true to lock out other actions until the animation ends
	Char:SetAttribute("Attacking", true)
	Anim.Priority = Enum.AnimationPriority.Action
	Anim:Play()

	-- Clean up 'Attacking' state once the swing finishes
	Anim.Stopped:Connect(function()
		Char:SetAttribute("Attacking", false)
	end)

	-- 5. HITBOX PARAMETERS: Define the impact of the current swing
	local hitboxSize = Vector3.new(5,5,5)
	local knockbackForce = 15
	local stunDuration = 0.8

	-- Buff the finisher hit with high knockback and longer stun
	if currentCombo >= 4 then
		knockbackForce = 122
		stunDuration = 1
	end

	-- Small delay before the hitbox activates to sync with the "active" frames of the animation
	task.wait(.08)

	-- 6. HITBOX EXECUTION: Uses the EzHitbox module to detect targets
	Hitbox:Create({
		Caster = Char,
		CFrame = RootPart.CFrame,
		Size = hitboxSize,
		Touched = function(Enemy: Model)
			if not Enemy or Enemy == Char then return end

			local EnemyHumanoid = Enemy:FindFirstChildOfClass("Humanoid")
			if not EnemyHumanoid then return end

			-- Apply damage
			EnemyHumanoid:TakeDamage(0.5)

			-- Play "Hit Reaction" animation on the enemy
			local hitAnim = game.ServerStorage.Hit['Hit1']
			if hitAnim then
				local EnemyAnimator = EnemyHumanoid.Animator
				if EnemyAnimator then
					local AnimHit = EnemyAnimator:LoadAnimation(hitAnim)
					if AnimHit then
						AnimHit:Play()
					end
				end
			end

			-- 7. PHYSICS (KNOCKBACK): 
			-- Apply a slight forward lunge to the attacker for "flow" (if not a finisher)
			if currentCombo < 4 then
				local bv = Instance.new("BodyVelocity")
				bv.Parent = RootPart
				bv.MaxForce = Vector3.new(1,1,1) * 1000000
				bv.P = 1250
				bv.Velocity = RootPart.CFrame.LookVector * knockbackForce
				game.Debris:AddItem(bv, 0.1)
			end

			-- Apply knockback to the enemy
			local enemyRoot = Enemy:FindFirstChild("HumanoidRootPart")
			if enemyRoot then
				local bv = Instance.new("BodyVelocity")
				bv.Parent = enemyRoot
				bv.MaxForce = Vector3.new(1,1,1) * 1000000
				bv.P = 1250
				bv.Velocity = RootPart.CFrame.LookVector * knockbackForce
				game.Debris:AddItem(bv, 0.1)
			end

			-- 8. STATUS EFFECT: Apply stun tag to the enemy to prevent them from counter-attacking
			CreateInst("Stunned", Enemy, stunDuration)
		end,
	})
end)
