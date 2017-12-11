--local MsModules = MsModules_Playmusic

-- html:QueueJavascript([[player.seekTo(]] .. args .. [[, true)]])

local Ver = "1.0"

include("shared.lua")

MsModules = {}
MPlayM = {}

local Music = ""
local Length = 0
local State = ""
local playing = false
local alpha = 1
local StateText = ""
local Do_fade = false
local URI = ""
local HUDalpha = 0
local Tog_VideoShow = false
local Volume = 0
local HUD_Show = true -- 플레이어 HUD 표시 여부. false면 기본적으로 표시하지 않음. true면 기본적으로 표시함. 인게임에서 !playmusic hud로 조작 가능.
local StopUser = "nil"
local Min = 0
local Sec = 0
local SongLength = 0
local StartTime = 0
local PlayTime = 0
local PlayingUser = "nil"
local vol = 100
local titleText = ""
local Vol_Music = ""
local New_Connect = nil

timer.Simple( 1, function()
html = vgui.Create("DHTML")
html:SetPos(ScrW() / 3 - 106 ,-8)
html:SetSize(106,60)
html:SetPaintedManually(true)
html:SetMouseInputEnabled(false)
html:SetEnabled(true)
html:SetHTML("")
end)

surface.CreateFont("MinPlaymusic_Title",{
font    = "UiBold",
size    = ScreenScale(6),
weight  = 600,
antialias = true,
shadow = false})

surface.CreateFont("MinPlaymusic_Sec",{
font    = "UiBold",
size    = ScreenScale(5),
weight  = 300,
antialias = true,
shadow = false})

MsModules.Playmusic = function(ply, text, teamchat, isdead, station, c, args)

	if MsModules.CallPlaymusic(text) and ply == LocalPlayer() then
		local command, args = MsModules.ExtractCommandArgs(text)
		
		args = args
		
		if string.len(command) == 0 then
			chat.AddText(Color(100, 255, 255), "\n\n사용 방법  PlayMusic " .. Ver)
			chat.AddText(Color(100, 255, 255), "!playmusic play {YouTube URL}")
			chat.AddText(Color(100, 255, 255), "유튜브 URL을 통해 노래를 재생합니다.")
			chat.AddText(Color(100, 255, 255), "!playmusic stop")
			chat.AddText(Color(100, 255, 255), "재생 중인 노래를 중지합니다. 만약 관리자이거나 내가 재생한 노래이면 모두에게 적용됩니다.")
			chat.AddText(Color(100, 255, 255), "!playmusic vol")
			chat.AddText(Color(100, 255, 255), "볼륨을 조절합니다 (0~100)")
			chat.AddText(Color(100, 255, 255), "!playmusic showvideo")
			chat.AddText(Color(100, 255, 255), "영상의 화면을 플레이어 옆에 표시하거나 취소합니다.")
			chat.AddText(Color(100, 255, 255), "!playmusic hud")
			chat.AddText(Color(100, 255, 255), "플레이어의 HUD를 숨기거나 표시합니다.\n")
		
		elseif command == "play" then
			if string.len(args) == 0 then
				MPlayM.n("유튜브 URL을 입력하세요.")
			else
			
				Fileaddress = args
				
				if string.Left(Fileaddress, 32) == "https://www.youtube.com/watch?v=" then
			
					MPlayM.n("재생 준비중: " .. Fileaddress)
					address = Fileaddress
					--PlayM_Play(net.ReadString())
					Do_fade = true
					
					if Fileaddress == "Error" then
						MPlayM.err("URL을 처리하던 도중 문제가 발생했습니다.")
						Do_fade = false
						playing = false
						Music = ""
					else
						net.Start("PlayM_netPlay")
							net.WriteString(address)
						net.SendToServer()
						
						net.Start("PlayM_netUser")
							net.WriteString(ply:Nick())
						net.SendToServer()
						
					end
					
				else
					MPlayM.n(Fileaddress .. "은(는) 유효한 주소가 아닙니다.")
				end
				
			end
		
		
		elseif command == "stop" then
		
			
			if ply:IsAdmin() then
					net.Start("PlayM_netStopUser")
						net.WriteString("IsAdmin")
					net.SendToServer()
					net.Start("PlayM_netStop")
					net.SendToServer()
			elseif ply:Nick() == PlayingUser then
					net.Start("PlayM_netStopUser")
						net.WriteString(ply:Nick())
					net.SendToServer()
					net.Start("PlayM_netStop")
					net.SendToServer()
				
			else
				PlayM_Stop()
			end

		
		elseif command == "showvideo" then
			if not Tog_VideoShow then
				html:SetPos(ScrW() / 3 - 106,0)
				html:SetSize(106,60)
				html:SetPaintedManually(false)
				MPlayM.n("이제 영상 화면을 표시합니다.")
				Tog_VideoShow = true
			else
				html:SetPos(ScrW() / 3 - 106,0)
				html:SetSize(106,60)
				html:SetPaintedManually(true)
				MPlayM.n("이제 영상 화면을 표시하지 않습니다.")
				Tog_VideoShow = false
			end
		
		elseif command == "vol" then
			if string.len(args) == 0 then
				MPlayM.n("플레이어 볼륨을 조절합니다. (0~100)")
				MPlayM.n("현재 볼륨은 " .. vol .. "%입니다.")
				Music = "현재 볼륨은 " .. vol .. "%입니다."
				timer.Simple( 5, function() Music = Vol_Music end )
			else
				vol = args
				if string.match(vol, "[%a]") then
					MPlayM.n(vol .. "은(는) 잘못된 값입니다. 0부터 100 사이의 정수를 입력하십시오.")
					return
				end
				vol = math.Clamp( vol + 0, 0, 100 )
				
				MPlayM.n(vol .. "%로 변경되었습니다.")
				html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]])
				
				Music = vol .. "%로 변경되었습니다."
				timer.Simple( 5, function() Music = Vol_Music end )
				
			end
		
		elseif command == "hud" then --
			if HUD_Show then
				MPlayM.n("PlayMusic의 HUD를 숨깁니다.")
				timer.Simple( 2, function() HUD_Show = false end)
				Do_fade = false
			else
				MPlayM.n("PlayMusic의 HUD를 다시 표시합니다.")
				HUD_Show = true
				Do_fade = true
			end
		else
			
			MPlayM.n("알 수 없는 명령입니다. 자세한 명령어 목록을 보려면 !playmusic 을 입력하세요.")
	
		end
	end
