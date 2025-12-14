local Module = {}

function Module.Load(Settings, CacheMapFunction)
    -- Load Lib
    local Bytecode = game:HttpGet("https://raw.githubusercontent.com/DCHARLESAKAMRGREEN/Severe-Luas/main/Libraries/Pseudosynonym.lua")
    local Library = luau.load(Bytecode)()

    local Window = Library:CreateWindow({
        Title = "Almeida",
        Tag = "v6.0-Modular",
        Keybind = "End",
        AutoShow = true
    })

    local AimTab = Window:AddTab({ Name = "Aimbot" })
    local AntiAimTab = Window:AddTab({ Name = "Anti Aim" })
    local VisualsTab = Window:AddTab({ Name = "Visuals" })
    local SettingsTab = Window:AddTab({ Name = "Settings" })

    -- [[ AIMBOT UI ]]
    local MainContainer = AimTab:AddContainer({ Name = "General", Side = "Left", AutoSize = true })
    local TriggerContainer = AimTab:AddContainer({ Name = "Triggerbot", Side = "Left", AutoSize = true })
    local PredContainer = AimTab:AddContainer({ Name = "Prediction", Side = "Right", AutoSize = true })
    local HitboxContainer = AimTab:AddContainer({ Name = "Targeting", Side = "Right", AutoSize = true })

    MainContainer:AddToggle({ Name = "Master Switch", Value = Settings.Enabled, Callback = function(v) Settings.Enabled = v end })
    MainContainer:AddToggle({ Name = "Sticky Aim", Value = Settings.StickyAim, Callback = function(v) Settings.StickyAim = v end })
    MainContainer:AddToggle({ Name = "Wall Check", Value = Settings.WallCheck, Callback = function(v) Settings.WallCheck = v end })
    MainContainer:AddButton({ Name = "Re-Cache Map", Callback = CacheMapFunction })
    MainContainer:AddToggle({ Name = "Draw FOV", Value = Settings.ShowFOV, Callback = function(v) Settings.ShowFOV = v end })
    MainContainer:AddToggle({ Name = "Team Check", Value = Settings.TeamCheck, Callback = function(v) Settings.TeamCheck = v end })
    MainContainer:AddSlider({ Name = "FOV Radius", Min = 10, Max = 800, Default = Settings.FOV, Rounding = 10, Callback = function(v) Settings.FOV = v end })
    
    local AimKeyToggle = MainContainer:AddToggle({ Name = "Aim Key", Value = true })
    AimKeyToggle:AddKeypicker({ Default = "XButton2", Mode = "Hold", Callback = function(v) Settings.Aiming = v end })

    -- Triggerbot
    local TrigToggle = TriggerContainer:AddToggle({ Name = "Enabled", Value = Settings.TriggerEnabled, Callback = function(v) Settings.TriggerEnabled = v end })
    TrigToggle:AddKeypicker({ Default = "None", Mode = "Hold", Callback = function(v) Settings.TriggerActive = v end })
    TriggerContainer:AddSlider({ Name = "Delay (s)", Min = 0, Max = 1, Default = Settings.TriggerDelay, Rounding = 0.01, Callback = function(v) Settings.TriggerDelay = v end })
    TriggerContainer:AddSlider({ Name = "Max Distance", Min = 10, Max = 2000, Default = Settings.TriggerDistance, Rounding = 50, Callback = function(v) Settings.TriggerDistance = v end })

    -- Prediction
    PredContainer:AddToggle({ Name = "Enable Prediction", Value = Settings.PredictionEnabled, Callback = function(v) Settings.PredictionEnabled = v end })
    local SliderH = PredContainer:AddSlider({ Name = "Horizontal", Min = 0, Max = 1, Default = Settings.PredHorizontal, Rounding = 0.001, Callback = function(v) Settings.PredHorizontal = v end })
    local SliderV = PredContainer:AddSlider({ Name = "Vertical", Min = 0, Max = 1, Default = Settings.PredVertical, Rounding = 0.001, Callback = function(v) Settings.PredVertical = v end })

    -- [[ ANTI AIM UI ]]
    local AAMain = AntiAimTab:AddContainer({ Name = "General", Side = "Left", AutoSize = true })
    local AASettings = AntiAimTab:AddContainer({ Name = "Settings", Side = "Right", AutoSize = true })
    
    local AAToggle = AAMain:AddToggle({ Name = "Enable Anti-Aim", Value = Settings.AntiAimMasterEnabled, Callback = function(v) Settings.AntiAimMasterEnabled = v end })
    AAToggle:AddKeypicker({ Default = "None", Mode = "Toggle", Callback = function(v) Settings.AntiAimActive = v end })
    AAMain:AddToggle({ Name = "Show Debug Line", Value = Settings.ShowAADebug, Callback = function(v) Settings.ShowAADebug = v end })
    AAMain:AddDropdown({ Name = "Mode", Values = {"None", "Spin", "Jitter", "Static"}, Default = Settings.AntiAimMode, Callback = function(v) Settings.AntiAimMode = v end })
    
    AASettings:AddSlider({ Name = "Spin Speed", Min = 1, Max = 150, Default = Settings.SpinSpeed, Rounding = 1, Callback = function(v) Settings.SpinSpeed = v end })
    AASettings:AddSlider({ Name = "Jitter Min", Min = -180, Max = 180, Default = Settings.JitterMin, Rounding = 1, Callback = function(v) Settings.JitterMin = v end })
    AASettings:AddSlider({ Name = "Jitter Max", Min = -180, Max = 180, Default = Settings.JitterMax, Rounding = 1, Callback = function(v) Settings.JitterMax = v end })

    -- [[ VISUALS UI ]]
    local ESPMain = VisualsTab:AddContainer({ Name = "ESP Main", Side = "Left", AutoSize = true })
    ESPMain:AddToggle({ Name = "Master Switch", Value = Settings.ESPEnabled, Callback = function(v) Settings.ESPEnabled = v end })
    ESPMain:AddToggle({ Name = "Boxes", Value = Settings.ESPBox, Callback = function(v) Settings.ESPBox = v end })
    ESPMain:AddToggle({ Name = "Tracers", Value = Settings.ESPTracers, Callback = function(v) Settings.ESPTracers = v end })
    
    -- Radar
    local RadarC = VisualsTab:AddContainer({ Name = "Radar", Side = "Right", AutoSize = true })
    RadarC:AddToggle({ Name = "Enabled", Value = Settings.RadarEnabled, Callback = function(v) Settings.RadarEnabled = v end })
    RadarC:AddSlider({ Name = "Range", Min = 50, Max = 500, Default = Settings.RadarRange, Rounding = 10, Callback = function(v) Settings.RadarRange = v end })

    -- [[ SETTINGS UI ]]
    local MenuC = SettingsTab:AddContainer({ Name = "Interface", Side = "Left", AutoSize = true })
    MenuC:AddMenuBind({ Default = "End" })
    MenuC:AddWatermark({ Watermark = "Almeida v6.0", ShowFPS = true })
    MenuC:AddButton({ Name = "Unload", Unsafe = true, Callback = function() Library:Unload(); Settings.Enabled = false end })
    SettingsTab:AddConfigManager({ Side = "Right", AutoSize = true })
end

return Module
