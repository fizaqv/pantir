-- Bundled by luabundle {"luaVersion":"5.1","version":"1.6.0"}
local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
-- Check for table that is shared between executions.
if not shared then
	return warn("No shared, no script.")
end

-- Initialize Luraph globals if they do not exist.
loadstring("getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end")()

getfenv().PP_SCRAMBLE_NUM = function(...)
	return ...
end

getfenv().PP_SCRAMBLE_STR = function(...)
	return ...
end

getfenv().PP_SCRAMBLE_RE_NUM = function(...)
	return ...
end

---@module Utility.Profiler
local Profiler = require("Utility/Profiler")
---This is called when the initalization errors.
---@param error string
local function onInitializeError(error)
	-- Warn that an error happened while initializing.
	warn("Failed to initialize.")
	warn(error)

	-- Warn traceback.
	warn(debug.traceback())

	-- Detach the current instance.
	Lycoris.detach()
end

-- Safely profile and initialize the script aswell as handle errors.
Profiler.run("Main_InitializeScript", function(...)
	return xpcall(initializeScript, onInitializeError, ...)
end)

end)
__bundle_register("Lycoris", function(require, _LOADED, __bundle_register, __bundle_modules)
-- Detach and initialize a Lycoris instance.
local Lycoris = { queued = false, silent = false, dpscanning = false, norpc = false }

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Game.Hooking
local Hooking = require("Game/Hooking")

---@module Menu
local Menu = require("Menu")

---@module Features
local Features = require("Features")

---@module Utility.ControlModule
local ControlModule = require("Utility/ControlModule")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Game.PlayerScanning
local PlayerScanning = require("Game/PlayerScanning")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Features.Combat.StateListener
local StateListener = require("Features/Combat/StateListener")

---@module Utility.PersistentData
local PersistentData = require("Utility/PersistentData")

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Game.QueuedBlocking
local QueuedBlocking = require("Game/QueuedBlocking")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.Timings.ModuleManager
local ModuleManager = require("Game/Timings/ModuleManager")

---@module Utility.CoreGuiManager
local CoreGuiManager = require("Utility/CoreGuiManager")

---@module Game.ServerHop
local ServerHop = require("Game/ServerHop")

---@module Game.Wipe
local Wipe = require("Game/Wipe")

---@module Features.Automation.EchoFarm
local EchoFarm = require("Features/Automation/EchoFarm")

---@module Features.Automation.JoyFarm
local JoyFarm = require("Features/Automation/JoyFarm")


__bundle_register("Game/Hooking", function(require, _LOADED, __bundle_register, __bundle_modules)
-- Hooking related stuff is handled here.
local Hooking = {}

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Features.Combat.StateListener
local StateListener = require("Features/Combat/StateListener")

---@module Game.LeaderboardClient
local LeaderboardClient = require("Game/LeaderboardClient")

---@module Features.Game.Spoofing
local Spoofing = require("Features/Game/Spoofing")

---@module Game.Objects.DodgeOptions
local DodgeOptions = require("Game/Objects/DodgeOptions")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

-- Services.
local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")

-- Cached IsA.
local isA = game.IsA

-- Old hooked functions.
local oldFireServer = nil
local oldUnreliableFireServer = nil
local oldNameCall = nil
local oldNewIndex = nil
local oldTick = nil
local oldToString = nil
local oldIndex = nil
local oldPrint = nil
local oldWarn = nil
local oldHasEffect = nil






local onFireServer = LPH_NO_VIRTUALIZE(function(...)
	local args = { ... }
	local self = args[1]

	if banRemotes[self] then
		return Logger.warn("(%s) Anticheat is calling a ban remote.", self.Name)
	end

	local blockRemote = KeyHandling.getRemote("Block")

	local inputType = nil

	if blockRemote and self == blockRemote then
		inputType = INPUT_BLOCK
	end

	if inputType then
		-- Before.
		onInterceptedInput(inputType, INPUT_TYPE_BEFORE)

		-- Now.
		local result = oldFireServer(...)

		-- After.
		onInterceptedInput(inputType, INPUT_TYPE_AFTER)

		-- Return.
		return result
	end

	return oldFireServer(...)
end)

	---@improvement: Add a listener for this script.
	local playerScripts = localPlayer:WaitForChild("PlayerScripts")
	local clientActor = playerScripts:WaitForChild("ClientActor")
	local clientManager = clientActor:WaitForChild("ClientManager")
	local requests = replicatedStorage:WaitForChild("Requests")

	---@note: Crucial part because of the actor and the error detection.
	clientManager.Enabled = false

	---@note: Dynamically get the ban remotes.
	local banRemoteCount = 0

	for _, request in next, requests:GetChildren() do
		local hasChangedConnection = #getconnections(request.Changed)
		if hasChangedConnection <= 0 then
			continue
		end

		banRemoteCount = banRemoteCount + 1
		banRemotes[request] = true
	end

	-- Did we execute with a standalone AC bypass?
	local nulledBanRemotes = {}

	for _, instance in next, getnilinstances() do
		if instance.Name ~= "NulledBanRemote" then
			continue
		end

		nulledBanRemotes[#nulledBanRemotes + 1] = instance
	end

	if #nulledBanRemotes ~= 2 then
		if banRemoteCount ~= 2 then
			return error("Anticheat has less or more than two ban remotes.")
		end
	end

	oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, onFireServer)
	oldUnreliableFireServer = hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, onUnreliableFireServer)
	oldToString = hookfunction(tostring, onToString)
	oldIndex = hookfunction(getrawmetatable(game).__index, onIndex)
	oldNameCall = hookfunction(getrawmetatable(game).__namecall, onNameCall)
	oldNewIndex = hookfunction(getrawmetatable(game).__newindex, onNewIndex)
	oldTick = hookfunction(tick, onTick)
	oldWarn = hookfunction(warn, onWarn)
	oldPrint = hookfunction(print, onPrint)

	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)

	oldHasEffect = effectReplicatorModule.HasEffect

	effectReplicatorModule.HasEffect = onHasEffect

	-- Okay, we're done.
	print("Client-side anticheat has been penetrated.")
    end)
end)
