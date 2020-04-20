MySQL = module("vrp_mysql", "MySQL")
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
local Lang = module("vrp", "lib/Lang")
local cfg = module("vrp_companyaccs", "cfg/conti")

vRP = Proxy.getInterface("vRP")
vRPbm = Proxy.getInterface("vRP_basic_menu")
vRPca = Proxy.getInterface("vRP_cards")
lang = Lang.new(module("vrp_companyaccs", "cfg/lang"))

vRPcc = {}
Tunnel.bindInterface("vRP_companyaccs",vRPcc)
Proxy.addInterface("vRP_companyaccs",vRPcc)
CCclient = Tunnel.getInterface("vRP_companyaccs","vRP_companyaccs")

vRPclient = Tunnel.getInterface("vRP","vRP_companyaccs")

tmpConti = {}
busi = {}
	
MySQL.createCommand("vRP/bank_init_user","INSERT IGNORE INTO vrp_business(business,bank) VALUES(@business,@bank)")
MySQL.createCommand("vRP/get_bank","SELECT * FROM vrp_business WHERE business = @business")
MySQL.createCommand("vRP/get_bankid","SELECT * FROM vrp_business WHERE user_id = @user_id")
MySQL.createCommand("vRP/set_bank","UPDATE vrp_business SET bank = @bank WHERE business = @business")
MySQL.createCommand("vRP/get_pin_c","SELECT * FROM vrp_business WHERE business = @business")
MySQL.createCommand("vRP/insert_cc_pin","UPDATE vrp_business SET pin = @pin WHERE business = @business")
MySQL.createCommand("vRP/get_owner_id","SELECT * FROM vrp_business WHERE user_id = @user_id")
MySQL.createCommand("vRP/get_cap_soc","SELECT * FROM vrp_user_moneys")
MySQL.createCommand("vRP/get_cartatot","SELECT * FROM vrp_cards")
MySQL.createCommand("vRP/set_hirankownship","UPDATE vrp_business SET user_id = @user_id WHERE business = @business")

function vRPcc.generaPIN()
	math.randomseed(os.time() - os.clock() * 1000)
	for i=0,5 do
		math.random(10001,99999)
	end
	local numero = tonumber(math.random(10001,99999))
	return numero
end

function vRPcc.getPIN(business, cbr)
	local task = Task(cbr,{""})
	MySQL.query("vRP/get_pin_c", {business = business}, function(rows, affected)
		if #rows > 0 then		
			task({rows[1].pin})
		else
			task()
		end
	end)
end

function vRPcc.setPIN(business, player)
	if business ~= nil then
		pin = vRPcc.generaPIN()
		MySQL.execute("vRP/insert_cc_pin", {business = business, pin = pin}, function(affected)	
			vRPclient.notify(player, {lang.pin.changed({pin})})
		end)
	end
end

function vRPcc.cambia_PIN(business, player)
	if business ~= nil then
		vRP.prompt({player, lang.pin.change(),"",function(player,pin)
			pin = parseInt(pin)
			if #tostring(pin) == 5 and pin >= 0 and pin <= 99999 then
				MySQL.execute("vRP/insert_cc_pin", {business = business, pin = pin}, function(affected)	
					vRPclient.notify(player, {lang.pin.changed({pin})})
				end)	
			else
				vRPclient.notify(player, {lang.pin.not_available()})
			end
		end})		
	end
end

function vRPcc.tryContoPayment(business,amount, cbr)
	local task = Task(cbr,{""})
	vRPcc.getBankBalance(business, function(ammontare)
		ammontare = parseInt(ammontare)
		if ammontare ~= nil and ammontare >= amount then
			vRPcc.setBankBalance(business,ammontare-amount)
			task({"1"})
		else
			task()
		end
	end)
end

function vRPcc.getBankBalance(business, cbr)
	local task = Task(cbr,{""})
	MySQL.query("vRP/get_bank", {business = business}, function(rows, affected)
		if #rows > 0 then		
			task({rows[1].bank})
		else
			task()
		end
	end)
end

function vRPcc.getBankBalanceID(user_id, cbr)
	local task = Task(cbr,{""})
	user_id = tonumber(parseInt(user_id))
	if user_id > 0 then
		MySQL.query("vRP/get_bankid", {user_id = user_id}, function(rows, affected)
			if #rows > 0 then		
				task({rows[1].bank})
			else
				task()
			end
		end)
	end
end

function vRPcc.setBankBalance(business, amount)
	if business ~= nil and amount ~= nil and amount >= 0 then
		MySQL.execute("vRP/set_bank", {business = business, bank = amount})
	end
end

