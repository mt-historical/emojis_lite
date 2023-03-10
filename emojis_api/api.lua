emojis_api = {}
emojis_api.emojis = {}

local emoji_sound_gain = tonumber(minetest.settings:get("emojis_lite_sound_gain")) or 1
local emoji_duration = tonumber(minetest.settings:get("emojis_lite_duration")) or 4
local emoji_size = tonumber(minetest.settings:get("emojis_lite_size")) or 6
local emoji_glow = minetest.settings:get_bool("emojis_lite_glow", false)

local total_emojis = 0
local emoji_formspec = ""
local emojis_per_row = 0
local emoji_light_level = 0

if emoji_glow then
    emoji_light_level = 14
end

emojis_api.register_emoji = function(name, image, sound)
    if emojis_api.emojis[name] == nil then
        emojis_api.emojis[name] = {image = image, sound = sound}
    else
        minetest.log("error", "[emojis_api] Emoji " .. emoji .. " is already defined!")
    end
end

local function build_emoji_list()
    local counter = 0
    local scale_factor = (4/emojis_per_row)*2
    local missing_rows = math.floor(((emojis_per_row * emojis_per_row) - total_emojis)/emojis_per_row)
    local ydisp = (scale_factor/2)*missing_rows
    for k,v in pairs(emojis_api.emojis) do
        local ypos = math.floor(counter/emojis_per_row)
        local xpos = counter % emojis_per_row
        emoji_formspec = emoji_formspec ..
            "image_button[" ..
            xpos*scale_factor ..
            "," ..
            (ypos*scale_factor)+0.4+ydisp ..
            ";" ..
            scale_factor ..
            "," ..
            scale_factor ..
            ";" ..
            v.image ..
            ";" ..
            k ..
            ";]"
        counter = counter + 1
    end
end

local function play_emoji(pos, emojidef)
    minetest.add_particle({
        pos = {x=pos.x, y=pos.y+2, z=pos.z},
        velocity = {x=0, y=0.5, z=0},
        expirationtime = emoji_duration,
        size = emoji_size,
        glow = emoji_light_level,
        texture = emojidef.image,
    })
    minetest.sound_play(emojidef.sound, {pos=pos, gain=emoji_sound_gain, max_hear_distance=2*64})
end

local function formspec_action(player, context, fields)
    local pos = player:get_pos()
    for k,_ in pairs(fields) do
        if k == "quit" then return end
        if not emojis_api.emojis[k] then return end
        play_emoji(pos, emojis_api.emojis[k])
        break
    end
end

local function process_emojis()
    for _,_ in pairs(emojis_api.emojis) do
        total_emojis = total_emojis + 1
    end
    emojis_per_row = math.ceil(math.sqrt(total_emojis))
    build_emoji_list()
end

minetest.register_on_mods_loaded(process_emojis)

minetest.register_chatcommand("emoji_board", {
    params = "[<emoji>]",
    description = "Open the emoji board or use <emoji>",
    func = function(pname, param)
        if param == "" or not param then
            minetest.show_formspec(pname, "emojis_api:emoji_board", "size[8,8.6]" .. emoji_formspec)
            return true
        else
            if not emojis_api.emojis[param] then return false, "Invalid emoji: " .. param end
            play_emoji(minetest.get_player_by_name(pname):get_pos(), emojis_api.emojis[param])
            return true
        end
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= ("emojis_api:emoji_board") then return end
    if not player then return end

    formspec_action(player, {}, fields)
end)

-- Optional
-----------

if sfinv then
    sfinv.register_page("emojis_api:emojis",
        {
            title = "Emojis",
            get = function(self, player, context)
                return sfinv.make_formspec(player, context, emoji_formspec, false)
            end,
            on_player_receive_fields = function(self, ...) formspec_action(...) end,
        }
    )
end
