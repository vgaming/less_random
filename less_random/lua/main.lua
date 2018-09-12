-- << lessrandom/main.lua

lessrandom = {}
local lessrandom = lessrandom
local ipairs = ipairs
local wesnoth = wesnoth
local wml = wml
local T = wesnoth.require("lua/helper.lua").set_wml_tag_metatable {}


local function add_object(unit)
	wesnoth.add_modification(unit, "object", {
		id = "lessrandom_hp",
		T.effect {
			apply_to = "hitpoints",
			increase_total = (wml.variables.lessrandom_multiplier - 1) .. "00%",
			increase = (wml.variables.lessrandom_multiplier - 1) .. "00%",
		},
		T.effect {
			apply_to = "attack",
			increase_attacks = (wml.variables.lessrandom_multiplier - 1) .. "00%",
		},
	})
	unit.variables.lessrandom = true
end

function lessrandom.side_turn_event()
	for _, unit in ipairs(wesnoth.get_units { side = wesnoth.current.side }) do
		wesnoth.remove_modifications(unit, { id = "lessrandom_hp" })
		if (unit.variables.lessrandom) then
			unit.hitpoints = unit.hitpoints / wml.variables.lessrandom_multiplier
			unit.variables.lessrandom = false
		end
	end
end

function lessrandom.turn_refresh_event()
	for _, unit in ipairs(wesnoth.get_units { side = wesnoth.current.side }) do
		add_object(unit)
	end
end

function lessrandom.unit_placed_event()
	local unit = wesnoth.get_unit(wml.variables.x1, wml.variables.y1  )
	add_object(unit)
end


-- >>
