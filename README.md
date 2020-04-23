# vRP Company Bank Accounts

## Description
  Simple script to provide bank accounts to [vRP_business](https://github.com/CPietro/vRP_business).\
  It's possible to get paid by people, deposit money in the company's bank account, transfer it from the personal account to the business' one and the other way around. You'll also gain interest from the money in the account. A PIN that only the owner can change is there to prevent employees to steal. For public departments bosses there is a special blip in the map to gain access to their department bank account, this may be useful for the head of the police department. It'll have to be used only once.

## Pictures
<details><summary>SHOW</summary>
<p>

![Image1](https://i.postimg.cc/qMXZPZFW/image.png)\
![Image2](https://i.postimg.cc/MGWcsXQh/image.png)\
![Image3](https://i.postimg.cc/KvfrmX5S/image.png)
</p>
</details>

## Dependencies
 #### Mandatory
 * [vRP_business](https://github.com/CPietro/vRP_business) - Companies that can be bought by players;
 * [vRP_cards](https://github.com/CPietro/vRP_cards) - Cards for players to buy stuff with them;
 * [Changes](#changes-to-vrp-mandatory) - Mandatory modifications to vRP;

## Installation
  1. [IMPORTANT!] Install the dependencies first;
  2. Move the [vrp_companyaccs](#vrp-company-bank-accounts) folder to your ```resources``` directory (the folder name must be all lowercase characters);
  3. Add "```start vrp_companyaccs```" to your server.cfg file;
  4. Make any changes you like to the files in the cfg folder;
  5. Enjoy!

## Changes to vRP (mandatory)
  * Add the code below to the ```vrp\modules\money.lua``` file:
    <details><summary>SHOW</summary>
    
    ```lua
    --Around the top of the file, maybe below the vRP/money_init_user query
    MySQL.createCommand("vRP/get_soldi_carta","SELECT * FROM vrp_cards WHERE user_id = @user_id")
    MySQL.createCommand("vRP/set_carta_balance","UPDATE vrp_cards SET coins = @coins WHERE user_id = @user_id")

    --Wherever you want in the file
    function vRP.impostaBankMoneyOffline(user_id,value)
        local source = vRP.getUserSource(user_id)
        if source ~= nil then
            vRP.setBankMoney(user_id,value)
        else
            MySQL.query("vRP/get_money", {user_id = user_id}, function(rows, affected)
            if rows then
                MySQL.execute("vRP/set_money", {user_id = user_id, wallet = rows[1].wallet, bank = value})
            end
            end)
        end
    end

    function vRP.tryBankMoney(user_id,amount)
      local money = vRP.getBankMoney(user_id)
      if amount > 0 and money >= amount then
        vRP.setBankMoney(user_id,money-amount)
        return true
      else
        return false
      end
    end
    ```
    </details>

## Instructions
  * Add each business you want an account for to the ```vrp_companyaccs\cfg\conti.lua``` file, in the table ```cfg.bizz```:
    <details><summary>SHOW</summary>
    
    ```lua
    {"Bank Director","bank"}
    ```
    "Bank Director" -> This is the company owner, you should already know what it is if you followed the dependencies instructions.
    "bank" -> business internal name.
    </details>
  * The public departments should be added to another table in the same file, called ```cfg.lavori```:
    <details><summary>SHOW</summary>
    
    ```lua
    {"LSPD - Head of Police","police","Captain.cloakroom"}
    ```
    "LSPD - Head of Police" -> This is the department boss' group name.
    "police" -> Internal department name (such as police, fbi, ems).
    "Captain.cloakroom" -> A permission only the boss has.
    </details>

## License
  ```
  vRP Company Bank Accounts
  Copyright (C) 2020  CPietro - Discord: @TBGaming#9941

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as published
  by the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
  ```
