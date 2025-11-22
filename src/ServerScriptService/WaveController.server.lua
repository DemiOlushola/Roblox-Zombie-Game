-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local BadgeService = game:GetService("BadgeService")
-----------------------------
-- VARIABLES --
-----------------------------
local GameStateEnum = require(ReplicatedStorage.Modules.Enums.GameStateEnum)
local GameCommsEnum = require(ReplicatedStorage.Modules.Enums.GameCommsEnum)
local BadgeEnum = require(ReplicatedStorage.Modules.Enums.BadgeEnum)

local gameEvent = ReplicatedStorage.Remotes.GameEvent
local respawnEvent = ReplicatedStorage.Remotes.GUI.Respawn
local zombies = ServerStorage.Zombies
local zombieSpawns = workspace.Spawns.ZombieSpawns:GetChildren()
local zombiesWorspace = workspace.Zombies

local zombieCountPerWave = {
	Wave1 = {Zombie = 12},
	Wave2 = {Zombie = 20},
	Wave3 = {Zombie = 19, ["Fast Zombie"] = 8},
	Wave4 = {Zombie = 24, ["Fast Zombie"] = 10},
	Wave5 = {Zombie = 24, ["Fast Zombie"] = 12, ["Tough Zombie"] = 4},
	Wave6 = {Zombie = 28, ["Fast Zombie"] = 16, ["Tough Zombie"] = 8},
	Wave7 = {Zombie = 28, ["Fast Zombie"] = 16, ["Tough Zombie"] = 10, ["Fast Zombie Boss"] = 2},
	Wave8 = {Zombie = 34, ["Fast Zombie"] = 20, ["Tough Zombie"] = 12, ["Fast Zombie Boss"] = 4, 
		["Tough Zombie Boss"] = 2},
	Wave9 = {Zombie = 36, ["Fast Zombie"] = 28, ["Tough Zombie"] = 16, ["Fast Zombie Boss"] = 5, 
		["Tough Zombie Boss"] = 4, ["Lightning Zombie"] = 8},
	Wave10 = {Zombie = 40, ["Fast Zombie"] = 28, ["Tough Zombie"] = 18, ["Fast Zombie Boss"] = 8, 
		["Tough Zombie Boss"] = 5, ["Lightning Zombie"] = 12},
	Wave11 = {Zombie = 44, ["Fast Zombie"] = 30, ["Tough Zombie"] = 20, ["Fast Zombie Boss"] = 8, 
		["Tough Zombie Boss"] = 6, ["Lightning Zombie"] = 14, ["Ultimate Zombie Boss"] = 1}
}


local waveCashRewards = {
	Wave1 = 20,
	Wave2 = 20,
	Wave3 = 20,
	Wave4 = 30,
	Wave5 = 30,
	Wave6 = 30,
	Wave7 = 40,
	Wave8 = 50,
	Wave9 = 60,
	Wave10 = 70
}

local soundsFolder = workspace.Sounds
local waveMusic = soundsFolder.WaveMusic:GetChildren()
local currentPlayingMusic = nil

local currentWave = 0
local rng = Random.new()


-- CONSTANTS --
local TOTAL_WAVES = 11
local WAIT_TIME_INTERMISSION = 60
local WAIT_TIME_START_INTERMISSION = 30


-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

local function awardBadge(playerId, badgeId)
	local success, result = pcall(function()
		return BadgeService:AwardBadge(playerId, badgeId)
	end)
	
	if not success then
		print("Failed to award badge: \n"..result)
	end
end

local function createHighlight(parent, properties)
	local highlight = Instance.new("Highlight")
	for property, value in properties do
		highlight[property] = value
	end
	highlight.Parent = parent
	return highlight
end

local function fadeSound(sound)
	if sound.IsPlaying then
		local fadeTween = TweenService:Create(sound, TweenInfo.new(3), {Volume = 0})
		sound:SetAttribute("OriginalVolume", sound.Volume)
		fadeTween:Play()
		fadeTween.Completed:Wait()
		sound:Stop()
	else
		if sound.Volume ~= 0 then
			sound:SetAttribute("OriginalVolume", sound.Volume)
		end
		sound.Volume = 0
		sound:Play()
		local fadeTween = TweenService:Create(sound, TweenInfo.new(3), {Volume = sound:GetAttribute("OriginalVolume")})
		fadeTween:Play()
		fadeTween.Completed:Wait()
	end
