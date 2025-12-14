-- [[ OPTIMIZATION ]]
memory.set_write_strength(0.001)

-- [[ CONFIGURATION ]]
-- CHANGE THIS TO YOUR GITHUB USERNAME AND REPO NAME
local Repo = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/"

-- [[ IMPORTER ]]
local function Import(path)
    local url = Repo .. path
    local source = game:HttpGet(url)
    local bytecode = luau.compile(source, {
        optimizationLevel = 2,
        coverageLevel = 0,
        debugLevel = 1
    })
    return luau.load(bytecode, {
        debugName = path,
        injectGlobals = true
    })()
end

-- [[ SHARED STATE ]]
-- This table is passed to all modules so they share the same settings
local Settings = {
    Enabled = true,
    StickyAim = true,
    WallCheck = true,
    
    -- Triggerbot
    TriggerEnabled = false,
    TriggerDelay = 0.05,
    TriggerDistance = 1000,
    
    -- Aimbot
    FOV = 100,
    FOVSides = 64,
    AimKey = "XButton2",
    ShowFOV = false,
    
    -- Prediction
    PredictionEnabled = false,
    PredictionMode = "Combined",
    PredAmount = 0.165,
    PredHorizontal = 0.165,
    PredVertical = 0.165,
    
    -- Targeting
    HitboxR6 = { ["Head"] = true },
    HitboxR15 = { ["Head"] = true },
    TeamCheck = false,
    
    -- Anti Aim
    AntiAimMasterEnabled = false,
    AntiAimMode = "None",
    ShowAADebug = false,
    SpinSpeed = 80,
    JitterMin = -45,
    JitterMax = 45,
    StaticOffset = 90,
    
    -- Visuals
    ESPEnabled = false,
    ESPBox = false,
    ESPSkeleton = false,
    ESPHealthBar = false,
    ESPHealthGradient = true,
    ESPName = false,
    ESPDistance = false,
    ESPHealthText = false,
    ESPTracers = false,
    ESPHeadDot = false,
    
    -- Fancy Visuals
    ESPGroundRing = false,
    ESPHeadHalo = false,
    ESPLookTracer = false,
    ESPOffscreen = false,
    
    -- Radar
    RadarEnabled = false,
    RadarRange = 150,
    RadarSize = 150,
    RadarX = 50,
    RadarY = 50,
    
    -- Colors (Defaults)
    ColorBox = Color3.fromRGB(255, 255, 255),
    ColorSkel = Color3.fromRGB(255, 255, 255),
    ColorHealthSolid = Color3.fromRGB(0, 255, 0),
    ColorTracer = Color3.fromRGB(255, 255, 255),
    ColorHeadDot = Color3.fromRGB(255, 0, 0),
    ColorRing = Color3.fromRGB(100, 100, 255),
    ColorHalo = Color3.fromRGB(255, 255, 0),
    ColorLook = Color3.fromRGB(255, 100, 100),
    ColorRadarBG = Color3.fromRGB(30, 30, 30),
    ColorRadarDot = Color3.fromRGB(255, 0, 0),
    ColorOffscreen = Color3.fromRGB(255, 0, 0),
}

-- [[ GLOBAL CACHES ]]
local MapCache = { Grid = {}, CellSize = 25, Ready = false, IsCaching = false, PendingParts = {} }
local TargetCache = { Player = nil, Part = nil, LastPos = nil, Velocity = vector.create(0,0,0), LastUpdate = os.clock() }

-- [[ LOAD MODULES ]]
local AimbotModule  = Import("Modules/Aimbot.lua")
local VisualsModule = Import("Modules/Visuals.lua")
local AAModule      = Import("Modules/AntiAim.lua")
local UIModule      = Import("Modules/UI.lua")

-- [[ INITIALIZE ]]
local Aimbot  = AimbotModule.Init(Settings, MapCache, TargetCache)
local Visuals = VisualsModule.Init(Settings, MapCache) -- Visuals doesn't really use cache but passed for future proofing
local AntiAim = AAModule.Init(Settings)

-- Load UI (We pass Aimbot.CacheMap so the button works)
UIModule.Load(Settings, Aimbot.CacheMap)

-- [[ MAIN LOOP ]]
game:GetService("RunService").Render:Connect(function()
    Aimbot.Update()
    Visuals.Update()
    AntiAim.Update()
end)

print("Almeida Loaded via GitHub")
