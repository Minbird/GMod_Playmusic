local API_KEY = "AIzaSyBek-uYZyjZfn2uyHwsSQD7fyKIRCeXifU"

MPlayM = {}

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("PlayM_netPlay")
util.AddNetworkString("PlayM_netStop")
util.AddNetworkString("PlayM_netUser")
util.AddNetworkString("PlayM_netStopUser")
util.AddNetworkString("PlayM_End")
util.AddNetworkString("PlayM_New_Connect")

local playing = nil
local Length = 0
local ChannelTitle = nil
local titleText = nil

local Video_Length_Limit = 1000900000 -- 영상 제한 길이 (분).

function VLength_Limit(Length)

	local Video_Length_Limit = Video_Length_Limit * 60
	
	if Length > Video_Length_Limit then
		return false
	else
		return true
	end
end

function ParseUrl(str)
	if string.find(str,"youtube")!=nil then
		str=string.match(str,"[?&]v=([^&]*)")
	end
	
	if str == nil or str == "" then
		return "Error"
	else
		URI = str
		return str
	end
end

function PlayM_TimesThink()

	if playing then
	
		Times = CurTime() - StartTime
	
	if (math.floor(Times) / math.floor(Length)) == 1 then
		Times = 0
		net.Start("PlayM_End")
		net.Broadcast()
		playing = false
	end
	
	end
	
end

hook.Add("Think", "PlayM_TimesThink", PlayM_TimesThink)

net.Receive("PlayM_netPlay",function(len,ply)
	local URI = net.ReadString()
	
	URI = ParseUrl(URI)
	
		if playing then
			MPlayM.n("이미 재생중인 노래가 있습니다.")
			return
		end
	
		http.Fetch("https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=" .. URI .. "&key=" .. API_KEY, function(data,code,headers)
			
			local strJson = data
			json = util.JSONToTable(strJson)
			
			if json["items"][1] == nil then
				MPlayM.err("\"" .. URI .. "\"에 대한 정보가 없습니다!")
				No_Data = true
				return
			end

			local contentDetails = json["items"][1]["contentDetails"]
			
			local strVideoDuration = contentDetails["duration"]
			

			Sec = string.match(strVideoDuration, "M([^<]+)S")
			if Sec == nil then
				Sec = string.match(strVideoDuration, "H([^<]+)S")
				if Sec == nil then
					Sec = string.match(strVideoDuration, "PT([^<]+)S")
					if Sec == nil then
						Sec = 0
					end
				end
			end
			
			Min = string.match(strVideoDuration, "H([^<]+)M")
			if Min == nil then
				Min = string.match(strVideoDuration, "PT([^<]+)M")
				if Min == nil then
					Min = 0
				end
			end
			
			Hour = string.match(strVideoDuration, "PT([^<]+)H")
			if Hour == nil then
				Hour = 0
			end
			
			Length = Sec + Min * 60 + Hour * 3600 + 1

		end,nil)
		
			http.Fetch("https://www.googleapis.com/youtube/v3/videos?part=snippet&id=" .. URI .. "&key=" .. API_KEY, function(data,code,headers)
				
				local strJson = data
				json = util.JSONToTable(strJson)
				
				if json["items"][1] == nil then
					MPlayM.err("\"" .. URI .. "\"에 대한 정보가 없습니다!")
					No_Data = true
					return
				end
				
				local snippet = json["items"][1]["snippet"]
				
				titleText = snippet["title"]
				ChannelTitle = snippet["channelTitle"]
				IsliveBroadcast = snippet["liveBroadcastContent"]
				
		end,nil)
		
		timer.Simple( 1, function() 

		
		if titleText == nil or Length == 0 or No_Data then
			MPlayM.err("서버에서 올바른 응답을 받지 못했습니다. " .. "(대상:" .. URI .. ") (영상 데이터를 받아오지 못했거나 처리 도중 문제가 발생했습니다.)")
			net.Start("PlayM_End")
			net.Broadcast()
			No_Data = false
			return
		elseif IsliveBroadcast == "live" then
			MPlayM.n("실시간 스트리밍 콘텐츠는 재생할 수 없습니다.")
			net.Start("PlayM_End")
			net.Broadcast()
			No_Data = false
			return
		elseif not VLength_Limit(Length) then
			MPlayM.n("이 영상은 길이가 너무 깁니다. 최대 " .. Video_Length_Limit .. "분 이하만 재생할 수 있습니다.")
			net.Start("PlayM_End")
			net.Broadcast()
			No_Data = false
			return
		else
			MPlayM.n("재생중: ".. titleText .." [채널: " .. ChannelTitle .. " ] [" .. Length .. "초]")

		end
			
		net.Start("PlayM_netPlay")
			net.WriteString(URI)
			net.WriteString(ChannelTitle)
			net.WriteString(titleText)
			net.WriteString(Length)
		net.Broadcast()

		print("재생 시작: " .. URI)
		StartTime = CurTime()
		
		playing = true
		
		end)
end)

function PlayerInitialSpawn(ply)
timer.Simple( 1, function() 
	if playing then
		net.Start("PlayM_New_Connect")
			net.WriteString(URI)
			net.WriteString(ChannelTitle)
			net.WriteString(titleText)
			net.WriteString(Length)
			net.WriteString(Times)
			net.WriteString(StartTime)
		net.Send(ply)
	end
end)
end

hook.Add("PlayerInitialSpawn", "PlayerInitialSpawn", PlayerInitialSpawn)

net.Receive("PlayM_netStop",function(len,ply)

		net.Start("PlayM_netStop")
		net.Broadcast()
		
		playing = false
		
end)
net.Receive("PlayM_netUser",function(len,ply)

		net.Start("PlayM_netUser")
			net.WriteString(net.ReadString())
		net.Broadcast()
		
		
end)
net.Receive("PlayM_netStopUser",function(len,ply)

		net.Start("PlayM_netStopUser")
			net.WriteString(net.ReadString())
		net.Broadcast()
		
end)
net.Receive("PlayM_End",function(len,ply)

	if playing then
		net.Start("PlayM_End")
		net.Broadcast()
		playing = false
	else
		return
	end
end)

MPlayM.n = function(text)
	text = (sender and (sender .. " @ ") or "") .. text
	MNotice.LastMessage = text
	text = "[PlayMusic] " .. text
	PrintMessage(HUD_PRINTTALK, text)
end

MPlayM.err = function(text)
	text = (sender and (sender .. " @ ") or "") .. text
	MNotice.LastMessage = text
	text = "[PlayMusic Error] " .. text
	PrintMessage(HUD_PRINTTALK, text)
end

print("[Playmusic] Server - complete!")