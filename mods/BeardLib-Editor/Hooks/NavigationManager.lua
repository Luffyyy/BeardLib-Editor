if not Global.editor_mode then
	return
end

local mvec3_cpy = mvector3.copy
function NavigationManager:init()
	self._debug = SystemInfo:platform() == Idstring("WIN32")
	self._builder = NavFieldBuilder:new()
	self._get_room_height_at_pos = self._builder._get_room_height_at_pos
	self._check_room_overlap_bool = self._builder._check_room_overlap_bool
	self._door_access_types = self._builder._door_access_types
	self._opposite_side_str = self._builder._opposite_side_str
	self._perp_pos_dir_str_map = self._builder._perp_pos_dir_str_map
	self._perp_neg_dir_str_map = self._builder._perp_neg_dir_str_map
	self._dim_str_map = self._builder._dim_str_map
	self._perp_dim_str_map = self._builder._perp_dim_str_map
	self._neg_dir_str_map = self._builder._neg_dir_str_map
	self._x_dir_str_map = self._builder._x_dir_str_map
	self._dir_str_to_vec = self._builder._dir_str_to_vec
	self._geog_segment_size = self._builder._geog_segment_size
	self._grid_size = self._builder._grid_size
	self._rooms = {}
	self._room_doors = {}
	self._geog_segments = {}
	self._nr_geog_segments = nil
	self._visibility_groups = {}
	self._nav_segments = {}
	self._coarse_searches = {}
	self:set_debug_draw_state(true)
	self._covers = {}
	self._next_pos_rsrv_expiry = false
	if self._debug then
		self._nav_links = {}
	end
	self._quad_field = World:quad_field()
	self._quad_field:set_nav_link_filter(NavigationManager.ACCESS_FLAGS)
	self._pos_rsrv_filters = {}
	self._obstacles = {}
	if self._debug then
		self._pos_reservations = {}
	end
end

function NavigationManager:update(t, dt)
	if self._debug then
		self._builder:update(t, dt)
		if self._draw_enabled then
			local options = self._draw_enabled
			local data = self._draw_data
			if data and type(options) == "table" then
				local progress = math.clamp((t - data.start_t) / (data.duration * 0.5), 0, 1)
                if options.quads then
                    self:_draw_rooms(progress)
                end
                if options.doors then
                    self:_draw_doors(progress)
                end
                if options.blockers then
                    --self:_draw_nav_blockers() Some crashing issues with this
                end
                if options.vis_graph then
                    self:_draw_visibility_groups(progress)
                end
                if options.coarse_graph then
                    self:_draw_coarse_graph()
                end
                if options.nav_links then
                    self:_draw_anim_nav_links()
                end
                if options.covers then
                    self:_draw_covers()
                end
				if progress == 1 then
					self._draw_data.start_t = t
				end
			end
		end
	end
	self:_commence_coarce_searches(t)
end

function NavigationManager:set_debug_draw_state(options)
    local temp = {}
    if type(options) == "table" then
        for k, option in pairs(options) do
            if type(option) == "table" then
                temp[k] = option.value
            end
        end 
        options = temp
    end
    if options and not self._draw_enabled then
        self:_init_draw_data()
        self._draw_data.start_t = TimerManager:game():time()
    end
    self._draw_enabled = options
end

function NavigationManager:build_complete_clbk(draw_options)
	self:_refresh_data_from_builder()
	self:set_debug_draw_state(draw_options)
	if self:is_data_ready() then
		self._load_data = self:get_save_data()
        local c = BeardLibEditor.Utils:GetPart("opt")
        BeardLibEditor:log("Navigation data Progress: Done!")
        BeardLibEditor.Utils:QuickDialog({message = "Done building navigation data do you wish to save it?"}, {{"Yes", callback(c, c, "save_nav_data")}})
    end
	if self._build_complete_clbk then
		self._build_complete_clbk()
	end
	BLE.Utils:GetPart("opt"):reenable_disabled_units()
end

local search = NavigationManager.search_coarse
function NavigationManager:search_coarse( ... )
    if self._builder._building then
        return
    end
    return search(self, ...)
end

function NavigationManager:_safe_remove_unit(unit) end
function NavigationManager:remove_AI_blocker_units() end