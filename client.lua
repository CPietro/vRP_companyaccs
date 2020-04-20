vRPcc = {}
Tunnel.bindInterface("vRP_companyaccs",vRPcc)
vRPserver = Tunnel.getInterface("vRP","vRP_companyaccs")
CCserver = Tunnel.getInterface("vRP_companyaccs","vRP_companyaccs")
vRP = Proxy.getInterface("vRP")

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(900000) --900000 15 minutes
		local codice_utente = GetPlayerServerId(PlayerId())
		TriggerServerEvent('pagaTitolare', codice_utente)
	end
end)