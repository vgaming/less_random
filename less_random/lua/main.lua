-- << main | less_random

lessrandom = {}
local lessrandom = lessrandom
local ipairs = ipairs
local math = math
local wesnoth = wesnoth
local wml = wml
local on_event = wesnoth.require("lua/on_event.lua")
local T = wml.tag

if wml.variables.lessrandom_multiplier == 1 then
	return
end

local function remove_object(unit)
	if not unit or not unit.id then return end
	unit.variables.lessrandom_init = nil
	local safe_unit_id = tostring(unit.id):gsub("-", "_"):gsub(" ", "_")
	local obj_id = "lessrandom_" .. safe_unit_id
	wesnoth.wml_actions.remove_object {
		object_id = obj_id,
		id = unit.id
	}
end

lessrandom.remove_object = remove_object

local function add_object(unit)
	if not unit or not unit.id or unit.id == "" then
		-- In 1.18, unit.id might not be available immediately after recruitment.
		-- Such units will be handled in turn_refresh
		return
	end

	-- Check if already initialized
	if unit.variables.lessrandom_init then
		return
	end

	-- Use unique object ID per unit
	-- Replace problematic characters (like dashes) that might cause "Invalid id=" error
	local safe_unit_id = tostring(unit.id):gsub("[^a-zA-Z0-9]", "_")
	local obj_id = "lessrandom_" .. safe_unit_id

	-- Mark as initialized BEFORE applying to prevent race conditions
	--
	-- Note: this comment was taken from Less Random Fork. The current maintainer of Less Random
	-- does not know what this means. Wesnoth's Lua context is single-threaded, after all.
	-- Let's keep it as-is since the add-on seems to be working.
	unit.variables.lessrandom_init = true

	-- Calculate percentage: if multiplier is 10, we want 900% increase (10x total)
	-- Formula: (multiplier - 1) * 100 = percentage increase
	local multiplier = wml.variables.lessrandom_multiplier or 3
	if type(multiplier) ~= "number" then
		multiplier = 3
	end
	local percent_increase = (multiplier - 1) * 100
	local percent_str = tostring(percent_increase) .. "%"

	-- Apply object using WML action
	-- Use coordinates instead of ID for filter - more reliable for newly recruited units
	-- Wrap in pcall to catch any errors
	local success, err = pcall(function()
		-- Try using coordinates first (more reliable for newly recruited units)
		if unit.x and unit.y then
			wesnoth.wml_actions.object {
				T.filter { x = unit.x, y = unit.y },
				id = obj_id,
				take_only_once = false,
				silent = true,
				duration = "forever",
				T.effect {
					apply_to = "hitpoints",
					increase_total = percent_str,
					increase = percent_str,
				},
				T.effect {
					apply_to = "attack",
					increase_attacks = percent_str,
				},
			}
		else
			-- Fallback to ID if coordinates not available
			wesnoth.wml_actions.object {
				T.filter { id = unit.id },
				id = obj_id,
				take_only_once = false,
				silent = true,
				duration = "forever",
				T.effect {
					apply_to = "hitpoints",
					increase_total = percent_str,
					increase = percent_str,
				},
				T.effect {
					apply_to = "attack",
					increase_attacks = percent_str,
				},
			}
		end
	end)

	if not success then
		local err_msg = "[less_random] add_object: ERROR applying object to unit " .. tostring(unit.id) .. ": " .. tostring(err)
		print(err_msg)
		wesnoth.log("error", err_msg)
		-- Reset init flag on error so we can try again
		unit.variables.lessrandom_init = nil
	end
end
lessrandom.add_object = add_object

local function initialize_all_units()
	-- Initialize all units on the map
	for _, unit in ipairs(wesnoth.units.find_on_map {}) do
		add_object(unit)
	end
end

local function start_initialize()
	initialize_all_units()
end

local function prestart_initialize()
	-- Initialize units before the game starts
	initialize_all_units()
end