function vRPcc.addBankMoney(business, amount, player)
	amount = parseInt(amount)
	if business ~= nil and amount ~= nil and amount > 0 then
		vRPcc.getBankBalance(business, function(current_balance)
			local newbalance = current_balance + amount
			vRPcc.setBankBalance(business, newbalance)
			if player ~= nil then
				vRPclient.notify(player, {lang.account.new_balance({newbalance})})
			end
		end)
	else
		if player ~= nil then
			vRPclient.notify(player, {lang.account.amount_not_correct()})
		end
	end
end

function vRPcc.removeBankMoney(business, amount, player)
	amount = parseInt(amount)
	if business ~= nil and amount ~= nil and amount > 0 then
		vRPcc.getBankBalance(business, function(current_balance)
			current_balance = parseInt(current_balance)
			if current_balance >= amount then
				local newbalance = current_balance - amount
				vRPcc.setBankBalance(business, newbalance)
				vRPclient.notify(player, {lang.account.new_balance({newbalance})})
			else
				vRPclient.notify(player, {lang.account.not_enough_money()})
			end
		end)
	else
		vRPclient.notify(player, {lang.account.amount_not_correct()})
	end
end

function vRPcc.multaContoAziendale(business,perc,player)
	vRPcc.getBankBalance(business, function(bal)
		local contoperc = (tonumber(bal)/100)*tonumber(perc)
		local nuovoimporto = bal - contoperc
		vRPcc.setBankBalance(business, nuovoimporto)
		if player ~= nil then
			vRPclient.notify(player, {lang.business.fined()})
		end
	end)
end

function vRPcc.removeBusMoney(user_id, amount)
	amount = parseInt(amount)
	if amount ~= nil and amount > 0 then
		vRPcc.getOwnerBizName(user_id, function(business)
			vRPcc.getBankBalance(business, function(current_balance)
				current_balance = parseInt(current_balance)
				if current_balance >= amount then
					local newbalance = current_balance - amount
					vRPcc.setBankBalance(business, newbalance)
				end
			end)
		end)
	end
end

function vRPcc.getCapSoc(cbr)
	local task = Task(cbr,{""})
	totaleBank = 0
	MySQL.query("vRP/get_cap_soc", {}, function(rows, affected)
		if #rows > 0 then
			for i=1,#rows do 
				totaleBank = totaleBank + rows[i].bank
			end
		else
			task()
		end
	end)
	totaleCC = 0
	MySQL.query("vRP/get_cartatot", {}, function(rows, affected)
		if #rows > 0 then
			for i=1,#rows do
				totaleCC = totaleCC + rows[i].coins
			end
		else
			task()
		end
	end)
	SetTimeout(500,function()
		totale = totaleBank + totaleCC
		task({totale})
	end)	
end

function vRPcc.rapinaMoney(percentuale,cbr)
	percentuale = percentuale*0.01
	local task = Task(cbr,{""})
	totaleBank = 0
	MySQL.query("vRP/get_cap_soc", {}, function(rows, affected)
		if #rows > 0 then
			for i=1,#rows do 
				local user_id = rows[i].user_id
				local soldiUtente = rows[i].bank
				vRP.impostaBankMoneyOffline({user_id,math.floor(soldiUtente*(1-percentuale))})
				totaleBank = totaleBank + rows[i].bank
			end
		else
			task()
		end
	end)
	totaleCC = 0
	MySQL.query("vRP/get_cartatot", {}, function(rows, affected)
		if #rows > 0 then
			for i=1,#rows do
				local user_id = rows[i].user_id
				local soldiUtenteCC = rows[i].coins
				source = vRP.getUserSource({user_id})
				if source ~= nil then
					vRPca.setCoins({user_id,math.floor(soldiUtenteCC*(1-percentuale))})					
				else
					vRPca.setCoinsOffline({user_id,math.floor(soldiUtenteCC*(1-percentuale))})
				end				
				totaleCC = totaleCC + rows[i].coins
			end
		else
			task()
		end
	end)
	SetTimeout(500,function()
		totale = totaleBank + totaleCC
		totale = math.floor(totale*percentuale)
		task({totale})
	end)	
end

function vRPcc.getUserBizName(user_id)
	player = vRP.getUserSource({user_id})
	if user_id ~= nil then
		local biz_group_name = vRP.getUserGroupByType({user_id,"business"})
		local job_group_name = vRP.getUserGroupByType({user_id,"job"})
		local nomi_business = cfg.bizz
		local nomi_lavori = cfg.lavori
		for k,v in pairs(nomi_business) do
			local gruppo,nome = table.unpack(v)
			local gruppo_figlio = vRP.getGroupFiglio({gruppo})			
			if biz_group_name == gruppo or biz_group_name == gruppo_figlio then
				return nome
			end
		end
		for k,v in pairs(nomi_lavori) do
			local gruppo,nome,permesso = table.unpack(v)
			if tostring(job_group_name) == tostring(gruppo) then
				return nome
			end
		end
	end
end

