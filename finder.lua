local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local module = loadstring(game:HttpGet("https://raw.githubusercontent.com/LeoKholYt/roblox/main/lk_serverhop.lua"))()
local paidWebhook = "https://discord.com/api/webhooks/1448505730763329607/9dAVSDfQ5ko07QMDUz3KCpu-_w1h9_DryXnIjVxHZC8iOnhrdYHIzXZFukC9MvL-yl8G"
local freeWebhook = "https://discord.com/api/webhooks/1448505856915406979/qWjUU-RkogVbIZUGhkrqUwnkARyNVVSwhEkwvEz68TWERYXCEbXkzcVJ_HkZwqyGt_vH"

local jobId = game.JobId
local placeId = game.PlaceId
local redirectUrl =
	"https://linkfowardbrainrotfinder.netlify.app/.netlify/functions/redirect-roblox"
	.. "?placeId=" .. placeId .. "&gameInstanceId=" .. jobId

local finalModelName = {
	"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16",
	"17", "18", "19", "20", "21", "22", "23", "24", "25", "26"
}

local accountedBrainrots = {}

local function strip(text)
	return tostring(text):gsub("<.->", ""):gsub("%s+", " ")
end

local function convertToNumber(str)
	str = strip(str):upper():gsub("%$", ""):gsub("/S", "")
	local mult = 1
	if str:find("K") then mult = 1e3 end
	if str:find("M") then mult = 1e6 end
	if str:find("B") then mult = 1e9 end
	if str:find("T") then mult = 1e12 end
	str = str:gsub("[KMBT]", "")
	return (tonumber(str) or 0) * mult
end

local function format(n)
	if n >= 1e6 then 
		return string.format("%.1fM/s", n / 1e6) 
	end
	if n >= 1e3 then 
		return string.format("%.1fK/s", n / 1e3) 
	end
	return tostring(n) .. "s"
end

function SendMessage(url, message)
	local http = game:GetService("HttpService")
	local headers = {
		["Content-Type"] = "application/json"
	}
	local data = {
		["content"] = message
	}
	local body = http:JSONEncode(data)
	local response = request({
		Url = url,
		Method = "POST",
		Headers = headers,
		Body = body
	})
	print("Sent")
end


local function sendEmbed(url, title, lines)
	if #lines == 0 then
		print("No brainrots detected, skipping embed.")
		return
	end

	local desc = table.concat(lines, "\n")

	if url == freeWebhook then
		SendMessage(paidWebhook, "<@&1444531574363131936>")
		desc = desc .. "\n\nPlayers in server: " .. #Players:GetPlayers() .. "/8"
	else
		desc = desc .. "\n\nPlayers in server: " .. #Players:GetPlayers() .. "/8"
		desc = desc .. "\n[Click to Join!](" .. redirectUrl .. ")"
	end

	local embedData = {
		embeds = {
			{
				title = title,
				description = desc,
				color = 16776960,  -- Yellow
			}
		}
	}

	-- Debugging: Print out the embed data to verify its structure
	print("Sending Embed with Data:", HttpService:JSONEncode(embedData))

	local success, response = pcall(function()
		return request({
			Url = url,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = HttpService:JSONEncode(embedData)
		})
	end)

	if success then
		print("Embed sent successfully.")
	else
		print("Error sending embed:", response)
	end
end

local function findBrainrotsInWorkspace()
	local paid = {}
	local free = {}

	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("BillboardGui") and instance.Name == "AnimalOverhead" then
			local name = instance:FindFirstChild("DisplayName", true)
			local mut  = instance:FindFirstChild("Mutation", true)
			local rar  = instance:FindFirstChild("Rarity", true)
			local gen  = instance:FindFirstChild("Generation", true)

			local mutation = "Normal" 
			if mut and mut.Visible and mut.Text and mut.Text ~= "" then
				mutation = strip(mut.Text)
			end

			local rarity = "No Rarity"
			if rar and strip(rar.Text) ~= "" then
				rarity = strip(rar.Text)
			end

			if strip(name.Text) == "Lucky Block" and rarity ~= "Secret" then continue end

			if name and mut and rar and gen then
				local genNum = convertToNumber(gen.Text)
				if genNum <= 0 then continue end
				local key = strip(name.Text) .. genNum .. mutation .. rarity
				if accountedBrainrots[key] then continue end
				accountedBrainrots[key] = true

				local line = "• " .. strip(name.Text) .. " | Gen: " .. format(genNum) .. " | Mut: " .. mutation .. " | Rarity: " .. rarity

				if genNum >= 10_000_000 then
					table.insert(paid, line)
				elseif rarity == "Secret" then
					table.insert(free, line)
				end
			end
		end
	end

	-- Send the results to the respective webhooks
	sendEmbed(paidWebhook, "OP Brainrots Detected", paid)
	sendEmbed(freeWebhook, "Brainrots Detected", free)
end

local TeleportService = game:GetService("TeleportService")

local function ListServers(cursor)
	local ServersUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
	local Raw = game:HttpGet(ServersUrl .. ((cursor and "&cursor=" .. cursor) or ""))
	return HttpService:JSONDecode(Raw)
end

local function TeleportToAvailableServer()
	local Server, Next = nil, nil

	repeat
		local Servers = ListServers(Next)
		Server = Servers.data[math.random(1, (#Servers.data / 3))]
		Next = Servers.nextPageCursor
	until Server

	if Server.playing < Server.maxPlayers and Server.id ~= game.JobId then
		TeleportService:TeleportToPlaceInstance(game.PlaceId, Server.id, game.Players.LocalPlayer)
	end
end


findBrainrotsInWorkspace()

while true do
	task.wait(1)
	TeleportToAvailableServer()
end