local function side_turn_event()
	for _, unit in ipairs(wesnoth.units.find_on_map {}) do
		unit.variables.lessrandom_hp_before = unit.hitpoints
	end
end

local function turn_refresh_event()
	for _, unit in ipairs(wesnoth.units.find_on_map {}) do
		-- Apply healing multiplier
		local hp = unit.hitpoints
		local enforce_max = math.max(hp, unit.max_hitpoints)
		local heal_diff = hp - (unit.variables.lessrandom_hp_before or hp)
		local new_hp = hp + heal_diff * (wml.variables.lessrandom_multiplier - 1)
		unit.hitpoints = math.max(1, math.min(enforce_max, new_hp))

		-- Check/add object for units that need it (newly recruited/placed)
		-- This is a backup for units that weren't initialized in recruit/unit_placed events
		if unit.variables.lessrandom_needs_check then
			unit.variables.lessrandom_needs_check = nil
			-- Only reset init flag if object wasn't already applied
			-- Check if object exists by checking the init flag
			if not unit.variables.lessrandom_init then
				-- Try to apply object
				add_object(unit)
			end
		end
	end
end

local function new_turn_event()
	-- Don't check all units on new turn - this was causing duplicate applications
	-- Only check units that were marked as needing check
	-- The turn_refresh_event will handle healing multiplier logic
end

local function unit_placed_event(ctx)
	-- Try multiple ways to get the unit in 1.18 using new API
	-- NOTE: For recruited units, this fires BEFORE recruit_event, so we just mark them
	-- The recruit_event will handle the actual application
	local unit = nil
	if ctx.x1 and ctx.y1 then
		unit = wesnoth.units.get(ctx.x1, ctx.y1)
	end
	if not unit and ctx.x and ctx.y then
		unit = wesnoth.units.get(ctx.x, ctx.y)
	end
	if not unit and ctx.id then
		local units = wesnoth.units.find_on_map { id = ctx.id }
		if #units > 0 then
			unit = units[1]
		end
	end
	if unit then
		-- Mark for check on turn refresh - unit might not have ID yet
		-- But don't apply here - let recruit_event handle recruited units
		unit.variables.lessrandom_needs_check = true
	end
end

local function recruit_event(ctx)
	-- Handle recruited units - use new API and ensure unit is ready
	-- In 1.18, recruit event fires after unit is placed, but ID might not be ready yet
	local unit = nil

	-- Try to get unit by coordinates first (most reliable)
	if ctx.x1 and ctx.y1 then
		unit = wesnoth.units.get(ctx.x1, ctx.y1)
	end

	-- Fallback to other methods
	if not unit and ctx.x and ctx.y then
		unit = wesnoth.units.get(ctx.x, ctx.y)
	end

	if not unit and ctx.id then
		local units = wesnoth.units.find_on_map { id = ctx.id }
		if #units > 0 then
			unit = units[1]
		end
	end

	-- Mark unit for check on turn refresh (backup)
	if unit then
		-- Clear the needs_check flag since we're handling it here
		unit.variables.lessrandom_needs_check = nil
		-- Try to apply immediately if ID is available
		if unit.id and unit.id ~= "" then
			-- Reset init flag to ensure object is applied (in case unit_placed already set it)
			unit.variables.lessrandom_init = nil
			add_object(unit)
		else
			-- Mark for check in turn_refresh if ID is not available
			unit.variables.lessrandom_needs_check = true
		end
	end
end

local function prerecruit_event(ctx)
	-- Handle units before recruitment (for compatibility)
	-- Don't add object here, wait for recruit event
end


on_event("prestart", prestart_initialize)
on_event("start", start_initialize)
on_event("new turn", new_turn_event)
on_event("side turn", side_turn_event)
on_event("turn refresh", turn_refresh_event)
on_event("unit placed", unit_placed_event)
on_event("prerecruit", prerecruit_event)
on_event("recruit", recruit_event)

-- >>