function vRPcc.getOwnerBizName(user_id, cbr)
	if user_id ~= nil then
		local task = Task(cbr,{""})
		MySQL.query("vRP/get_owner_id", {user_id = user_id}, function(rows, affected)
			if #rows > 0 then		
				task({rows[1].business})
			else
				task()
			end
		end)
	end
end

function vRPcc.setOwnerHiRank(user_id, business)
	if user_id ~= nil then
		if business ~= nil then
			player = vRP.getUserSource({user_id})
			MySQL.execute("vRP/set_hirankownship", {business = business, user_id = user_id})
			vRPclient.notify(player, {lang.business.ownership()})
		end
	end
end

function vRPcc.depositaCash(user_id,biz_name,player)
	if user_id ~= nil then
		biz_name = tostring(biz_name)
		if biz_name ~= nil then
			vRP.prompt({player, lang.common.quantity(),"",function(player,amount)
				amount = parseInt(amount)
				if amount > 0 and amount <= 2500 then
					if vRP.tryPayment({user_id,amount}) then
						vRPcc.addBankMoney(biz_name, amount, player)
						vRPclient.getPosition(player, {}, function(x,y,z) vRPca.transactionTrack({user_id, nil, lang.tracking.deposit(), amount, "x="..x..", y="..y..", z="..z..".", nil, nil, 1}) end)
					else
						vRPclient.notify(player, {lang.account.not_enough_money()})
					end				
				else
					if amount > 2500 then
						vRPclient.notify(player, {lang.account.too_much()})
					else
						vRPclient.notify(player, {lang.account.amount_not_correct()})
					end
				end
			end})
		end
	end
end

function vRPcc.pagaUtente(user_id, player)
	if user_id ~= nil then
		local nome_bizun = vRPcc.getUserBizName(user_id)
		vRPclient.getNearestPlayers(player,{15},function(nplayers)
			usrList = ""
			for k,v in pairs(nplayers) do
				usrList = usrList .. "[" .. vRP.getUserId({k}) .. "]" .. GetPlayerName(k) .. " | "
			end
			if usrList ~= "" then
				vRP.prompt({player, lang.common.near_players({usrList}),"",function(player,user_id1) 
					user_id1 = user_id1
					if user_id1 ~= nil and user_id1 ~= "" then 
						local target = vRP.getUserSource({tonumber(user_id1)})
						if target ~= nil then
							vRP.request({target, lang.common.transfer_request({GetPlayerName(player)}), 10, function(target,ok)
								vRPclient.notify(player, {lang.common.request_recipient()})
								if ok then
									destinatario = vRP.getUserId({target})
									vRPcc.getPIN(nome_bizun, function(pin_giusto)	
										vRP.prompt({player, lang.pin.insert(),"",function(player,pin_inserito)	
											pin_inserito = parseInt(pin_inserito)
											if pin_inserito == pin_giusto then
												vRP.prompt({player, lang.common.how_much(),"",function(player,amount)
													amount = parseInt(amount)
													if amount > 0 then
														vRPcc.tryContoPayment(nome_bizun,math.floor(amount*1.02), function(cacca)
															if tonumber(cacca) == 1 then 
																vRPca.giveCoins({destinatario,amount})
																vRPclient.notify(player, {lang.common.sent_amount({amount})})
																vRPclient.notify(target, {lang.common.received_amount({amount})})
																vRPclient.notify(player, {lang.common.commissions({amount*0.02})})
																vRPcc.addBankMoney("bank", math.floor(amount*0.04), nil)
																vRPclient.getPosition(player, {}, function(x,y,z) vRPca.transactionTrack({user_id, destinatario, lang.tracking.payment(), amount, "x="..x..", y="..y..", z="..z..".", nil, 1, nil}) end)
															else
																vRPclient.notify(player, {lang.account.not_enough_money()})
															end
														end)
													else
														vRPclient.notify(player, {lang.account.amount_not_correct()})
													end
												end})
											else
												vRPclient.notify(player, {lang.pin.wrong()})
											end
										end})
									end)
								else --iiii
									vRPclient.notify(player,{lang.account.refused({GetPlayerName(target)})})
									vRPclient.notify(target,{lang.account.you_refused({GetPlayerName(player)})})
								end
							end})
						end
					else
						vRPclient.notify(player,{lang.common.no_id_specified()})
					end
				end})
			else
				vRPclient.notify(player,{lang.common.no_near_players()})
			end
		end) --cc
	end
end

