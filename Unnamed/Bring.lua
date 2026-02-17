local Bring_Configuration = {
    Bring_Status = false,
    Bring_Timeout = 5,
    Desync = false,
    Spiral = false,
    Bait = false,
    Ragebot_Settings = {},
    Ragebot_Weapons = {},
    Ragebot_Bring = {
        Settings = {},
        Weapons = '[AUG]'
    }
}

for i, v in pairs(Options.ragebot_settings.Value) do
    Bring_Configuration.Ragebot_Settings[i] = v
end

for i, v in pairs(Options.ragebot_weapon.Value) do
    Bring_Configuration.Ragebot_Weapons[i] = v
end

Bring_Configuration.Spiral = Toggles.ragebot_spiral.Value
Bring_Configuration.Bait = Toggles.ragebot_defensive_enabled.Value

function Default()
    api:set_ragebot(false)
    Options.ragebot_settings:SetValue(Bring_Configuration.Ragebot_Settings)
    Options.ragebot_weapon:SetValue(Bring_Configuration.Ragebot_Weapons)
    Options.ragebot_targets:SetValue({})
    Bring_Configuration.Bring_Status = false
    Bring_Configuration.Desync = false
    if Bring_Configuration.Spiral then
        Toggles.ragebot_spiral:SetValue(true)
    end
    if Bring_Configuration.Bait then
        Toggles.ragebot_defensive_enabled:SetValue(true)
    end
    return
end

function Grab()
    game:GetService('ReplicatedStorage'):WaitForChild('MainEvent', 9e9):FireServer('Grabbing', false)
end

function Bring_Target()
    if Bring_Configuration.Bring_Status then
        api:notify('Please wait before using bring again...')
        return
    end

    Bring_Configuration.Bring_Status = true

    local Target_Value = Options.selected_player_dropdown.Value
    local Target = game.Players:FindFirstChild(Target_Value)

    if not Target or not Target.Character then
        api:notify('Targets character not found...')
        return
    end

    local Target_Character = Target.Character

    api:set_ragebot(true)
    api:notify('Attempting to bring: ' .. tostring(Target.Name) .. '...')

    Options.ragebot_settings:SetValue(Bring_Configuration.Ragebot_Bring.Settings)
    Options.ragebot_weapon:SetValue(Bring_Configuration.Ragebot_Bring.Weapons)
    Options.ragebot_targets:SetValue({})
    Options.ragebot_targets:SetValue(Target.Name)
    Toggles.ragebot_spiral:SetValue(false)
    Toggles.ragebot_defensive_enabled:SetValue(false)

    local Timeout = tick()
    repeat 
        task.wait()
    until Target_Character.BodyEffects['K.O'].Value == true or tick() - Timeout > Bring_Configuration.Bring_Timeout

    if tick() - Timeout > Bring_Configuration.Bring_Timeout then
        api:notify('Took too long to knock target.')
        Default()
        return
    end

    Default()

    Bring_Configuration.Desync = true

    if Bring_Configuration.Desync then
        task.spawn(function()
            while Bring_Configuration.Desync do
                local Target_Position = Target_Character.LowerTorso.Position + Vector3.new(0, 3, 0)
                api:set_desync_cframe(CFrame.new(Target_Position))
                Grab()
                task.wait()
            end
        end)
    end

    local Timeout = tick()
    repeat 
        task.wait()
    until Target_Character:FindFirstChild('GRABBING_CONSTRAINT') or tick() - Timeout > Bring_Configuration.Bring_Timeout

    if tick() - Timeout > Bring_Configuration.Bring_Timeout then
        api:notify('Took too long to knock target.')
        Default()
        return
    end

    Default()
end

api:GetTab('misc'):GetGroupbox('player'):AddButton({
    Text = 'bring',
    Func = function()
        Bring_Target()
    end
})