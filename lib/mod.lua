local mod = require 'core/mods'
local script = require 'core/script'
local tabutil = require 'tabutil'

local state = {
  script_active = true
}

local function init_params()
  params:add_group("MOD - QREMOTE",8)

  params:add_option("qremote_active", "qremote active", {"on", "off"}, state.script_active and 1 or 2)
  params:set_action("qremote_active",
                    function(v)
                      state.script_active = v == 1 and true or false
  end)

  params:add{type = "number", id = "qremote_mchan", name = "Midi Chan", min = 1, max = 16, default = 10}
  params:add{type = "number", id = "qremote_enc1", name = "Enc1 CC", min = 1, max = 127, default = 58}
  params:add{type = "number", id = "qremote_enc2", name = "Enc2 CC", min = 1, max = 127, default = 62}
  params:add{type = "number", id = "qremote_enc3", name = "Enc3 CC", min = 1, max = 127, default = 63}

  params:add{type = "number", id = "qremote_but1", name = "But1 CC", min = 1, max = 127, default = 85}
  params:add{type = "number", id = "qremote_but2", name = "But2 CC", min = 1, max = 127, default = 87}
  params:add{type = "number", id = "qremote_but3", name = "But3 CC", min = 1, max = 127, default = 88}
end

local m = {}

local nornskey = norns.none

local nornsmidi_event
local function midi_event(id, data)
  -- print("Midi event", id, data)

  local consumed = false
  if state.script_active then

    if data[1] & 0xf0 then
      local mchan = params:get("qremote_mchan")

      local ch = data[1] - 0xb0 + 1

      if ch == mchan then
        local cc = data[2]
        local val = data[3]

        local enc1 = params:get("qremote_enc1")
        local enc2 = params:get("qremote_enc2")
        local enc3 = params:get("qremote_enc3")

        -- encoders
        if cc == enc1 then
          local delta = val > 64 and 1 or -1
          _norns.enc(1, delta)
          consumed = true
        elseif cc == enc2 then
          local delta = val > 64 and 1 or -1
          _norns.enc(2, delta)
          consumed = true
        elseif cc == enc3 then
          local delta = val > 64 and 1 or -1
          _norns.enc(3, delta)
          consumed = true
        end

        local but1 = params:get("qremote_but1")
        local but2 = params:get("qremote_but2")
        local but3 = params:get("qremote_but3")

        -- buttons
        if cc == but1 then
          local bstate = val > 0 and 1 or 0
          _norns.key(1, bstate)
          consumed = true
        elseif cc == but2 then
          local bstate = val > 0 and 1 or 0
          _norns.key(2, bstate)
          consumed = true
        elseif cc == but3 then
          local bstate = val > 0 and 1 or 0
          _norns.key(3, bstate)
          consumed = true
        end
      end
    end
  end

  if not consumed then
    nornsmidi_event(id, data)
  end
end

--
-- [optional] hooks are essentially callbacks which can be used by multiple mods
-- at the same time. each function registered with a hook must also include a
-- name. registering a new function with the name of an existing function will
-- replace the existing function. using descriptive names (which include the
-- name of the mod itself) can help debugging because the name of a callback
-- function will be printed out by matron (making it visible in maiden) before
-- the callback function is called.
--
-- here we have dummy functionality to help confirm things are getting called
-- and test out access to mod level state via mod supplied fuctions.
--

mod.hook.register("system_post_startup", "qremote-sys-post-startup", function()
  state.system_post_startup = true

  local script_clear = script.clear
  script.clear = function()

    local is_restart = (tabutil.count(params.lookup) == 0)

    script_clear()

    if is_restart then
      print("mod - qremote - clear at (re)start")
      init_params()
    else
      print("mod - qremote - clear at script stop / pre-start")
      init_params()
    end
  end

  -- plug into the midi event pipe
  nornsmidi_event = _norns.midi.event
  _norns.midi.event = midi_event
end)

mod.hook.register("script_pre_init", "my init hacks", function()
  -- tweak global environment here ahead of the script `init()` function being called
end)


m.key = function(n, z)
  print("Key " + n + " " + z)
  if n == 2 and z == 1 then
    -- return to the mod selection menu
    mod.menu.exit()
  end
end

m.enc = function(n, d)
  print("enc " + n + " " + d)
  if n == 2 then state.x = state.x + d
  elseif n == 3 then state.y = state.y + d end
  -- tell the menu system to redraw, which in turn calls the mod's menu redraw
  -- function
  mod.menu.redraw()
end

m.redraw = function()
  screen.clear()
  screen.move(64, 40)
  screen.text_center("QREMOTE")
  screen.update()
end

m.init = function() end -- on menu entry, ie, if you wanted to start timers
m.deinit = function() end -- on menu exit

-- register the mod menu
--
-- NOTE: `mod.this_name` is a convienence variable which will be set to the name
-- of the mod which is being loaded. in order for the menu to work it must be
-- registered with a name which matches the name of the mod in the dust folder.
--
mod.menu.register(mod.this_name, m)


--
-- [optional] returning a value from the module allows the mod to provide
-- library functionality to scripts via the normal lua `require` function.
--
-- NOTE: it is important for scripts to use `require` to load mod functionality
-- instead of the norns specific `include` function. using `require` ensures
-- that only one copy of the mod is loaded. if a script were to use `include`
-- new copies of the menu, hook functions, and state would be loaded replacing
-- the previous registered functions/menu each time a script was run.
--
-- here we provide a single function which allows a script to get the mod's
-- state table. using this in a script would look like:
--
-- local mod = require 'name_of_mod/lib/mod'
-- local the_state = mod.get_state()
--
local api = {}

api.get_state = function()
  return state
end

return api