end

local function onStartIntermission()
	print("starting intermission")
	gameEvent:FireAllClients(GameCommsEnum.ToClient.UpdateText, "WAITING FOR PLAYERS...")
	Teams.Alive.PlayerAdded:Wait()
	currentPlayingMusic = soundsFolder.Intermission
	task.spawn(fadeSound, currentPlayingMusic)
	for i = WAIT_TIME_START_INTERMISSION, 1, -1 do
		if workspace:GetAttribute("GameState") ~= GameStateEnum.START_INTERMISSION then
			return
		end
		gameEvent:FireAllClients(GameCommsEnum.ToClient.UpdateText, "WAVES ARE STARTING IN "..i.." SECONDS!")
		task.wait(1)
	end
	if workspace:GetAttribute("GameState") ~= GameStateEnum.START_INTERMISSION then
		return
	end
	workspace:SetAttribute("GameState", GameStateEnum.WAVE_IN_PROGRESS)
end


local function onIntermission()
	print("intermission")
	task.spawn(fadeSound, currentPlayingMusic)
	currentPlayingMusic = soundsFolder.Intermission
	task.spawn(fadeSound, currentPlayingMusic)
	
	for i = WAIT_TIME_INTERMISSION, 1, -1 do
		if workspace:GetAttribute("GameState") ~= GameStateEnum.INTERMISSION then
			return
		end
		gameEvent:FireAllClients(GameCommsEnum.ToClient.UpdateText, "INTERMISSION: "..i.." SECONDS UNTIL NEXT WAVE!")
		task.wait(1)
	end
	if workspace:GetAttribute("GameState") ~= GameStateEnum.INTERMISSION then
		return
	end
	workspace:SetAttribute("GameState", GameStateEnum.WAVE_IN_PROGRESS)
end

