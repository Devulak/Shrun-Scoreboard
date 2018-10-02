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

	local seconds = math.floor( seconds )
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
	Window:SetKeyboardInputEnabled( false );
	Window.Paint = function(self, w, h)
		self:SetWide(rem(48));
		self:InvalidateLayout(true);
		self:SizeToChildren(false, true);
		self:Center();
		draw.RoundedBox(shrun.theme.round, 0, 0, w, h, shrun.theme.bg);
	end

	Window.Header = vgui.Create("DPanel", Window);
	Window.Header:Dock(TOP);
	Window.Header.Paint = function(self, w, h)
		self:SetTall(rem(8.5));
		draw.SimpleText(GetHostName(), "FontTitle", w/2, h/2, shrun.theme.txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER);
	end

	Window.Detail = vgui.Create("DPanel", Window);
	Window.Detail:Dock(TOP);
	Window.Detail.Paint = function(self, w, h)
		self:SetTall(rem(3));
		surface.SetDrawColor(shrun.theme.bgAlternative)
		surface.DrawRect(0, 0, w, h);
		draw.SimpleText("Currently playing " .. GAMEMODE.Name .. " on the map " .. game.GetMap() .. ", with " .. (#player.GetAll() >= 2 and (#player.GetAll() - 1) or "no") .. " other player" .. (#player.GetAll() != 2 and "s" or "") .. ".", "FontSub", w/2, h/2, shrun.theme.txtAlternative, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER);
	end

	// PlayerScroll
	Window.PlayerScroll = vgui.Create("DScrollPanel", Window)
	Window.PlayerScroll:Dock(TOP);
	Window.PlayerScroll.PlayerPanels = {};
	Window.PlayerScroll.Spacer = rem(.125);
	Window.PlayerScroll.PanelHeight = rem(4);
	Window.PlayerScroll.Paint = function(self, w, h)
		self.Spacer = rem(.125)
		self.PanelHeight = rem(4)
		self:SetTall(#self.PlayerPanels * (self.PanelHeight + self.Spacer));
	end

	function scoreboard:createPlayerPanel(parent, ply)

		local playerPanel = vgui.Create("DPanel", parent);
		playerPanel:Dock(TOP);
		playerPanel.Paint = function(self, w, h)

			self:SetTall(Window.PlayerScroll.PanelHeight + Window.PlayerScroll.Spacer);

			self:SetZPos((ply:Frags() * -50) + ply:Deaths())
			surface.SetDrawColor(shrun.theme.red);
			//surface.DrawRect(0, 0, w, h - Window.PlayerScroll.Spacer);
			surface.SetDrawColor(shrun.theme.bgAlternative);
			surface.DrawRect(0, h - Window.PlayerScroll.Spacer, w, Window.PlayerScroll.Spacer);
		end
		playerPanel.player = ply;

		playerPanel.AvatarButton = playerPanel:Add("DButton");
		playerPanel.AvatarButton:Dock(LEFT);
		function playerPanel.AvatarButton:DoClick() // OnMousePressed

			playerPanel.AvatarButton:DockMargin(rem(),rem(),rem(),rem());
			playerPanel.AvatarButton:SetSize(rem(2), rem(2));

			ply:ShowProfile()
		end

		playerPanel.AvatarButton.Image = playerPanel.AvatarButton:Add("AvatarImage");
		playerPanel.AvatarButton.Image:Dock(FILL);
		playerPanel.AvatarButton.Image:SetPlayer(ply);
		playerPanel.AvatarButton.Image:SetMouseInputEnabled(false);

		playerPanel.Mute = playerPanel:Add("DImageButton");
		playerPanel.Mute:Dock(RIGHT);
		playerPanel.Mute.Paint = function(self, w, h)
			if not playerPanel.player then return end

			playerPanel.Mute:DockMargin(rem(),rem(),rem(),rem());
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

		playerPanel.NamePanel = playerPanel:Add("DPanel")
		playerPanel.NamePanel:Dock(FILL);
		playerPanel.NamePanel.Paint = function(self)
			if not playerPanel.player then return end

			playerPanel.NamePanel:DockMargin(0,rem(),0,rem());

		end

		playerPanel.NamePanel.Name = playerPanel.NamePanel:Add("DLabel")
		playerPanel.NamePanel.Name:Dock(FILL);
		playerPanel.NamePanel.Name:SetFont("FontHeader");
		playerPanel.NamePanel.Name.Paint = function(self)
			if not playerPanel.player then return end

			playerPanel.NamePanel.Name:SetTextColor(shrun.theme.txt);

			self:SetText(ply:Nick());
		end

		if evolve or ply:IsAdmin() then
			playerPanel.NamePanel.Rank = playerPanel.NamePanel:Add("DLabel");
			playerPanel.NamePanel.Rank:Dock(BOTTOM);
			playerPanel.NamePanel.Rank:SetFont("FontSub");
			playerPanel.NamePanel.Rank:SetTextColor(shrun.theme.AlternativeTxt);
			playerPanel.NamePanel.Rank.Paint = function(self, w, h)
				if not playerPanel.player then return end

				if evolve then
					local usergroup = ply:EV_GetRank()
					local bgCol = evolve.ranks[ usergroup ].Color;
					local textWidth, textHeight = scoreboard:QuickTextSize("FontSub", evolve.ranks[usergroup].Title);

					if (bgCol.r + bgCol.g + bgCol.b)/3 > 127 then
						self:SetTextColor(Color(0, 0, 0));
					else
						self:SetTextColor(Color(255, 255, 255));
					end

					self:SetWide(textWidth + rem())
					self:SetContentAlignment(5);

					draw.RoundedBox(shrun.theme.round, 0, 0, self:GetWide(), h, Color(bgCol.r, bgCol.g, bgCol.b));

					self:SetText(evolve.ranks[usergroup].Title);
				elseif ply:IsSuperAdmin() then
					self:SetText("Superadmin");
				else
					self:SetText("Admin");
				end
			end
		end

		playerPanel.Ping = playerPanel:Add("DLabel");
		playerPanel.Ping:Dock(RIGHT);
		playerPanel.Ping:SetWidth(50);
		playerPanel.Ping:SetFont("FontHeader");
		playerPanel.Ping:SetTextColor(shrun.theme.txt);
		playerPanel.Ping:SetContentAlignment(5);
		playerPanel.Ping.Paint = function(self)
			if not playerPanel.player then return end
			if self.NumPing == nil or self.NumPing != ply:Ping() then
				self.NumPing = ply:Ping();
				self:SetText(self.NumPing);
			end
		end

		playerPanel.Props = playerPanel:Add("DLabel");
		playerPanel.Props:Dock(RIGHT);
		playerPanel.Props:SetWidth(50);
		playerPanel.Props:SetFont("FontHeader");
		playerPanel.Props:SetTextColor(shrun.theme.txt);
		playerPanel.Props:SetContentAlignment(5);
		playerPanel.Props.Paint = function(self)
			if not playerPanel.player then return end
			if self.NumProps == nil or self.NumProps != (ply:GetNetworkedInt("Count.props") or 0) then
				self.NumProps = ply:GetNetworkedInt("Count.props") or 0;
				self:SetText(self.NumProps);
			end
		end

		playerPanel.Deaths = playerPanel:Add("DLabel");
		playerPanel.Deaths:Dock(RIGHT);
		playerPanel.Deaths:SetWidth(50);
		playerPanel.Deaths:SetFont("FontHeader");
		playerPanel.Deaths:SetTextColor(shrun.theme.txt);
		playerPanel.Deaths:SetContentAlignment(5);
		playerPanel.Deaths.Paint = function(self)
			if not playerPanel.player then return end
			if self.NumDeaths == nil or self.NumDeaths != ply:Deaths() then
				self.NumDeaths = ply:Deaths();
				self:SetText(self.NumDeaths);
			end
		end

		playerPanel.Frags = playerPanel:Add("DLabel");
		playerPanel.Frags:Dock(RIGHT);
		playerPanel.Frags:SetWidth(50);
		playerPanel.Frags:SetFont("FontHeader");
		playerPanel.Frags:SetTextColor(shrun.theme.txt);
		playerPanel.Frags:SetContentAlignment(5);
		playerPanel.Frags.Paint = function(self)
			if not playerPanel.player then return end
			if self.NumFrags == nil or self.NumFrags != ply:Frags() then
				self.NumFrags = ply:Frags();
				self:SetText(self.NumFrags);
			end
		end

		if evolve then
			playerPanel.Time = playerPanel:Add("DLabel");
			playerPanel.Time:Dock(RIGHT);
			playerPanel.Time:SetWidth(100);
			playerPanel.Time:SetFont("FontHeader");
			playerPanel.Time:SetTextColor(shrun.theme.txt);
			playerPanel.Time:SetContentAlignment(5);
			playerPanel.Time:SetText("");
			playerPanel.Time.Paint = function(self)
				if not playerPanel.player then return end
				if evolve then // is evolve installed?
					self.PlayTime = evolve:Time() - ply:GetNWInt("EV_JoinTime") + ply:GetNWInt("EV_PlayTime");
					if self.NumPlayTime == nil or self.NumPlayTime != self.PlayTime then
						self.NumPlayTime = self.PlayTime;
						self:SetText(scoreboard:FormatTime(self.NumPlayTime) .. " " .. scoreboard:FormatTime(self.NumPlayTime, true));
					end
				end
			end
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

	// Footer
	Window.Bottom = vgui.Create("DPanel", Window)
	Window.Bottom:Dock(TOP);
	Window.Bottom.Paint = function( self, w, h )
		self:SetTall(rem(3));
		draw.RoundedBox(shrun.theme.round, 0, -h, w, h * 2, shrun.theme.bgAlternative);
	end


	Window:Hide();

	self.Window = Window;
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