function vRPcc.trasferisciContoAzPers(user_id, player)
	if user_id ~= nil then
		local nome_bizun = vRPcc.getUserBizName(user_id)
		vRPcc.getPIN(nome_bizun, function(pin_giusto)	
			vRP.prompt({player, lang.pin.insert(),"",function(player,pin_inserito)	
				pin_inserito = parseInt(pin_inserito)
				if pin_inserito == pin_giusto then
					vRP.prompt({player, lang.common.how_much_trasfer(),"",function(player,amount)
						amount = parseInt(amount)
						if amount > 0 then
							vRPcc.tryContoPayment(nome_bizun,amount, function(cacca)
								if tonumber(cacca) == 1 then 
									vRP.giveBankMoney({user_id,amount})
									vRPclient.notify(player, {lang.common.transferred_amount({amount})})
									vRPclient.getPosition(player, {}, function(x,y,z) vRPca.transactionTrack({user_id, nil, lang.tracking.transfer(), amount, "x="..x..", y="..y..", z="..z..".", nil, 1, nil}) end)
								else
									vRPclient.notify(player, {lang.account.not_enough_money()})
								end
							end)
						else
							vRPclient.notify(player, {lang.account.amount_not_correct()})
						end
					end})
				else
					vRPclient.notify(player, {lang.pin.wrong()})
				end
			end})
		end)
	end
end

function vRPcc.trasferisciContoPersAz(user_id, player)
	if user_id ~= nil then
		local nome_bizun = vRPcc.getUserBizName(user_id)
		vRPcc.getPIN(nome_bizun, function(pin_giusto)	
			vRP.prompt({player, lang.pin.insert(),"",function(player,pin_inserito)	
				pin_inserito = parseInt(pin_inserito)
				if pin_inserito == pin_giusto then
					vRP.prompt({player, lang.common.how_much_trasfer(),"",function(player,amount)
						amount = parseInt(amount)
						if amount > 0 then
							if vRP.tryBankMoney({user_id,amount}) then
								vRPcc.addBankMoney(nome_bizun, amount, player)
								vRPclient.notify(player, {lang.common.transferred_amount({amount})})
								vRPclient.getPosition(player, {}, function(x,y,z) vRPca.transactionTrack({user_id, nil, lang.tracking.transfer(), amount, "x="..x..", y="..y..", z="..z..".", nil, nil, 1}) end)
							else
								vRPclient.notify(player, {lang.account.not_enough_money()})
							end
						else
							vRPclient.notify(player, {lang.account.amount_not_correct()})
						end
					end})
				else
					vRPclient.notify(player, {lang.pin.wrong()})
				end
			end})
		end)
	end
end

local ch_setOwner = {function(player,choice)
local user_id = vRP.getUserId({player})
if user_id ~= nil then
	vRPcc.setOwnerHiRank(user_id, busi)
end
end, lang.account.setowner_desc()}

local menu_pos = {}
for k,v in pairs(cfg.lavori) do
	local gruppo,nome,permesso = table.unpack(v)
	menu_pos[nome] = {name=lang.menu.owner.name(),css={top="75px",header_color="rgba(0,255,255,0.75)"}}
	menu_pos[nome][lang.menu.owner.set()] = ch_setOwner
	menu_pos[nome].onclose = function(source) vRP.closeMenu({source}) end
end

local function build_client_pubblici(source)
	local user_id = vRP.getUserId({source})
	if user_id ~= nil then	
		local function pubblici_enter()
			local user_id = vRP.getUserId({source})
			if user_id ~= nil then
				if not vRP.hasPermission({user_id,"no.withdraw"}) then
					for k,v in pairs(cfg.lavori) do
						local gruppo,nome,permesso = table.unpack(v)
						if vRP.hasPermission({user_id,permesso}) then
							busi = gruppo
							vRP.openMenu({source,menu_pos[nome]})
						end
					end
				else
					vRPclient.notify(player, {lang.account.blocked()})
				end		
			end		
		end
		local function pubblici_leave()
			vRP.closeMenu({source})
		end	  
		vRPclient.addMarker(source,{242.19073486328,211.48915100098,110.28295898438-1,0.7,0.7,0.3,0,125,255,125,150})
		vRP.setArea({source,"vRP:pubblici",242.19073486328,211.48915100098,110.28295898438,1,1.5,pubblici_enter,pubblici_leave}) 
	end
end

AddEventHandler("vRP:playerSpawn",function(user_id, source, first_spawn)
	if first_spawn then
		build_client_pubblici(source)
	end	
end)

RegisterServerEvent('pagaTitolare')
AddEventHandler('pagaTitolare', function(player)
player = parseInt(player)
if player ~= nil then
	local user_id = vRP.getUserId({player})
	player = vRP.getUserSource({user_id})
	vRPcc.getOwnerBizName(user_id, function(nome_propr)
		if nome_propr ~= nil and nome_propr ~= "" then
			vRPcc.getBankBalance(nome_propr, function(amount)
				vRPcc.addBankMoney(nome_propr, math.floor(amount*0.0025), player)
				vRPclient.notify(player, {lang.account.interests()})
			end)
		end
	end)
end
end)