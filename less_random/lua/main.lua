-- << lessrandom/main.lua

lessrandom = {}
local lessrandom = lessrandom
local ipairs = ipairs
local wesnoth = wesnoth
local wml = wml
local on_event = wesnoth.require("lua/on_event.lua")
local T = wesnoth.require("lua/helper.lua").set_wml_tag_metatable {}

if wml.variables.lessrandom_multiplier == 1 then
	return
end

local function remove_object(unit)
	wesnoth.wml_actions.remove_object {
		object_id = "lessrandom_hp",
		id = unit.id
	}
	if unit.variables.lessrandom_is_boosted then
		unit.variables.lessrandom_is_boosted = nil
		unit.variables.lessrandom_hp_was = unit.hitpoints
		unit.hitpoints = unit.hitpoints / wml.variables.lessrandom_multiplier
		unit.variables.lessrandom_reduced = unit.hitpoints
	end
end
lessrandom.remove_object = remove_object

local function add_object(unit)
	remove_object(unit)
	-- print("adding object to", unit.id)

	local hitpoints_after_turn_effects = unit.hitpoints
	wesnoth.wml_actions.object {
		T.filter {id = unit.id},
		id = "lessrandom_hp",
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
	if unit.variables.lessrandom_hp_was then
		unit.hitpoints = unit.variables.lessrandom_hp_was
			+ (hitpoints_after_turn_effects - unit.variables.lessrandom_reduced)
			* wml.variables.lessrandom_multiplier
		unit.variables.lessrandom_hp_was = nil
	end
	unit.variables.lessrandom_is_boosted = true
end
lessrandom.add_object = add_object

local function start_initialize()
	for _, unit in ipairs(wesnoth.get_units {}) do
		add_object(unit)
	end
end

local function side_turn_event()
	for _, unit in ipairs(wesnoth.get_units {}) do
		remove_object(unit)
	end
end

local function turn_refresh_event()
	for _, unit in ipairs(wesnoth.get_units {}) do
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
