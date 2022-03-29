local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent("payForRadar", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.RemoveMoney("bank", Config.RadarCost, "caught-by-police-radar")
	TriggerEvent('qb-bossmenu:server:addAccountMoney', "police", Config.RadarCost)
	TriggerClientEvent('radar:client:SendBillEmail', src, Config.RadarCost)
end)