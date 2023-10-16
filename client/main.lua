local lastCarData = {}
local lastWeaponData = {}
local directions = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
local playerId = 0
local inVeh = false
local optiMode = 'Standard'
local weaponHud = false
local Cinema = false

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    StartMainThread()
    Wait(100)
    SetRadarBigmapEnabled(true, false)
    Wait(100)
    SetRadarBigmapEnabled(false, false)
    DisplayRadar(false)
end)

Citizen.CreateThread(function()
    RequestStreamedTextureDict("map", false)
    while not HasStreamedTextureDictLoaded("map") do
        Citizen.Wait(0)
    end

    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "map", "radarmasksm")
    SetBlipAlpha(GetNorthRadarBlip(), 0.0)
    SetBlipScale(GetMainPlayerBlipId(), 0.7)
    SetMinimapClipType(1)

    local minimap = RequestScaleformMovie("minimap")
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    while true do
        Wait(0)
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
    end
end)

CreateThread(function()
     local minimap = RequestScaleformMovie("minimap")
      SetRadarBigmapEnabled(true, false)
      Wait(0)
      SetRadarBigmapEnabled(false, false)
     while true do
         Wait(0)
         BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
         ScaleformMovieMethodAddParamInt(3)
         EndScaleformMovieMethod()
     end
end)

RegisterCommand('loop', function()
    StartMainThread()
end)

RegisterCommand('hud', function()
    SendNUIMessage({ action = 'OPEN_SETTINGS' })
    SetNuiFocus(true, true)
end)

RegisterCommand("togglehud", function()
    ToggleHUD()
end)

function ToggleHUD()
    SendNUIMessage({action = 'TOGGLE_HUD'})
end

RegisterKeyMapping("togglehud", "Chowanie HUDu", "mouse_button", "MOUSE_MIDDLE")

RegisterNUICallback('CloseSettings', function()
    SetNuiFocus(false, false)
end)

function StartMainThread()
    playerId = GetPlayerServerId(PlayerId())
    SendNUIMessage({
        action = 'SHOW_HUD',
        id = playerId,
        uid = 00001 -- uid
    })
    Citizen.CreateThread(function()
        while true do
            local sleep = 1000
            if (optiMode == 'Better') then
                sleep = 2000
            end
            if not Cinema then
                local ped = PlayerPedId()
                local hudData = {}
                hudData.Health = (GetEntityHealth(ped) / 2)
                hudData.Armor = GetPedArmour(ped)
                TriggerEvent('esx_status:getStatus', 'hunger', function(status)
                    hudData.Hunger = status.getPercent()
                end)
                TriggerEvent('esx_status:getStatus', 'thirst', function(status)
                    hudData.Thirst = status.getPercent()
                end)
                hudData.Oxygen = (GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10)
    
                SendNUIMessage({
                    action = 'UPDATE_HUD',
                    hud = hudData,
                })
    
                local voiceData = {
                    isTalking = NetworkIsPlayerTalking(PlayerId()),
                    mode = LocalPlayer.state.proximity.mode
                }
                SendNUIMessage({
                    action = 'UPDATE_VOICE',
                    voice = voiceData
                })
            end
            Citizen.Wait(sleep)
        end
    end)

    Citizen.CreateThread(function()
        while true do
            local sleep = 500
            if (optiMode == 'Better') then
                sleep = 800
            end
            if not Cinema then
                local myWeapon = exports.ox_inventory:getCurrentWeapon()
                if myWeapon then
                    if not weaponHud then
                        SendNUIMessage({ action = 'SHOW_WEAPONHUD' })
                        weaponHud = true
                    end
                    local magazine = exports.ox_inventory:Search('count', myWeapon.ammo)
                    local weaponData = {
                        name = myWeapon.name,
                        ammo = myWeapon.metadata.ammo,
                        magazine = magazine
                    }
                    if not lib.table.matches(weaponData, lastWeaponData) then
                        SendNUIMessage({
                            action = 'UPDATE_WEAPONHUD',
                            weapon = weaponData
                        })
                        weaponData = lastWeaponData
                    end
                else
                    if weaponHud then
                        SendNUIMessage({ action = 'HIDE_WEAPONHUD' })
                        weaponHud = false
                    end
                end
            end
            Citizen.Wait(sleep)
        end
    end)
    
    Citizen.CreateThread(function()
        while true do
            local sleep = 1500
            if (optiMode == 'Better') then
                sleep = 2500
            end
            if not Cinema then
                local hours = GetClockHours()
                local minutes = GetClockMinutes()
                local showClock = ''
                if (hours < 10 and minutes < 10) then
                    showClock = '0'..hours..':'..'0'..minutes
                elseif (hours < 10 and minutes > 9) then
                    showClock = '0'..hours..':'..minutes
                elseif (hours > 9 and minutes < 10) then
                    showClock = hours..':'..'0'..minutes
                elseif (hours > 9 and minutes > 9) then
                    showClock = hours..':'..minutes
                end
                SendNUIMessage({
                    action = 'UPDATE_CLOCK',
                    clock = showClock
                })
            end
            Citizen.Wait(sleep)
        end
    end)
