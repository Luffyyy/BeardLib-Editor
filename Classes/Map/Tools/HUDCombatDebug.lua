HUDCombatDebug = HUDCombatDebug or class()

function HUDCombatDebug:init()
    self._is_shown = false
end

function HUDCombatDebug:build_menu()
    local ws = managers.hud._saferect
	self._hud_panel = ws:panel()

	if self._hud_panel:child("combat_debug_panel") then
		self._hud_panel:remove(self._hud_panel:child("combat_debug_panel"))
	end

	self._combat_debug_panel = self._hud_panel:panel({
		halign = "center",
		name = "combat_debug_panel",
		h = 230,
		visible = false,
		w = 260,
		layer = 99,
		valign = "center"
	})

	self._combat_debug_panel:set_center(0.8888888888888888 * self._combat_debug_panel:parent():w() / 2, self._combat_debug_panel:parent():h() / 2)
	self._combat_debug_panel:set_right(self._combat_debug_panel:parent():w())

	local background = self._combat_debug_panel:rect({
		name = "combat_debug_bg",
		y = 0,
		x = 0,
		w = self._combat_debug_panel:w(),
		h = self._combat_debug_panel:h(),
		color = Color.black:with_alpha(0.7)
	})
	self._default_font_size = tweak_data.menu.pd2_tiny_font_size
	self._default_font = tweak_data.menu.pd2_tiny_font
	local game_intensity = self._combat_debug_panel:text({
		name = "combat_debug_intensity",
		vertical = "top",
		text = "Game intensity:",
		y = 8,
		align = "left",
		blend_mode = "normal",
		visible = true,
		x = 8,
		color = Color(0.937, 0.6, 0.2),
		font = self._default_font,
		font_size = self._default_font_size,
		layer = background:layer() + 1
	})
	local current_phase = self._combat_debug_panel:text({
		name = "combat_debug_phase",
		vertical = "top",
		text = "Current phase:",
		y = 30,
		align = "left",
		blend_mode = "normal",
		visible = true,
		x = 8,
		color = Color(0.937, 0.6, 0.2),
		font = self._default_font,
		font_size = self._default_font_size,
		layer = background:layer() + 1
	})
	local current_phase_duration = self._combat_debug_panel:text({
		name = "combat_debug_phase_duration",
		vertical = "top",
		text = "Current phase - time elapsed:",
		y = 52,
		align = "left",
		blend_mode = "normal",
		visible = true,
		x = 8,
		color = Color(0.937, 0.6, 0.2),
		font = self._default_font,
		font_size = self._default_font_size,
		layer = background:layer() + 1
	})
	local phase_number = self._combat_debug_panel:text({
		name = "combat_debug_phase_number",
		vertical = "top",
		text = "Wave number:",
		y = 74,
		align = "left",
		blend_mode = "normal",
		visible = true,
		x = 8,
		color = Color(0.2, 0.7529411764705882, 0.9372549019607843),
		font = self._default_font,
		font_size = self._default_font_size,
		layer = background:layer() + 1
	})
	local spawned_phase = self._combat_debug_panel:text({
		name = "combat_debug_phase_enemies_spawned",
		vertical = "top",
		text = "Enemies spawned (assault):",
		y = 96,
		align = "left",
		blend_mode = "normal",
		visible = true,
		x = 8,
		color = Color(0.3058823529411765, 0.6745098039215687, 0.23137254901960785),
		font = self._default_font,
		font_size = self._default_font_size,
		layer = background:layer() + 1
	})
	local killed_phase = self._combat_debug_panel:text({
		name = "combat_debug_phase_enemies_killed",
		vertical = "top",
		text = "Enemies killed (assault):",
		y = 118,
		align = "left",
		blend_mode = "normal",
		visible = true,
		x = 8,
		color = Color(0.2980392156862745, 0.796078431372549, 0.2823529411764706),
		font = self._default_font,
		font_size = self._default_font_size,
		layer = background:layer() + 1
	})
	local spawned_lifetime = self._combat_debug_panel:text({
		name = "combat_debug_lifetime_enemies_spawned",
		vertical = "top",
		text = "Enemies spawned (lifetime):",
		y = 140,
		align = "left",
		blend_mode = "normal",
		visible = true,
		x = 8,
		color = Color(0.7137254901960784, 0.2627450980392157, 0.7411764705882353),
		font = self._default_font,
		font_size = self._default_font_size,
		layer = background:layer() + 1
	})
	local killed_lifetime = self._combat_debug_panel:text({
		name = "combat_debug_lifetime_enemies_killed",
		vertical = "top",
		text = "Enemies killed (lifetime):",
		y = 162,
		align = "left",
		blend_mode = "normal",
		visible = true,
		x = 8,
		color = Color(0.8509803921568627, 0.3568627450980392, 0.8823529411764706),
		font = self._default_font,
		font_size = self._default_font_size,
		layer = background:layer() + 1
	})
	local enemies_alive = self._combat_debug_panel:text({
		name = "combat_debug_enemies_alive",
		vertical = "top",
		text = "Enemies alive:",
		y = 184,
		align = "left",
		blend_mode = "normal",
		visible = true,
		x = 8,
		color = Color(0.8823529411764706, 0.3568627450980392, 0.3568627450980392),
		font = self._default_font,
		font_size = self._default_font_size,
		layer = background:layer() + 1
	})
	local music_state = self._combat_debug_panel:text({
		name = "combat_debug_music_state",
		vertical = "top",
		text = "Music state:",
		y = 206,
		align = "left",
		blend_mode = "normal",
		visible = true,
		x = 8,
		color = Color(0.8823529411764706, 0.3568627450980392, 0.3568627450980392),
		font = self._default_font,
		font_size = self._default_font_size,
		layer = background:layer() + 1
	})
	self._game_intensity_val = self._combat_debug_panel:text({
		name = "combat_debug_intensity_val",
		vertical = "top",
		text = "",
		align = "right",
		blend_mode = "normal",
		visible = true,
		x = -10,
		color = Color(0.937, 0.6, 0.2),
		font = self._default_font,
		font_size = self._default_font_size,
		y = game_intensity:y(),
		layer = background:layer() + 1
	})
	self._current_phase_val = self._combat_debug_panel:text({
		name = "combat_debug_phase_val",
		vertical = "top",
		text = "reenforce",
		align = "right",
		blend_mode = "normal",
		visible = true,
		x = -10,
		color = Color(0.937, 0.6, 0.2),
		font = self._default_font,
		font_size = self._default_font_size,
		y = current_phase:y(),
		layer = background:layer() + 1
	})
	self._current_phase_duration_val = self._combat_debug_panel:text({
		name = "combat_debug_phase_duration_val",
		vertical = "top",
		text = "0",
		align = "right",
		blend_mode = "normal",
		visible = true,
		x = -10,
		color = Color(0.937, 0.6, 0.2),
		font = self._default_font,
		font_size = self._default_font_size,
		y = current_phase_duration:y(),
		layer = background:layer() + 1
	})
	self._current_phase_timer = 0
	self._phase_number_val = self._combat_debug_panel:text({
		name = "combat_debug_phase_number_val",
		vertical = "top",
		text = "0",
		align = "right",
		blend_mode = "normal",
		visible = true,
		x = -10,
		color = Color(0.2, 0.7529411764705882, 0.9372549019607843),
		font = self._default_font,
		font_size = self._default_font_size,
		y = phase_number:y(),
		layer = background:layer() + 1
	})
	self._spawned_phase_val = self._combat_debug_panel:text({
		name = "combat_debug_phase_enemies_spawned_val",
		vertical = "top",
		text = "0",
		align = "right",
		blend_mode = "normal",
		visible = true,
		x = -10,
		color = Color(0.3058823529411765, 0.6745098039215687, 0.23137254901960785),
		font = self._default_font,
		font_size = self._default_font_size,
		y = spawned_phase:y(),
		layer = background:layer() + 1
	})
	self._killed_phase_val = self._combat_debug_panel:text({
		name = "combat_debug_phase_enemies_killed_val",
		vertical = "top",
		text = "0",
		align = "right",
		blend_mode = "normal",
		visible = true,
		x = -10,
		color = Color(0.2980392156862745, 0.796078431372549, 0.2823529411764706),
		font = self._default_font,
		font_size = self._default_font_size,
		y = killed_phase:y(),
		layer = background:layer() + 1
	})
	self._spawned_lifetime_val = self._combat_debug_panel:text({
		name = "combat_debug_lifetime_enemies_spawned_val",
		vertical = "top",
		text = "0",
		align = "right",
		blend_mode = "normal",
		visible = true,
		x = -10,
		color = Color(0.7137254901960784, 0.2627450980392157, 0.7411764705882353),
		font = self._default_font,
		font_size = self._default_font_size,
		y = spawned_lifetime:y(),
		layer = background:layer() + 1
	})
	self._killed_lifetime_val = self._combat_debug_panel:text({
		name = "combat_debug_lifetime_enemies_killed_val",
		vertical = "top",
		text = "0",
		align = "right",
		blend_mode = "normal",
		visible = true,
		x = -10,
		color = Color(0.8509803921568627, 0.3568627450980392, 0.8823529411764706),
		font = self._default_font,
		font_size = self._default_font_size,
		y = killed_lifetime:y(),
		layer = background:layer() + 1
	})
	self._enemies_alive_val = self._combat_debug_panel:text({
		name = "combat_debug_enemies_alive_val",
		vertical = "top",
		text = "0",
		align = "right",
		blend_mode = "normal",
		visible = true,
		x = -10,
		color = Color(0.8823529411764706, 0.3568627450980392, 0.3568627450980392),
		font = self._default_font,
		font_size = self._default_font_size,
		y = enemies_alive:y(),
		layer = background:layer() + 1
	})
	self._music_state_val = self._combat_debug_panel:text({
		name = "combat_debug_music_state_val",
		vertical = "top",
		text = "none",
		align = "right",
		blend_mode = "normal",
		visible = true,
		x = -10,
		color = Color(0.8823529411764706, 0.3568627450980392, 0.3568627450980392),
		font = self._default_font,
		font_size = self._default_font_size,
		y = music_state:y(),
		layer = background:layer() + 1
	})
