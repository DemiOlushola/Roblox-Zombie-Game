# Roblox-Zombie-Game-Wave-System
Et serverstyret wave-baseret zombiesystem jeg har udviklet i Roblox Lua, designet med fokus på modularitet, netværksarkitektur, state management og robust gameplay-logik.

🚀 Oversigt

Zombie Waves er et komplet serverside-system, der håndterer spawns, bølger, fjendetyper, belønninger, game state transitions, lydstyring, highlight-effekter og player lifecycle-kontrol.
Projektet er bygget til at være stabilt, skalerbart og let at udvide.

🎮 Features

- Komplet state machine (Intermission, Wave In Progress, Game Over, m.m.)

- Dynamisk wave-system med flere zombie-typer pr. bølge

- Server-authoritative gameplay (anti-cheat friendly)

- Randomiseret spawn distribution

- Player team management (Alive/Dead state)

- Badge unlocking system

- RemoteEvent-baseret kommunikation

- Audio-management med TweenService (fade in/out)

🧩 Arkitektur

Projektet bruger en map-baseret callback-struktur, som gør state management enkelt og let at udvide:

local intermissionFunctions = {
	[GameStateEnum.START_INTERMISSION] = onStartIntermission,
	[GameStateEnum.INTERMISSION] = onIntermission,
	[GameStateEnum.WAVE_IN_PROGRESS] = onStartWave,
	[GameStateEnum.GAME_OVER] = onGameOver,
	[GameStateEnum.GAME_OVER_WIN] = onGameOverWin,
	[GameStateEnum.WAITING] = onWaiting,
}

👥 Player Lifecycle

- Spilleren joiner → sættes automatisk til Dead

- Respawn kun i godkendte gamestates

- Ved death → flyttes tilbage til Dead-team

- Ved Game Over → tvungen death/reset


🧠 Eksempel på wave-generation

local zombiesToSpawn = {}
for zombie, amount in zombieCountPerWave["Wave"..currentWave] do
	for i = 1, amount do
		local clone = zombies[zombie]:Clone()
		table.insert(zombiesToSpawn, clone)
	end
end

🔊 Audio System

Fade in/out af musik ved hjælp af TweenService:

local fadeTween = TweenService:Create(sound, TweenInfo.new(3), {Volume = 0})
fadeTween:Play()
fadeTween.Completed:Wait()
sound:Stop()

🥇 Badges & Rewards
- Cash-belønninger efter hver wave

- Victory badge for at gennemføre sidste bølge

- Server-valideret badge awarding

📁 Folderstruktur
src/
├── ServerScriptService/
│   └── WaveController.server.lua
├── ReplicatedStorage/
│   └── Modules/
│       └── Enums/
│           ├── GameStateEnum.lua
│           ├── GameCommsEnum.lua
│           └── BadgeEnum.lua


🧑‍💻 Hvad jeg lærte
- Avanceret state machine-design

- Event-driven programming

- Klient/server-arkitektur

- Modularitet og ren kode

- Performance-optimering

- Design af komplekse datastrukturer

- Debugging og problemløsning

- Arkitektur i større systemer

📜 Bemærkning
Dette repository viser kun wave-controller delen af et større Roblox-spil.
Det er valgt ud for at demonstrere min programmeringsstil, arkitektur og evne til at strukturere komplekse systemer.
