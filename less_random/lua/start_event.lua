-- << lessrandom.start_event

local wesnoth = wesnoth
local wml = wml
local T = wesnoth.require("lua/helper.lua").set_wml_tag_metatable {}


if wml.variables.lessrandom_multiplier == 1 then
	return
end

wesnoth.wml_actions.event {
	first_time_only = false,
	name = "side turn",
	T.lua { code = "lessrandom.side_turn_event()" }
}
wesnoth.wml_actions.event {
	first_time_only = false,
	name = "turn refresh",
	T.lua { code = "lessrandom.turn_refresh_event()" }
}
--wesnoth.wml_actions.event {
--	first_time_only = false,
--	name = "side turn end",
--	T.lua { code = "lessrandom.side_turn_end_event()" }
--}
wesnoth.wml_actions.event {
	first_time_only = false,
	name = "unit placed",
	T.lua { code = "lessrandom.unit_placed_event()" }
}


-- >>