end

function HUDCombatDebug:update(t, dt)
    if not self._combat_debug_panel and managers.hud then
        self:build_menu()
    end

    self._current_phase_timer = self._current_phase_timer + dt

	if self._is_shown == false or not self._combat_debug_panel then
		return
	end

    local game_intensity = string.format("%.3f", tostring(managers.groupai:state()._difficulty_value))

	if self._game_intensity_val:text() ~= game_intensity then
		self._game_intensity_val:set_text(game_intensity)
		self._game_intensity_val:stop()
		self._game_intensity_val:animate(callback(self, self, "_animate_change"), Color(0.937, 0.6, 0.2))
	end

    local task_data = managers.groupai:state()._task_data
    local whisper_mode = managers.groupai:state():whisper_mode()

    local current_phase = whisper_mode and "sneak" or task_data.assault.phase or "control"

    if self._current_phase_val:text() ~= current_phase then
		self._current_phase_val:set_text(current_phase)
		self._current_phase_val:stop()
		self._current_phase_val:animate(callback(self, self, "_animate_change"), Color(0.937, 0.6, 0.2))
		self._current_phase_duration_val:stop()
		self._current_phase_duration_val:animate(callback(self, self, "_animate_change"), Color(0.937, 0.6, 0.2))

		self._current_phase_timer = 0
	end

    local curr_t = math.floor(self._current_phase_timer + 0.5)

	self._current_phase_duration_val:set_text(string.format("%.2d:%.2d:%.2d", curr_t / 3600, curr_t / 60 % 60, curr_t % 60))

    local phase_number = tostring(managers.groupai:state():get_assault_number())

	if self._phase_number_val:text() ~= phase_number then
		self._phase_number_val:set_text(phase_number)
		self._phase_number_val:stop()
		self._phase_number_val:animate(callback(self, self, "_animate_change"), Color(0.2, 0.7529411764705882, 0.9372549019607843))
	end

    local spawned_phase = tostring(managers.groupai:state():enemies_spawned_in_current_assault())

	if self._spawned_phase_val:text() ~= spawned_phase then
		self._spawned_phase_val:set_text(spawned_phase)
		self._spawned_phase_val:stop()
		self._spawned_phase_val:animate(callback(self, self, "_animate_change"), Color(0.3058823529411765, 0.6745098039215687, 0.23137254901960785))
	end

	local killed_phase = tostring(managers.groupai:state():enemies_killed_in_current_assault())

	if self._killed_phase_val:text() ~= killed_phase then
		self._killed_phase_val:set_text(killed_phase)
		self._killed_phase_val:stop()
		self._killed_phase_val:animate(callback(self, self, "_animate_change"), Color(0.2980392156862745, 0.796078431372549, 0.2823529411764706))
	end

	local spawned_lifetime = tostring(managers.groupai:state():enemies_spawned_lifetime())

	if self._spawned_lifetime_val:text() ~= spawned_lifetime then
		self._spawned_lifetime_val:set_text(spawned_lifetime)
		self._spawned_lifetime_val:stop()
		self._spawned_lifetime_val:animate(callback(self, self, "_animate_change"), Color(0.7137254901960784, 0.2627450980392157, 0.7411764705882353))
	end

	local kills_lifetime = tostring(managers.groupai:state():enemies_killed_lifetime())

	if self._killed_lifetime_val:text() ~= kills_lifetime then
		self._killed_lifetime_val:set_text(kills_lifetime)
		self._killed_lifetime_val:stop()
		self._killed_lifetime_val:animate(callback(self, self, "_animate_change"), Color(0.8509803921568627, 0.3568627450980392, 0.8823529411764706))
	end

	local enemies_alive = tostring(managers.groupai:state():enemies_in_level())

	if self._enemies_alive_val:text() ~= enemies_alive then
		self._enemies_alive_val:set_text(enemies_alive)
		self._enemies_alive_val:stop()
		self._enemies_alive_val:animate(callback(self, self, "_animate_change"), Color(0.8823529411764706, 0.3568627450980392, 0.3568627450980392))
	end

    local music_state = Global.music_manager.current_event or "none"
    music_state = music_state:gsub("music_heist_", "")
    if self._music_state_val:text() ~= music_state then
        self._music_state_val:set_text(tostring(music_state))
        self._music_state_val:stop()
        self._music_state_val:animate(callback(self, self, "_animate_change"), Color(0.8823529411764706, 0.3568627450980392, 0.3568627450980392))
    end
end

function HUDCombatDebug:set_enabled(enabled)
    self._combat_debug_panel:set_visible(enabled)
    self._is_shown = enabled
end

function HUDCombatDebug:clean_up()
    if self._combat_debug_panel then
	    self._combat_debug_panel:parent():remove(self._combat_debug_panel)
    end
end

function HUDCombatDebug:_animate_change(text, final_color)
	local starting_color = Color.red
	local curr_color = starting_color
	local t = 0

	text:set_x(-30)

	while t < 0.5 do
		local dt = coroutine.yield()
		t = t + dt

		text:set_x(self:_ease_in_quart(t, -30, 20, 0.5))

		local new_r = self:_ease_in_quart(t, starting_color.r, final_color.r, 0.5)
		local new_g = self:_ease_in_quart(t, starting_color.g, final_color.g, 0.5)
		local new_b = self:_ease_in_quart(t, starting_color.b, final_color.b, 0.5)

		text:set_color(Color(new_r, new_g, new_b))
	end

	text:set_x(-10)
	text:set_color(final_color)
end

function HUDCombatDebug:_ease_in_quart(t, starting_value, change, duration)
	t = t / duration

	return change * t * t * t * t + starting_value
end