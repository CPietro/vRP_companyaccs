description "vrp_companyaccs"
dependency "vrp"

client_scripts {
	"lib/Proxy.lua",
	"lib/Tunnel.lua",
	"client.lua"
}

server_scripts {
    "@vrp/lib/utils.lua",
	"server.lua",
	"cfg/conti.lua"
}