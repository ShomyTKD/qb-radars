QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local PlayerJob = {}

local lastRadar, plate, street1, street2, street1name, street2name, travelSpeed = nil

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    PlayerJob = PlayerData.job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerJob = job
end)

AddEventHandler('onResourceStart', function(resource)--if you restart the resource
    if resource == GetCurrentResourceName() then
        Wait(200)
        PlayerJob = QBCore.Functions.GetPlayerData().job
    end
end)

-- Determines if player is close enough to trigger cam
function HandlespeedCam(speedCam, hasBeenBusted)
	local myPed = PlayerPedId()
	local playerPos = GetEntityCoords(myPed)
	local isInMarker  = false
	if #(playerPos - vector3(speedCam.x, speedCam.y, speedCam.z)) < 20.0 then
		isInMarker  = true
	end
	if isInMarker and not HasAlreadyEnteredMarker and lastRadar == nil then
		HasAlreadyEnteredMarker = true
		lastRadar = hasBeenBusted

		local vehicle = GetPlayersLastVehicle() -- gets the current vehicle the player is in.
		if IsPedInAnyVehicle(myPed, false) then
			if GetPedInVehicleSeat(vehicle, -1) == myPed then
				if GetVehicleClass(vehicle) ~= 18 then
                    plate = QBCore.Functions.GetPlate(vehicle)
					local speed = GetEntitySpeed(vehicle)
					if Config.UseKmh then -- If you are using KMH
						travelSpeed = math.floor(speed * 3.6 + 0.5)
						if travelSpeed > Config.SpeedLimitKmh then
							QBCore.Functions.Notify("You were caught by a police radar for speeding.", "primary")
							street1, street2 = GetStreetNameAtCoord(playerPos.x, playerPos.y, playerPos.z)
							street1name = GetStreetNameFromHashKey(street1)
							street2name = GetStreetNameFromHashKey(street2)
							PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
							TriggerServerEvent("payForRadar")
						end
					else -- If you are using MPH
						travelSpeed = math.floor(speed * 2.2369)
						if travelSpeed > Config.SpeedLimitMph then
							QBCore.Functions.Notify("You were caught by a police radar for speeding.", "primary")
							street1, street2 = GetStreetNameAtCoord(playerPos.x, playerPos.y, playerPos.z)
							street1name = GetStreetNameFromHashKey(street1)
							street2name = GetStreetNameFromHashKey(street2)
							PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
							TriggerServerEvent("payForRadar")
						end
					end
				end
			end
		end
	end

	if not isInMarker and HasAlreadyEnteredMarker and lastRadar == hasBeenBusted then
		HasAlreadyEnteredMarker = false
		lastRadar = nil
	end
end

RegisterNetEvent('radar:client:SendBillEmail', function(amount)
    SetTimeout(math.random(2500, 4000), function()
        local gender = "Mr."
        if QBCore.Functions.GetPlayerData().charinfo.gender == 1 then gender = "Mrs." end

		local speedType = "MP/H"
		if Config.UseKmh then speedType = "KM/H" end

        local charinfo = QBCore.Functions.GetPlayerData().charinfo
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = "Police",
            subject = "Speeding Ticket",
            message = "Dear " .. gender .. " " .. charinfo.lastname .. "<br/><br/>Hearby we inform you about receiving a ticket for speeding on <strong>" .. street1name .." / ".. street2name .. "</strong>.<br/><br/>Your driving speed was <strong>" .. travelSpeed .. " " .. speedType .. "</strong><br/><br/>Vehicle license plate: <strong>" .. plate .. "</strong><br/><br/>Total fine: <strong>$" .. amount .. "</strong><br/>",
        })
    end)
end)

CreateThread(function()
	while true do
		Wait(1)
		-- If player has a job from below they won't receive any tickets for speeding
		if IsPedInAnyVehicle(PlayerPedId(), false) and not (PlayerJob.name == "police" or PlayerJob.name == "ambulance") then
			for key, value in pairs(Config.Radars) do
				HandlespeedCam(value, key)
			end
			Wait(500)
		else
			Wait(2500)
		end
	end
end)
