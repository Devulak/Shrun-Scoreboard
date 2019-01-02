// Debugging
if CLIENT and scoreboard and scoreboard.window then
	scoreboard.window:Remove();
end

local scoreboard = scoreboard or {};

if SERVER then
	timer.Simple(1, function()
		scoreboard.GetCount = _R.Player.GetCount
		function _R.Player:GetCount(limit, minus)
			if limit == "props" then
				timer.Simple(.1, function() scoreboard.GetCount(self, limit, 0) end)
			end
			return scoreboard.GetCount(self, limit, minus)
		end
	end)
end

// Simplify common used things
local function rem(multiply)
	if multiply == nil then
		multiply = 1;
	end
	return multiply * shrun.theme.rem;
end

function scoreboard:QuickTextSize( font, text )
	surface.SetFont( font )
	return surface.GetTextSize( text )
end

function scoreboard:FormatTime( seconds, showSecond )

	local seconds = math.floor(seconds)
	local minutes = math.floor(seconds/60)
	local hours = math.floor(minutes/60)
	local time = 0
	local text = ""

	if hours >= 1 then
		time = hours;
		text = "hour";
	elseif minutes >= 1 then
		time = minutes;
		text = "minute";
	else
		time = seconds;
		text = "second";
	end

	return (showSecond == true and text .. (time != 1 and "s" or "") or time)

end