end

lib.onCache('vehicle', function(veh)
    if veh then
        inVeh = true
        StartCarThread(veh)
        SendNUIMessage({action = 'SHOW_CARHUD'})
        DisplayRadar(true)
    else
        inVeh = false
        SendNUIMessage({action = 'HIDE_CARHUD'})
        DisplayRadar(false)
    end
end)

function StartCarThread(vehicle)
    Citizen.CreateThread(function()
        while inVeh do
            Wait(0)
            if not Cinema then
                local ui = GetMinimapAnchor()
                local thickness = 4
                drawRct(ui.x, ui.y, ui.width, (thickness * ui.yunit), 14, 14, 14, 250)
                drawRct(ui.x, ui.y + (ui.height - 0.016), ui.width, -thickness * ui.yunit, 14, 14, 14, 250)
                drawRct(ui.x, ui.y, thickness * ui.xunit, (ui.height - 0.016), 14, 14, 14, 250)
                drawRct(ui.x + ui.width, ui.y, -thickness * ui.xunit, (ui.height - 0.016), 14, 14, 14, 250)
            end
        end
    end)
    Citizen.CreateThread(function()
        while inVeh do
            local sleep = 100
            if (optiMode == 'Better') then
                sleep = 500
            end
            Citizen.Wait(sleep)
            if not Cinema then
                local Coords = GetEntityCoords(PlayerPedId())
                local carData = {}
                carData.Speed = math.floor(GetEntitySpeed(vehicle) * 3.6)
                carData.Street = GetStreetNameFromHashKey(GetStreetNameAtCoord(Coords.x, Coords.y, Coords.z))
                carData.Zone = GetLabelText(GetNameOfZone(Coords.x, Coords.y, Coords.z))
                carData.Direction = Direction()
                carData.Fuel = GetVehicleFuelLevel(vehicle)
                carData.Belt = true -- export od pasow czy cos
                if not lib.table.matches(carData, lastCarData) then
                    SendNUIMessage({
                        action = 'UPDATE_CARHUD',
                        car = carData
                    })
                    lastCarData = carData
                end
            end
        end
    end)
end

RegisterNUICallback('SwitchCinema', function(data)
    Cinema = data.toggle
end)

function Direction()
    local heading = 360.0 - ((GetGameplayCamRot(0).z + 360.0) % 360.0)
    return directions[(math.floor((heading / 45) + 0.5) % 8) + 1];
end

RegisterNUICallback('Opti', function(data)
    optiMode = data.opti
end)

function GetMinimapAnchor()
    local safezone = GetSafeZoneSize()
    local safezone_x = 1.0 / 20.0
    local safezone_y = 1.0 / 20.0
    local aspect_ratio = GetAspectRatio(0)
    local res_x, res_y = GetActiveScreenResolution()
    local xscale = 1.0 / res_x
    local yscale = 1.0 / res_y
    local Minimap = {}
    Minimap.width = xscale * (res_x / (4 * aspect_ratio))
    Minimap.height = yscale * (res_y / 5.674)
    Minimap.left_x = xscale * (res_x * (safezone_x * ((math.abs(safezone - 1.0)) * 10)))
    Minimap.bottom_y = 1.0 - yscale * (res_y * (safezone_y * ((math.abs(safezone - 1.0)) * 10)))
    Minimap.right_x = Minimap.left_x + Minimap.width
    Minimap.top_y = Minimap.bottom_y - Minimap.height
    Minimap.x = Minimap.left_x
    Minimap.y = Minimap.top_y
    Minimap.xunit = xscale
    Minimap.yunit = yscale
    return Minimap
end

function drawRct(x, y, width, height, r, g, b, a)
    DrawRect(x + width/2, y + height/2, width, height, r, g, b, a)
end

-- POWIADOMIENIA

exports('ShowNotification', function(text, time)
    SendNUIMessage({
        action = 'ADD_NOTIFY',
        text = text,
        time = time
    })
end)

-- zervu developa