end

hook.Add("OnPlayerChat", "MsModules.Playmusic", MsModules.Playmusic)

function PlaymusicHUD()

	local nextThink = 0
	local curTime = CurTime()
	
		
	if not HUD_Show then
		alpha = 0
	else
		alpha = 1
	
		if (nextThink < curTime) then
			if Do_fade then
				if HUDalpha == 200 then
				else
				HUDalpha = HUDalpha + 1
				end
			else
				if HUDalpha == 0 then 
				else
				HUDalpha = HUDalpha - 1
				end
			end
			nextThink = curTime + 0.01
		end
	end
	
	if Times == nil then
		Times = 0
	end

	--PlayTime_Hour = math.floor(Times / 3600)
	PlayTime_Min = math.floor(Times / 60) -- 플레이 타임
	PlayTime_Sec = tostring(math.floor(Times-PlayTime_Min*60))
	if string.len(PlayTime_Sec)==1 then PlayTime_Sec="0"..PlayTime_Sec end
	
	--MusicTime_Hour = math.floor(Length / 3600)
	MusicTime_Min = math.floor(Length / 60) -- 음악 길이
	MusicTime_Sec = tostring(math.floor(Length-MusicTime_Min*60))
	if string.len(MusicTime_Sec)==1 then MusicTime_Sec="0"..MusicTime_Sec end
	
	if PlayTime_Min > 0 then
		PlayTime = PlayTime_Min .. ":" .. PlayTime_Sec
	else
		PlayTime = PlayTime_Sec
	end
	
	if MusicTime_Min > 0 then
		MusicTime = MusicTime_Min .. ":" .. MusicTime_Sec
	else
		MusicTime = MusicTime_Sec
	end

	draw.RoundedBox( 0, ScrW() / 3, 0, ScrW() / 3, 60, Color( 50, 50, 50, HUDalpha * alpha ) )
	draw.RoundedBox( 0, ScrW() / 3, 50, (ScrW() / 3), 10, Color( 160, 160, 160, HUDalpha * alpha ) ) 
	draw.RoundedBox( 0, ScrW() / 3, 50, (ScrW() / 3) * Times / Length, 10, Color( 255, 0, 0, HUDalpha * alpha ) )
	draw.DrawText( Music, "MinPlaymusic_Title", ScrW() * 0.5, 7, Color( 255, 255, 0, HUDalpha * alpha ), TEXT_ALIGN_CENTER )
	draw.DrawText( PlayTime .. " / " .. MusicTime, "MinPlaymusic_Sec", ScrW() * 0.5, 35, Color( 255, 255, 0, HUDalpha * alpha ), TEXT_ALIGN_CENTER )
end

local nextThink = 0

hook.Add("HUDPaint", "PlaymusicHUD", PlaymusicHUD)

function PlayM_TimesThink()

	if playing then

			Times = CurTime() - StartTime

	end
end

hook.Add("Think", "PlayM_TimesThink", PlayM_TimesThink)

