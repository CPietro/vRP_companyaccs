local lang = {
	pin = {
		change = "Insert your new PIN (5 digits)?",
		changed = "Your new PIN is {1}, be careful with it!",
		not_available = "~r~The PIN inserted isn't available!",
		insert = "Insert your PIN...",
		wrong = "~r~You inserted the wrong PIN!"
	},
	account = {
		new_balance = "Your new balance is ~g~{1}$~w~!",
		amount_not_correct = "~r~The typed in amount is not correct!",
		not_enough_money = "~r~You don't have enough money!",
		too_much = "~r~You cannot deposit more than 2500$.",
		refused = "~r~{1} refused the payment.",
		you_refused = "~r~You refused to receive the payment from {1}.",
		setowner_desc = "By signing this document you'll be in charge of managing your department's bank account.",
		blocked = "~r~Your account is frozen!",
		interests = "You have been paid interest on your corporate account!"
	},
	business = {
		fined = "~r~Business fined!",
		ownership = "You are now in charge of your department's account."
	},
	tracking = {
		deposit = "Deposit",
		payment = "Payment",
		transfer = "Transfer"
	},
	common = {
		quantity = "Insert quantity...",
		near_players = "Near players: {1}",
		transfer_request = "{1} wants to transfer you money by card...",
		request_recipient = "Request sent to the receipient...",
		how_much = "How much money do you want to send?",
		how_much_trasfer = "How much money do you want to transfer?",
		sent_amount = "You sent ~r~{1}$~w~.",
		received_amount = "You received ~g~{1}$~w~.",
		transferred_amount = "You transferred ~g~{1}$~w~.",
		commissions = "You paid ~r~{1}$~w~ in fees.",
		no_id_specified = "~r~No ID specified.",
		no_near_players = "~r~No players near."
	},
	menu = {
		owner = {
			name = "Account",
			set = "Take ownership of you department bank account."
		}
	}
}

return lang