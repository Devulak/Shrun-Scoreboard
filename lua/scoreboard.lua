// Debugging
if CLIENT and scoreboard and scoreboard.window then
	scoreboard.window:Remove();
end

local scoreboard = {};

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

if CLIENT then
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
			time = hours
			text = "hour" .. (hours != 1 and "s" or "")
		elseif minutes >= 1 then
			time = minutes
			text = (minutes != 1 and "minutes" or "minute")
		else
			time = seconds
			text = (seconds != 1 and "seconds" or "second")
		end

		return (showSecond == true and text or time)

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
		Window.Detail:SetTall(rem(3));
		Window.Detail.Paint = function(self, w, h)
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
			self:SetTall(#self.PlayerPanels * (self.PanelHeight + self.Spacer));
			surface.SetDrawColor(shrun.theme.txt);
			surface.DrawRect(0, 0, w, h);
		end

		function scoreboard:createPlayerPanel(parent, ply)

			local playerPanel = vgui.Create("DPanel", parent);
			playerPanel:Dock(TOP);
			playerPanel:SetTall(Window.PlayerScroll.PanelHeight + Window.PlayerScroll.Spacer);
			playerPanel.Paint = function(self, w, h)
				surface.SetDrawColor(shrun.theme.red);
				surface.DrawRect(0, 0, w, h - Window.PlayerScroll.Spacer);
				surface.SetDrawColor(shrun.theme.green);
				surface.DrawRect(0, h - Window.PlayerScroll.Spacer, w, Window.PlayerScroll.Spacer);
			end
			playerPanel.player = ply;

			playerPanel.AvatarButton = vgui.Create("DButton", playerPanel);
			playerPanel.AvatarButton:Dock(LEFT);
			playerPanel.AvatarButton:DockMargin(rem(),rem(),rem(),rem());
			playerPanel.AvatarButton:SetSize(rem(2), rem(2));
			function playerPanel.AvatarButton:DoClick() // OnMousePressed
				ply:ShowProfile()
			end

			playerPanel.AvatarButton.Image = vgui.Create("AvatarImage", playerPanel.AvatarButton);
			playerPanel.AvatarButton.Image:Dock(FILL);
			playerPanel.AvatarButton.Image:SetPlayer(ply);
			playerPanel.AvatarButton.Image:SetMouseInputEnabled(false);

			playerPanel.Name = self:Add("DLabel", playerPanel)
			playerPanel.Name:Dock(FILL);
			playerPanel.Name:SetFont("ScoreboardDefault");
			playerPanel.Name:SetTextColor(Color( 93, 93, 93 ));
			playerPanel.Name:DockMargin(8, 0, 0, 0);

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
		Window.Footer = vgui.Create("DPanel", Window)
		Window.Footer:Dock(TOP);
		Window.Footer.Paint = function( self, w, h )
			self:SetTall(rem(3));
			draw.RoundedBox(shrun.theme.round, 0, 0, w, h, shrun.theme.bgAlternative);
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
			local found;
			for _, ply in pairs(player.GetAll()) do
				if v.player == ply then
					found = true;
					break;
				end
			end
			if not found then
				// Remove the row
				v:Remove();
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

		// Playerlist
		/*if playerAmount != #player.GetAll() then

			playerAmount = #player.GetAll()

			local playerInfo = {}
			for _, v in pairs( player.GetAll() ) do
				table.insert( playerInfo, { Player = v, Nick = v:Nick(), Usergroup = v:EV_GetRank(), Frags = v:Frags(), Deaths = v:Deaths(), Ping = v:Ping(), PlayTime = evolve:Time() - v:GetNWInt( "EV_JoinTime" ) + v:GetNWInt( "EV_PlayTime" )
				, Propcount = v:GetNetworkedInt("Count.props") or 0
				} )
			end
			table.SortByMember( playerInfo, "PlayTime" )

			self.Window.PlayerScroll:Clear()

			local spacing = 0

			for k, v in pairs( playerInfo ) do

				self.Window.PlayerPanel = vgui.Create( "DPanel", self.Window.PlayerScroll )
				self.Window.PlayerPanel:SetSize( self.Window.PlayerScroll:GetWide(), rem(4) )
				self.Window.PlayerPanel:SetPos( 0, spacing )
				self.Window.PlayerPanel.Paint = function()

					// Background

					// Nick
					draw.SimpleText( v.Nick, "FontHeader", rem(4+3), rem(1.5), Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

					// PlayTime
					local col = evolve.ranks[ v.Usergroup ].Color

					local textWidth, textHeight = self:QuickTextSize( "FontSub", evolve.ranks[ v.Usergroup ].Title )
					draw.RoundedBox(3, rem(4+3), rem(3) - textHeight/2 - rem(.1), textWidth + rem(.5), textHeight + rem(.2), Color( col.r, col.g, col.b ) )
					if ( col.r + col.g + col.b )/3 > 127 then
						draw.SimpleText( evolve.ranks[ v.Usergroup ].Title, "FontSub", rem(4.25 + 3), rem(3), Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
					else
						draw.SimpleText( evolve.ranks[ v.Usergroup ].Title, "FontSub", rem(4.25 + 3), rem(3), Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
					end

					// Stacks
					local stackSpace = rem(5)
					local stackCount = 0

					// Ping
					draw.SimpleText( v.Ping, "FontHeader", self.Window.PlayerPanel:GetWide() - stackSpace*( stackCount + 0.5 ) - rem(), rem(1.5), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					draw.SimpleText( "ping", "FontSub", self.Window.PlayerPanel:GetWide() - stackSpace*( stackCount + 0.5 ) - rem(), rem(2.5), ColourSub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					stackCount = stackCount + 1

					// Props
					draw.SimpleText( v.Propcount, "FontHeader", self.Window.PlayerPanel:GetWide() - stackSpace*( stackCount + 0.5 ) - rem(), rem(1.5), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					draw.SimpleText( (v.Propcount == 1 and "prop" or "props"), "FontSub", self.Window.PlayerPanel:GetWide() - stackSpace*( stackCount + 0.5 ) - rem(), rem(2.5), ColourSub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					stackCount = stackCount + 1

					// Deaths
					draw.SimpleText( v.Deaths, "FontHeader", self.Window.PlayerPanel:GetWide() - stackSpace*( stackCount + 0.5 ) - rem(), rem(1.5), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					draw.SimpleText( (v.Deaths == 1 and "death" or "deaths"), "FontSub", self.Window.PlayerPanel:GetWide() - stackSpace*( stackCount + 0.5 ) - rem(), rem(2.5), ColourSub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					stackCount = stackCount + 1

					// Frags
					draw.SimpleText( v.Frags, "FontHeader", self.Window.PlayerPanel:GetWide() - stackSpace*( stackCount + 0.5 ) - rem(), rem(1.5), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					draw.SimpleText( (v.Frags == 1 and "frag" or "frags"), "FontSub", self.Window.PlayerPanel:GetWide() - stackSpace*( stackCount + 0.5 ) - rem(), rem(2.5), ColourSub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					stackCount = stackCount + 1

					// PlayTime
					draw.SimpleText( self:FormatTime( v.PlayTime ), "FontHeader", self.Window.PlayerPanel:GetWide() - stackSpace*( stackCount + 0.5 ) - rem(), rem(1.5), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					draw.SimpleText( self:FormatTime( v.PlayTime, true ), "FontSub", self.Window.PlayerPanel:GetWide() - stackSpace*( stackCount + 0.5 ) - rem(), rem(2.5), ColourSub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					stackCount = stackCount + 1

				end

				spacing = spacing + self.Window.PlayerPanel:GetTall() + 2

				// Avatar
				self.Window.PlayerPanel.Avatar = vgui.Create("AvatarImage", self.Window.PlayerPanel)
				self.Window.PlayerPanel.Avatar:SetPos(rem(4), rem())
				self.Window.PlayerPanel.Avatar:SetSize(rem(2), rem(2))
				self.Window.PlayerPanel.Avatar:SetPlayer(v.Player, rem(2))
				self.Window.PlayerPanel.Avatar:SetCursor("hand")
				function self.Window.PlayerPanel.Avatar:DoClick() // OnMousePressed
					v.Player:ShowProfile()
				end

				// Mute Button
				self.Window.PlayerPanel.Mute = vgui.Create("DImageButton", self.Window.PlayerPanel)
				self.Window.PlayerPanel.Mute:SetPos(rem(), rem())
				self.Window.PlayerPanel.Mute:SetSize(rem(2), rem(2))

				if true then
					if v.Player:IsMuted() then
						self.Window.PlayerPanel.Mute:SetImage("icon32/muted.png");
					else
						self.Window.PlayerPanel.Mute:SetImage("icon32/unmuted.png");
					end

					self.Window.PlayerPanel.Mute.DoClick = function() v.Player:SetMuted(!v.Player:IsMuted()) end
				end

			end

		end*/

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
end