function PlayM_Play(URI)

	timer.Simple( 0.5, function() if titleText == nil or Length == 0 then
			Music = "서버에서 올바른 응답을 받지 못했습니다. " .. "(대상:" .. URI .. ")"
			MPlayM.err("서버에서 올바른 응답을 받지 못했습니다. " .. "(대상:" .. URI .. ")")
			return
		else
		
			if string.len(titleText) > 70 then
				Music = string.Left(titleText, 70) .. "..."
			elseif (ScrW() <= 1360) and (ScrH() <= 768) and string.len(titleText) > 60 then
				Music = string.Left(titleText, 60) .. "..."
			else
				Music = titleText
			end
			
			Vol_Music = Music
			
			Do_fade = true
			playing = true
			
			if New_Connect then
			
				html:OpenURL("http://ziondevelopers.github.io/playx/youtubehost.html?url=https://youtube.com/watch?v=" .. URI)
				html:QueueJavascript([[player.seekTo(]] .. Play_Time + 1 .. [[, true)]])
				timer.Simple( 1, function() html:QueueJavascript([[player.seekTo(]] .. Play_Time + 2 .. [[, true)]]) end)
				timer.Simple( 2, function() html:QueueJavascript([[player.seekTo(]] .. Play_Time + 3 .. [[, true)]]) end)
				timer.Simple( 3, function() html:QueueJavascript([[player.seekTo(]] .. Play_Time + 4 .. [[, true)]]) end)
				timer.Simple( 4, function() html:QueueJavascript([[player.seekTo(]] .. Play_Time + 5 .. [[, true)]]) end)
				timer.Simple( 5, function() html:QueueJavascript([[player.seekTo(]] .. Play_Time + 6 .. [[, true)]]) end)
				html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]])
				timer.Simple( 1, function() html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]]) end)
				timer.Simple( 2, function() html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]]) end)
				timer.Simple( 3, function() html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]]) end)
				timer.Simple( 4, function() html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]]) end)
				timer.Simple( 5, function() html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]]) end)
				
				New_Connect = false
			
			else
			
				html:OpenURL("http://ziondevelopers.github.io/playx/youtubehost.html?url=https://youtube.com/watch?v=" .. URI)
				StartTime = CurTime()
				html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]])
				timer.Simple( 1, function() html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]]) end)
				timer.Simple( 2, function() html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]]) end)
				timer.Simple( 3, function() html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]]) end)
				timer.Simple( 4, function() html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]]) end)
				timer.Simple( 5, function() html:QueueJavascript([[player.setVolume(]] .. vol .. [[)]]) end)
			
			end
			
	end end)
		

end

function PlayM_Stop()
	if not playing then
		MPlayM.n("재생되고 있는 음악이 없습니다.")
		Do_fade = false
		playing = false
		html:SetHTML("") 
	else
		MPlayM.n("음악 재생을 종료합니다.")
		playing = false
		Do_fade = false
		Length = 0
		Times = 0
		html:SetHTML("")
		PlayingUser = "nil"
	end
end


MPlayM.err = function(text)
	text = (sender and (sender .. " @ ") or "") .. text
	MNotice.LastMessage = text
	text = "[PlayMusic Error] " .. text
	chat.AddText(text)
end

MPlayM.n = function(text)
	text = (sender and (sender .. " @ ") or "") .. text
	MNotice.LastMessage = text
	text = "[PlayMusic] " .. text
	chat.AddText(text)
end

MsModules.CallPlaymusic = function(text) 
	return string.Left(text, 10) == "!playmusic"
end

MsModules.ExtractCommandArgs = function(text)
	if string.len(text) <= 10 then
		return "", ""
	end
	local exploded = string.Explode(" ", text)
	table.remove(exploded, 1)
	local command = exploded[1]
	table.remove(exploded, 1)
	local args = table.concat(exploded, " ")
	
	return command, args
end

net.Receive("PlayM_netPlay",function(len)

	URI = net.ReadString()
	ChannelTitle = net.ReadString()
	titleText = net.ReadString()
	Length = net.ReadString()
	PlayM_Play(URI)
end)
net.Receive("PlayM_netStopUser",function(len)
	StopUser = net.ReadString()
end)
net.Receive("PlayM_netStop",function(len)
	
	if PlayingUser == StopUser then
		MPlayM.n(StopUser .. "님이 음악을 종료합니다.")
		PlayM_Stop()
	elseif StopUser == "IsAdmin" then
		MPlayM.n("관리자가 음악을 종료합니다.")
		PlayM_Stop()
	else
		MPlayM.err("PlayM_netStop: 잘못된 요청입니다. 요청한 플레이어(" .. StopUser .. ")가 PlayingUser(" .. PlayingUser .. ") 이거나 관리자 권한이 있어야 합니다.")
	end
end)
net.Receive("PlayM_netUser",function(len)
	PlayingUser = net.ReadString()
	MPlayM.n(PlayingUser .. "님이 재생합니다.")
	
end)

net.Receive("PlayM_End",function(len)
	MPlayM.n("음악 재생을 종료합니다.")
		playing = false
		Do_fade = false
		Length = 0
		Times = 0
		html:SetHTML("")
		PlayingUser = "nil"
end)
net.Receive("PlayM_New_Connect",function(len)

	if New_Connect == nil then
		New_Connect = true

		URI = net.ReadString()
		ChannelTitle = net.ReadString()
		titleText = net.ReadString()
		Length = net.ReadString()
		Play_Time = net.ReadString()
		StartTime = net.ReadString()
	
		PlayM_Play(URI)
	
	end
end)


print("[Playmusic] Client - complete!")

local nextThink = 0