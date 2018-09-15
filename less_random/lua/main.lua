-- << lessrandom/main.lua

lessrandom = {}
local lessrandom = lessrandom
local ipairs = ipairs
local math = math
local wesnoth = wesnoth
local wml = wml
local on_event = wesnoth.require("lua/on_event.lua")
local T = wesnoth.require("lua/helper.lua").set_wml_tag_metatable {}

if wml.variables.lessrandom_multiplier == 1 then
	return
end

local function remove_object(unit)
	unit.variables.lessrandom_init = nil
	wesnoth.wml_actions.remove_object {
		object_id = "lessrandom",
		id = unit.id
	}
end

lessrandom.remove_object = remove_object

local function add_object(unit)
	if unit.variables.lessrandom_init then return end
	unit.variables.lessrandom_init = true
	wesnoth.wml_actions.object {
		T.filter { id = unit.id },
		id = "lessrandom",
		take_only_once = false,
		T.effect {
			apply_to = "hitpoints",
			increase_total = (wml.variables.lessrandom_multiplier - 1) .. "00%",
			increase = (wml.variables.lessrandom_multiplier - 1) .. "00%",
		},
		T.effect {
			apply_to = "attack",
			increase_attacks = (wml.variables.lessrandom_multiplier - 1) .. "00%",
		},
	}
end
lessrandom.add_object = add_object

local function start_initialize()
	for _, unit in ipairs(wesnoth.get_units {}) do
		add_object(unit)
	end
end

local function side_turn_event()
	for _, unit in ipairs(wesnoth.get_units {}) do
		unit.variables.lessrandom_hp_before = unit.hitpoints
	end
end

local function turn_refresh_event()
	for _, unit in ipairs(wesnoth.get_units {}) do
		local hp = unit.hitpoints
		local enforce_max = math.max(hp, unit.max_hitpoints)
		local heal_diff = hp - (unit.variables.lessrandom_hp_before or hp)
		local new_hp = hp + heal_diff * wml.variables.lessrandom_multiplier
		unit.hitpoints = math.max(1, math.min(enforce_max, new_hp))
		add_object(unit)
	end
end

local function unit_placed_event(ctx)
	local unit = wesnoth.get_unit(ctx.x1, ctx.y1)
	-- print_as_json("executing new unit event", unit and unit.id, wml.variables.x1, ctx)
	if unit then
		add_object(unit)
	end
end


on_event("start", start_initialize)
on_event("side turn", side_turn_event)
on_event("turn refresh", turn_refresh_event)
on_event("unit placed", unit_placed_event)
on_event("recruit", unit_placed_event)

-- >>