function scoreboard:init()
	if self.Window then
		return;
	end

	// Actual work on it
	Window = vgui.Create("DPanel");

	Window:SetZPos(10);
	Window:MakePopup();
	Window:SetKeyboardInputEnabled(false);
	Window:DockPadding(rem(),rem(),rem(),rem());
	Window.Paint = function(self, w, h)
		self:SetWide(rem(48));
		self:InvalidateLayout(true);
		self:SizeToChildren(false, true);
		self:Center();
		draw.RoundedBox(shrun.theme.round, 0, 0, w, h, shrun.theme.bgAlternative);
	end

	Window.Header = vgui.Create("DPanel", Window);
	Window.Header:Dock(TOP);
	Window.Header.Paint = function(self, w, h)
		self:SetTall(rem(6.5));
		// draw.RoundedBox(shrun.theme.round, 0, 0, w, h, shrun.theme.bg);
		draw.SimpleText(
			GetHostName(), 
			"FontTitle", 
			w/2 + rem(.2), 
			h/2 + rem(.2), 
			shrun.theme.txt, 
			TEXT_ALIGN_CENTER, 
			TEXT_ALIGN_BOTTOM
		);
		draw.SimpleText(
			"Currently playing " ..
			GAMEMODE.Name ..
			" on the map " ..
			game.GetMap() ..
			", with " ..
			(#player.GetAll() >= 2 and (#player.GetAll() - 1) or "no") ..
			" other player" ..
			(#player.GetAll() != 2 and "s" or "") ..
			".",
			"FontSub", 
			w/2 + rem(.2), 
			h/2 + rem(.2), 
			shrun.theme:Transparency(shrun.theme.txt, .25), 
			TEXT_ALIGN_CENTER, 
			TEXT_ALIGN_TOP
		);
	end

	// PlayerScroll
	Window.PlayerScroll = vgui.Create("DScrollPanel", Window)
	Window.PlayerScroll:Dock(TOP);
	Window.PlayerScroll.PlayerPanels = {};
	Window.PlayerScroll.Paint = function(self, w, h)
		// draw.RoundedBox(shrun.theme.round, 0, 0, w, h, shrun.theme.blue);

		local playerTall = #self.PlayerPanels * (self.PlayerPanels[1]:GetTall() + rem());

		if playerTall + Window.Header:GetTall() + rem(2) >= ScrH() - rem(2) then
			self:SetTall(self:GetTall() - (Window:GetTall() - ScrH() + rem(2)));
		else
			self:SetTall(#self.PlayerPanels * (self.PlayerPanels[1]:GetTall() + rem()));
		end
	end

	function scoreboard:createPlayerPanel(parent, ply)

		local playerPanel = vgui.Create("DPanel", parent);
		playerPanel.player = ply;
		playerPanel:Dock(TOP);
		playerPanel.Paint = function(self, w, h)
			if not IsValid(ply) then return end

			playerPanel:DockMargin(0, rem(), 0, 0);
			playerPanel:DockPadding(rem(), rem(), rem(), rem());
			playerPanel:SetTall(rem(4));

			local immunity = tonumber(evolve.ranks[(ply or LocalPlayer()):EV_GetRank()].Immunity);
			local frags = ply:Frags();
			self:SetZPos(- frags - immunity * 100);

			local lineColour = shrun.theme.bg;
			if ply:IsSuperAdmin() then
				lineColour = shrun.theme.red;
			elseif ply:IsAdmin() then
				lineColour = shrun.theme.yellow;
			end

			draw.RoundedBox(shrun.theme.round, 0, 0, w, h, lineColour);

			draw.RoundedBox(shrun.theme.round - 1, 1, 1, w - 2, h - 2, shrun.theme.bg);
		end

		playerPanel.AvatarButton = playerPanel:Add("DButton");
		playerPanel.AvatarButton:Dock(LEFT);
		playerPanel.AvatarButton.Paint = function(self, w, h)
			playerPanel.AvatarButton:DockMargin(0, 0, rem(), 0);
			playerPanel.AvatarButton:SetSize(rem(2), rem(2));
		end
		function playerPanel.AvatarButton:DoClick() // OnMousePressed
			ply:ShowProfile()
		end

		playerPanel.AvatarButton.Image = playerPanel.AvatarButton:Add("AvatarImage");
		playerPanel.AvatarButton.Image:Dock(FILL);
		playerPanel.AvatarButton.Image:SetPlayer(ply);
		playerPanel.AvatarButton.Image:SetMouseInputEnabled(false);

		playerPanel.Mute = playerPanel:Add("DImageButton");
		playerPanel.Mute:Dock(RIGHT);
		playerPanel.Mute.Paint = function(self, w, h)
			if not IsValid(ply) then return end

			playerPanel.Mute:DockMargin(rem(), 0, 0, 0);
			playerPanel.Mute:SetSize(rem(2), rem(2));

			if self.Muted == nil or self.Muted != ply:IsMuted() then
				self.Muted = ply:IsMuted();
				if self.Muted then
					self:SetImage("icon32/muted.png");
				else
					self:SetImage("icon32/unmuted.png");
				end
				self.DoClick = function()
					ply:SetMuted(!self.Muted)
				end
			end
		end

		playerPanel.FillPanel = playerPanel:Add("DPanel");
		playerPanel.FillPanel:Dock(FILL);
		playerPanel.FillPanel.Paint = function(self, w, h)
			if not IsValid(ply) then return end

			// draw.RoundedBox(shrun.theme.round, 0, 0, w, h, shrun.theme.red);
		end

		playerPanel.FillPanel.Name = playerPanel.FillPanel:Add("DLabel")
		playerPanel.FillPanel.Name:Dock(TOP);
		playerPanel.FillPanel.Name:SetFont("FontHeader");
		playerPanel.FillPanel.Name.Paint = function(self, w, h)
			if not IsValid(ply) then return end
			
			self:SetTall(rem());

			// draw.RoundedBox(shrun.theme.round, 0, 0, w, h, shrun.theme.blue);

			playerPanel.FillPanel.Name:SetTextColor(shrun.theme.txt);
			self:SetText(ply:Nick());
		end

		playerPanel.FillPanel.Tags = playerPanel.FillPanel:Add("DPanel")
		playerPanel.FillPanel.Tags:Dock(FILL);
		playerPanel.FillPanel.Tags.Paint = function(self, w, h)
			if not IsValid(ply) then return end
		end

		if evolve or ply:IsAdmin() then
			playerPanel.FillPanel.Tags.Rank = playerPanel.FillPanel.Tags:Add("DLabel");
			playerPanel.FillPanel.Tags.Rank:Dock(LEFT);
			playerPanel.FillPanel.Tags.Rank:SetFont("FontSubBold");
			playerPanel.FillPanel.Tags.Rank:SetTextColor(shrun.theme.AlternativeTxt);
			playerPanel.FillPanel.Tags.Rank.Paint = function(self, w, h)
			if not IsValid(ply) then return end

				self:DockMargin(0,0,rem(.25),0);

				if evolve then
					local usergroup = ply:EV_GetRank()
					local bgCol = evolve.ranks[ usergroup ].Color or Color(255, 255, 100);
					local textWidth = scoreboard:QuickTextSize("FontSub", evolve.ranks[usergroup].Title);

					if (bgCol.r + bgCol.g + bgCol.b)/3 > 155 then
						self:SetTextColor(Color(0, 0, 0));
					else
						self:SetTextColor(Color(255, 255, 255));
					end

					self:SetWide(textWidth + rem())
					self:SetContentAlignment(5);

					draw.RoundedBox(shrun.theme.round, 0, 0, w, h, Color(bgCol.r, bgCol.g, bgCol.b));

					self:SetText(evolve.ranks[usergroup].Title);
				elseif ply:IsSuperAdmin() then
					self:SetText("Superadmin");
				else
					self:SetText("Admin");
				end
			end
		end

		scoreboard:CreateBoxStatus(playerPanel, "LATENCY", function() return ply:Ping() or 0 .. " ms"; end);
		scoreboard:CreateBoxStatus(playerPanel, "PROPS", function() return ply:GetNetworkedInt("Count.props") or 0 end);
		scoreboard:CreateBoxStatus(playerPanel, "DEATHS", function() return ply:Deaths() or 0; end);
		scoreboard:CreateBoxStatus(playerPanel, "FRAGS", function() return ply:Frags() or 0; end);

		if evolve then // is evolve installed?
			scoreboard:CreateBoxStatus(playerPanel, "PLAYTIME", function()
				self.PlayTime = evolve:Time() - ply:GetNWInt("EV_JoinTime") + ply:GetNWInt("EV_PlayTime");
				if self.NumPlayTime == nil or self.NumPlayTime != self.PlayTime then
					self.NumPlayTime = self.PlayTime;
				end
				return scoreboard:FormatTime(self.NumPlayTime) .. " " .. scoreboard:FormatTime(self.NumPlayTime, true);
			end);
		end

		return playerPanel;
	end

	// Scrollbar
	/*Window.PlayerScroll.Scrollbar = Window.PlayerScroll:GetVBar()
	Window.PlayerScroll.Scrollbar:SetWide( rem(.25) )
	Window.PlayerScroll.Scrollbar:DockMargin( 0, -rem(.25), rem(.25) + rem(.125), -rem(.25) )
	function Window.PlayerScroll.Scrollbar:Paint( self, w, h )

	end
	Window.PlayerScroll.Scrollbar.btnUp:Hide()
	Window.PlayerScroll.Scrollbar.btnDown:Hide()
	function Window.PlayerScroll.Scrollbar.btnGrip:Paint( self, w, h )

		draw.RoundedBox( rem(0.125), 0, 0, w, h, shrun.theme.bgAlternative )

	end*/


	Window:Hide();

	self.Window = Window;
end

function scoreboard:CreateBoxStatus(parent, text, value)
	local BoxStatus = parent:Add("DPanel");
	BoxStatus:Dock(RIGHT);
	BoxStatus.Paint = function(self, w, h)
		if not IsValid(parent.player) then return end

		self:DockMargin(rem(), 0, 0, 0);

		val = value();

		textWidth = scoreboard:QuickTextSize("FontSubBold", text);

		valWidth = scoreboard:QuickTextSize("FontSubBold", val);

		if valWidth > textWidth then
			self:SetWidth(valWidth);
		else
			self:SetWidth(textWidth);
		end

		// draw.RoundedBox(shrun.theme.round, 0, 0, w, h, shrun.theme.blue);

		draw.SimpleText(
			text,
			"FontSubBold", 
			w/2, 
			h/2, 
			shrun.theme:Transparency(shrun.theme.txt, .25),
			TEXT_ALIGN_CENTER, 
			TEXT_ALIGN_TOP
		);

		draw.SimpleText(
			val,
			"FontSubBold", 
			w/2, 
			h/2, 
			shrun.theme.txt,
			TEXT_ALIGN_CENTER, 
			TEXT_ALIGN_BOTTOM
		);
	end

	return BoxStatus;
end


function scoreboard:HUDDrawScoreBoard()
	if not self.Window or !self.Window:IsVisible() then
		return;
	end

	// Remove anything NOT in the players GetAll!
	for k, v in pairs(self.Window.PlayerScroll.PlayerPanels) do
		if not IsValid(v.player) then
			// Remove the row
			v:Remove();
			v.player = nil;
			table.remove(self.Window.PlayerScroll.PlayerPanels, k);
		end 
	end

	// Add anything NOT in the players list!
	for k, v in pairs(player.GetAll()) do
		local found;
		for _, ply in pairs(self.Window.PlayerScroll.PlayerPanels) do
			if v == ply.player then
				found = true;
				break;
			end
		end
		if not found then
			// Add the row
			local playerPanel = self:createPlayerPanel(self.Window.PlayerScroll, v);

			table.insert(self.Window.PlayerScroll.PlayerPanels, playerPanel);
		end 
	end
end

function scoreboard:show()
	scoreboard:init();
	self.Window:Show();
end

function scoreboard:hide()
	scoreboard:init();
	self.Window:Hide();
	playerAmount = 0;
end

// Hooks
hook.Add("ScoreboardShow", "ShrunScoreboardShow", function()
	if engine.ActiveGamemode() == "sandbox" then
		scoreboard:show();
		return true;
	end
end)

hook.Add("ScoreboardHide", "ShrunScoreboardHide", function()
	if engine.ActiveGamemode() == "sandbox" then
		scoreboard:hide();
		return true;
	end
end)

hook.Add("HUDDrawScoreBoard", "ShrunHUDDrawScoreBoard", function()
	if engine.ActiveGamemode() == "sandbox" then
		scoreboard:HUDDrawScoreBoard();
		return true;
	end
end)