local function onStartWave()
	print("wave in progress")
	gameEvent:FireAllClients(GameCommsEnum.ToClient.UpdateText, "WAVE STARTING...")
	soundsFolder.HordeHowl:Play()
	fadeSound(currentPlayingMusic)
	currentPlayingMusic = waveMusic[rng:NextInteger(1, #waveMusic)]
	task.spawn(fadeSound, currentPlayingMusic)
	
	currentWave += 1
	local zombiesToSpawn = {}
	for zombie, amount in zombieCountPerWave["Wave"..currentWave] do
		for i = 1, amount do
			local clone = zombies[zombie]:Clone()
			table.insert(zombiesToSpawn, clone)
		end
	end
	local zombiesLeft = #zombiesToSpawn
	
	gameEvent:FireAllClients(GameCommsEnum.ToClient.UpdateText, "WAVE "..currentWave.." IN PROGRESS! || "..zombiesLeft.. " ZOMBIES LEFT!")
	
	local spawnIndex = 1
	repeat
		local randomNum = rng:NextInteger(1, #zombiesToSpawn)
		zombiesToSpawn[randomNum].HumanoidRootPart.CFrame = zombieSpawns[spawnIndex].Attachment.WorldCFrame
		spawnIndex += 1
		if spawnIndex > #zombieSpawns then
			spawnIndex = 1
		end
		
		zombiesToSpawn[randomNum].Parent = zombiesWorspace
		
		zombiesToSpawn[randomNum].Humanoid.Died:Connect(function()
			zombiesLeft -= 1
			gameEvent:FireAllClients(GameCommsEnum.ToClient.UpdateText, "WAVE "..currentWave.." IN PROGRESS! || "..zombiesLeft.. " ZOMBIES LEFT!")
			
			if zombiesLeft == 1 then
				for _, zombie in zombiesWorspace:GetChildren() do
					if zombie.Humanoid.Health > 0 then
						createHighlight(zombie, {FillColor = Color3.fromRGB(255, 207, 15)})
					end
				end
			elseif zombiesLeft == 0 and workspace:GetAttribute("GameState") == GameStateEnum.WAVE_IN_PROGRESS then
				if currentWave ~= TOTAL_WAVES then
					for _, player in Players:GetPlayers() do
						player.leaderstats.Money.Value += waveCashRewards["Wave"..currentWave]
					end
					workspace:SetAttribute("GameState", GameStateEnum.INTERMISSION)
				else
					workspace:SetAttribute("GameState", GameStateEnum.GAME_OVER_WIN)

				end
			end
		end)
		
		table.remove(zombiesToSpawn, randomNum)
		task.wait(0.25)
	until #zombiesToSpawn <= 0 or workspace:GetAttribute("GameState") ~= GameStateEnum.WAVE_IN_PROGRESS

	--workspace:SetAttribute("GameState", GameStateEnum.INTERMISSION)

end

local function onGameOver()
	print("game over lose")
	gameEvent:FireAllClients(GameCommsEnum.ToClient.UpdateText, "GAME OVER...ZOMBIES WIN..")
	task.wait(10)
	workspace:SetAttribute("GameState", GameStateEnum.WAITING)

end

local function onGameOverWin()
	print("game over win")
	task.spawn(fadeSound, currentPlayingMusic)
	soundsFolder.Failure:Play()
	for _, player in Teams.Alive:GetPlayers() do
		awardBadge(player.UserId, BadgeEnum.VICTORY_BADGE.Id)
	end
	gameEvent:FireAllClients(GameCommsEnum.ToClient.UpdateText, "GAME OVER! YOU WIN!!!")
	task.wait(10)
	workspace:SetAttribute("GameState", GameStateEnum.WAITING)

end

local function onWaiting()
	print("cleanup")
	task.spawn(fadeSound, currentPlayingMusic)
	soundsFolder.Failure:Play()
	
	gameEvent:FireAllClients(GameCommsEnum.ToClient.UpdateText, "CLEANING UP GAME...")
	zombiesWorspace:ClearAllChildren()
	workspace.FilteringFolder.BulletHoles:ClearAllChildren()
	currentWave = 0
	for _, player in Players:GetPlayers() do
		player.leaderstats.Money.Value = 0
	end
	
	for _, alivePlayer in Teams.Alive:GetPlayers() do
		alivePlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
	end
	task.wait(5)
	for i = 10, 1, -1 do
		gameEvent:FireAllClients(GameCommsEnum.ToClient.UpdateText, "STARTING A NEW GAME IN "..i.. " SECONDS!")
		task.wait(1)
	end
	workspace:SetAttribute("GameState", GameStateEnum.START_INTERMISSION)

end


-----------------------------
-- HANDLERS --
-----------------------------

Players.PlayerAdded:Connect(function(plr)
	plr.Team = Teams.Dead
	
	plr.CharacterAdded:Connect(function(char)
		char.Humanoid.Died:Connect(function()
			plr.Team = Teams.Dead
		end)
	end)
end)

respawnEvent.OnServerEvent:Connect(function(plr)
	if workspace:GetAttribute("GameState") ~= GameStateEnum.START_INTERMISSION and workspace:GetAttribute("GameState") ~= GameStateEnum.INTERMISSION then
		return
	end
	
	plr.Team = Teams.Alive
	plr:LoadCharacter()
	local clone = ServerStorage.Tools.Knife:Clone()
	clone.Parent = plr.Backpack
end)


Teams.Alive.PlayerRemoved:Connect(function()
	if workspace:GetAttribute("GameState") == GameStateEnum.GAME_OVER 
		or workspace:GetAttribute("GameState") == GameStateEnum.GAME_OVER_WIN 
		or workspace:GetAttribute("GameState") == GameStateEnum.WAITING then
		return
	end
	
	local alivePlayers = Teams.Alive:GetPlayers()
	
	if #alivePlayers == 0 then
		workspace:SetAttribute("GameState", GameStateEnum.GAME_OVER)
	end
end)

local intermissionFunctions = {
	[GameStateEnum.START_INTERMISSION] = onStartIntermission,
	[GameStateEnum.INTERMISSION] = onIntermission,
	[GameStateEnum.WAVE_IN_PROGRESS] = onStartWave,
	[GameStateEnum.GAME_OVER] = onGameOver,
	[GameStateEnum.GAME_OVER_WIN] = onGameOverWin,
	[GameStateEnum.WAITING] = onWaiting,
}

workspace:GetAttributeChangedSignal("GameState"):Connect(function()
	local gameState = workspace:GetAttribute("GameState")
	local callback = intermissionFunctions[gameState]
	if callback then
		callback()
	end
end)

-----------------------------
-- MAIN --
-----------------------------

-----------------------------
--  --
-----------------------------

workspace:SetAttribute("GameState", GameStateEnum.START_INTERMISSION)
