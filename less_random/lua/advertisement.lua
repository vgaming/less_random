-- << less_random/new_ad

local wesnoth = wesnoth
local tostring = tostring
local ipairs = ipairs

local addon_name = tostring((...).name)
local addon_dir = tostring((...).dir)
local filename = "~add-ons/" .. addon_dir .. "/target/version.txt"
local addon_about = tostring((...).about)
local addon_icon = tostring((...).icon)

local function human_ver()
	if wesnoth.have_file(filename) then
		return { v = wesnoth.read_file(filename) }
	else
		return { v = "0.0.0" }
	end
end

local function ai_ver()
	return { v = "0.0.0" }
end


local highest_version = "0.0.0"
for side_number in ipairs(wesnoth.sides) do
	local side_version = wesnoth.synchronize_choice(human_ver, ai_ver, side_number).v
	print("side", side_number, "ver", side_version)
	if wesnoth.compare_versions(side_version, ">", highest_version) then
		highest_version = side_version
	end
end

local my_version = human_ver().v

if my_version == highest_version then
	return
end

local advertisement
if my_version == "0.0.0" then
	advertisement = "This game uses " .. addon_name .. " add-on. "
		.. "\n"
		.. "If you'll like it, feel free to install it from add-ons server."
		.. "\n\n"
		.. "======================\n\n"
else
	advertisement = "🠉🠉🠉 Please upgrade your " .. addon_name .. " add-on 🠉🠉🠉"
		.. "\n"
		.. my_version .. " -> " .. highest_version
		.. "\n\n"
end

wesnoth.wml_actions.message {
	caption = addon_name,
	message = advertisement .. addon_about,
	image = addon_icon,
}


-- >>
