-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- local menubar = require("menubar")

local temp_info = require("obvious.temp_info")
local fainty    = require("fainty")

require("lib.util")
require("lib.summon")
require("lib.core_ext")

local spawn  = awful.spawn
local summon = lib.summon.summon
local util   = lib.util

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
terminal = "urxvt"
home     = os.getenv("HOME")
modkey   = "Mod1"

global_keys = {}
local_keys  = {}

-- Themes define colours, icons, font and wallpapers.
beautiful.init(home .. "/.config/awesome/theme.lua")

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    -- awful.layout.suit.floating,
    -- awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}


-- Audio widgets
pulsewidget_out = fainty.widgets.pulseaudio({
  settings = {
    notify_errors = false,
    menu_theme = {
      width = beautiful.menu_width,
      height = beautiful.menu_height,
    }
  },

  channel_list = {
    {
      icon = "♪", channel_type = 'sink', label = "Speakers",
      name = "alsa_output.pci-0000_00_1f.3.analog-stereo"
    },
    {
      icon = "☊", channel_type = 'sink', label = "Canyon BT Speaker",
      name = "bluez_sink.25_59_BA_1C_4A_B2.a2dp_sink"
    },
    {
      icon = "☊", channel_type = 'sink', label = "TaoTronics Headset",
      name = "bluez_sink.00_00_00_00_1D_32.a2dp_sink"
    },
  }
})

pulsewidget_in = fainty.widgets.pulseaudio({
  settings = {
    notify_errors = false,
    format = " %s ",
    menu_theme = {
      width = beautiful.menu_width,
      height = beautiful.menu_height,
    }
  },

  channel_list = {
    {
      icon = "m", channel_type = 'source', label = "Built-in Microphone",
      name = "alsa_input.pci-0000_00_1f.3.analog-stereo"
    },
    {
      icon = "M", channel_type = 'source', label = "USB Microphone",
      name = "alsa_input.usb-0d8c_C-Media_USB_Headphone_Set-00.mono-fallback"
    },
  },
})

-- Battery widget
battery = fainty.widgets.battery({})

-- Keyboard layout widget
keyboard_layout = wibox.widget.textbox(" EN ")

dbus.request_name("session", "ru.gentoo.kbdd")
dbus.add_match("session", "interface='ru.gentoo.kbdd',member='layoutChanged'")
dbus.connect_signal("ru.gentoo.kbdd", function(...)
  local data = {...}
  local layout = data[2]
  lts = { [0] = " EN ", [1] = " BG " }
  keyboard_layout:set_text(lts[layout])
end)


-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
  awful.button({ }, 1, function(t) t:view_only() end),
  awful.button({ modkey }, 1, function(t)
    if client.focus then
      client.focus:move_to_tag(t)
    end
  end),
  awful.button({ }, 3, awful.tag.viewtoggle),
  awful.button({ modkey }, 3, function(t)
    if client.focus then
      client.focus:toggle_tag(t)
    end
  end),
  awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
  awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
  awful.button({ }, 1, function (c)
    if c == client.focus then
      c.minimized = true
    else
      c:emit_signal(
        "request::activate",
        "tasklist",
        {raise = true}
      )
    end
  end),
  awful.button({ }, 3, function()
    awful.menu.client_list({ theme = { width = 250 } })
  end),
  awful.button({ }, 4, function ()
    awful.client.focus.byidx(1)
  end),
  awful.button({ }, 5, function ()
    awful.client.focus.byidx(-1)
  end)
)

-- local function set_wallpaper(s)
--   -- Wallpaper
--   if beautiful.wallpaper then
--     local wallpaper = beautiful.wallpaper
--     -- If wallpaper is a function, call it with the screen
--     if type(wallpaper) == "function" then
--       wallpaper = wallpaper(s)
--     end
--     gears.wallpaper.maximized(wallpaper, s, true)
--   end
-- end
--
-- -- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
-- screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
  -- Wallpaper
  -- set_wallpaper(s)

  -- Each screen has its own tag table.
  awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

  -- Create an imagebox widget which will contain an icon indicating which layout we're using.
  -- We need one layoutbox per screen.
  s.layout_box = awful.widget.layoutbox(s)
  s.layout_box:buttons(gears.table.join(
    awful.button({ }, 1, function () awful.layout.inc( 1) end),
    awful.button({ }, 3, function () awful.layout.inc(-1) end),
    awful.button({ }, 4, function () awful.layout.inc( 1) end),
    awful.button({ }, 5, function () awful.layout.inc(-1) end)
  ))

  -- Create a taglist widget
  s.taglist = awful.widget.taglist {
    screen  = s,
    filter  = awful.widget.taglist.filter.all,
    buttons = taglist_buttons
  }

  -- Create a tasklist widget
  s.tasklist = awful.widget.tasklist {
    screen  = s,
    filter  = awful.widget.tasklist.filter.currenttags,
    buttons = tasklist_buttons
  }

  -- Create the wibox
  s.wibox = awful.wibar({ position = "top", screen = s })

  -- Create a generic separator
  s.separator = wibox.widget.textbox(util.colorize("#ee1111", " :: "))

  -- Add widgets to the wibox
  s.wibox:setup {
    layout = wibox.layout.align.horizontal,
    {
      -- Left widgets
      layout = wibox.layout.fixed.horizontal,
      s.taglist,
      pulsewidget_out,
      pulsewidget_in,
    },
    -- Middle widget
    s.tasklist,
    {
      -- Right widgets
      layout = wibox.layout.fixed.horizontal,
      s.separator,
      wibox.widget.systray(),
      s.separator,
      keyboard_layout,
      s.separator,
      battery,
      s.separator,
      temp_info(),
      s.separator,
      wibox.widget.textclock(),
      s.layout_box,
    },
  }
end)
-- }}}

-- Key bindings
function translate_modifiers(modifiers)
  local result = {}

  for i, mod in pairs(modifiers) do
    if mod == 'M' then
      table.insert(result, modkey)
    elseif mod == 'S' then
      table.insert(result, "Shift")
    elseif mod == 'C' then
      table.insert(result, "Control")
    end
  end

  return result
end

-- TODO: unmap_global
function map_global(key_description, action)
  local key_definition = key_description:split('-')
  local key            = table.remove(key_definition)
  local modifiers      = translate_modifiers(key_definition)

  key_definition = awful.key(modifiers, key, action)
  global_keys    = awful.util.table.join(global_keys, key_definition)
  -- root.keys(global_keys)
end

-- Disabled for now, not really used:
--map_global("M-Left",   awful.tag.viewprev)
--map_global("M-Right",  awful.tag.viewnext)
--map_global("M-Escape", awful.tag.history.restore)

map_global("M-j", function ()
  awful.client.focus.byidx(1)

  if client.focus then
    client.focus:raise()
  end
end)
map_global("M-k", function ()
  awful.client.focus.byidx(-1)

  if client.focus then
    client.focus:raise()
  end
end)
map_global("M-Tab", function ()
  awful.client.focus.history.previous()

  if client.focus then
    client.focus:raise()
  end
end)

map_global("M-S-j", function () awful.client.swap.byidx(1) end)
map_global("M-S-k", function () awful.client.swap.byidx(-1) end)

map_global("M-u", awful.client.urgent.jumpto)

map_global("M-S-p", util.spawner("mpc toggle"))
map_global("M-S-.", util.spawner("mpc next"))
map_global("M-S-,", util.spawner("mpc prev"))

-- Screenkey
screenkey_started = 0
screenkey_callback = function ()
  if screenkey_started == 0 then
    screenkey_started = 1
    spawn("screenkey")
  else
    screenkey_started = 0
    spawn("killall screenkey")
  end
end
map_global("M-F11", screenkey_callback)

-- Applications
map_global("M-Return", util.spawner(terminal))
map_global("M-S-f", function () summon("firefox", { class = "firefox" }) end)
map_global("M-S-w", util.spawner("bin/websearch-prompt 'http://en.wikipedia.org/wiki/{0}'"))
map_global("M-S-y", util.spawner("bin/websearch-prompt 'http://youtube.com/results?search_query={0}'"))
map_global("M-S-t", util.spawner("bash -c 'PATH=$PATH:/home/andrew/bin thunar'"))
map_global("M-S-m", util.spawner("firefox gmail.com"))

global_keys = awful.util.table.join(
  global_keys,

  awful.key({ modkey, "Shift"   }, "q",      awesome.restart),

  awful.key({ modkey, },           "l",     function () awful.tag.incmwfact( 0.05)    end),
  awful.key({ modkey, },           "h",     function () awful.tag.incmwfact(-0.05)    end),
  awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
  awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
  awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
  awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
  awful.key({ modkey, },           "space", function () awful.layout.inc(1) end),
  awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1) end),

  -- sound & brightness
  awful.key({ modkey }, "F1", function () pulsewidget_out:toggle() end),
  awful.key({ modkey }, "F2", function () pulsewidget_out:lower(5) end),
  awful.key({ modkey }, "F3", function () pulsewidget_out:raise(5) end),
  awful.key({ modkey }, "F4", function () pulsewidget_in:toggle() end),

  awful.key({ modkey }, "F5", function () spawn("xbacklight -dec 2") end ),
  awful.key({ modkey }, "F6", function () spawn("xbacklight -inc 2") end ),

  -- prompt
  awful.key({ modkey }, "p", function () spawn("bash -c 'PATH=$PATH:/home/andrew/bin gmrun'") end),

  -- keyboard backlight
  awful.key({ modkey }, "F9", function () spawn("bash -c 'PATH=$PATH:/home/andrew/bin keyboard-light-toggle'") end),

  -- keyboard backlight
  awful.key({ modkey }, "F10", function () spawn("bash -c 'PATH=$PATH:/home/andrew/bin sound-toggle'") end),

  -- pixel-grabbing
  awful.key({ modkey }, "F12", function () spawn("bash -c 'PATH=$PATH:/home/andrew/.cargo/bin xcolor | tr -d \"\n\" | xclip -i'") end),

  -- copy X selection to clipboard
  awful.key({ modkey, "Shift" }, "=", function () spawn("bin/copy-to-clipboard") end),
  awful.key({ modkey, "Shift" }, "-", function () spawn("bin/copy-from-clipboard") end),

  -- screengrabbing
  awful.key({ modkey }, "Print", function () spawn("scrot -e 'mv $f /home/andrew/images/shots/'") end)
)

client_keys = awful.util.table.join(
  awful.key({ modkey, }, "f", function (c)
    c.fullscreen = not c.fullscreen
    c:raise()
  end,
  {description = "toggle fullscreen", group = "client"}),
  -- TODO consider adding descriptions everywhere, and that help window
  awful.key({ modkey, },           "q",      function (c) c:kill()                         end),
  awful.key({ modkey, },           "t",      awful.client.floating.toggle                     ),
  awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
  awful.key({ modkey, },           "o",      awful.client.movetoscreen                        ),
  awful.key({ modkey, "Shift" },   "r",      function (c) c:redraw()                       end),
  awful.key({ modkey, },           "n",      function (c) c.minimized = not c.minimized    end),
  awful.key({ modkey, },           "m",      function (c)
    c.maximized_horizontal = not c.maximized_horizontal
    c.maximized_vertical   = not c.maximized_vertical
  end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
  global_keys = gears.table.join(global_keys,
  -- View tag only.
  awful.key({ modkey }, "#" .. i + 9,
  function ()
    local screen = awful.screen.focused()
    local tag = screen.tags[i]
    if tag then
      tag:view_only()
    end
  end,
  {description = "view tag #"..i, group = "tag"}),
  -- Toggle tag display.
  awful.key({ modkey, "Control" }, "#" .. i + 9,
  function ()
    local screen = awful.screen.focused()
    local tag = screen.tags[i]
    if tag then
      awful.tag.viewtoggle(tag)
    end
  end,
  {description = "toggle tag #" .. i, group = "tag"}),
  -- Move client to tag.
  awful.key({ modkey, "Shift" }, "#" .. i + 9,
  function ()
    if client.focus then
      local tag = client.focus.screen.tags[i]
      if tag then
        client.focus:move_to_tag(tag)
      end
    end
  end,
  {description = "move focused client to tag #"..i, group = "tag"}),
  -- Toggle tag on focused client.
  awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
  function ()
    if client.focus then
      local tag = client.focus.screen.tags[i]
      if tag then
        client.focus:toggle_tag(tag)
      end
    end
  end,
  {description = "toggle focused client on tag #" .. i, group = "tag"})
)
end

client_buttons = gears.table.join(
  awful.button({ }, 1, function (c)
    c:emit_signal("request::activate", "mouse_click", {raise = true})
  end),
  awful.button({ modkey }, 1, function (c)
    c:emit_signal("request::activate", "mouse_click", {raise = true})
    awful.mouse.client.move(c)
  end),
  awful.button({ modkey }, 3, function (c)
    c:emit_signal("request::activate", "mouse_click", {raise = true})
    awful.mouse.client.resize(c)
  end)
)

root.keys(global_keys)

-- Rules
awful.rules.rules = {
  -- All clients will match this rule.
  {
    rule       = { },
    properties = {
      border_width     = beautiful.border_width,
      border_color     = beautiful.border_normal,
      focus            = awful.client.focus.filter,
      size_hints_honor = false,
      raise            = true,
      keys             = client_keys,
      buttons          = client_buttons,
      screen           = awful.screen.preferred,
      placement        = awful.placement.no_overlap+awful.placement.no_offscreen
    }
  },

  -- Floating clients.
  {
    rule_any = {
      instance = {
        "pinentry",
      },
      class = {
        "MPlayer",
        "gimp",
        "Arandr",
        "Blueman-manager",
        "Blueberry.py",
      },

      -- Note that the name property shown in xprop might be set slightly after creation of the client
      -- and the name shown there might not match defined rules here.
      name = {
        "screenkey",
        "Event Tester",  -- xev.
      },
      role = {
        "pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
      }
    },
    properties = { floating = true }
  },

  -- Add titlebars to normal clients and dialogs
  -- {
  --   rule_any   = { type = { "normal", "dialog" } },
  --   properties = { titlebars_enabled = true }
  -- },
  {
    rule       = { class = "Skype" },
    properties = { tag = "9" }
  },
  {
    rule       = { class = "Pidgin" },
    properties = { tag = "8" }
  },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
  -- Set the windows at the slave,
  -- i.e. put it at the end of others instead of setting it master.
  -- if not awesome.startup then awful.client.setslave(c) end

  if awesome.startup
    and not c.size_hints.user_position
    and not c.size_hints.program_position then
    -- Prevent clients from being unreachable after screen count changes.
    awful.placement.no_offscreen(c)
  end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
  -- buttons for the titlebar
  local buttons = gears.table.join(
    awful.button({ }, 1, function()
      c:emit_signal("request::activate", "titlebar", {raise = true})
      awful.mouse.client.move(c)
    end),
    awful.button({ }, 3, function()
      c:emit_signal("request::activate", "titlebar", {raise = true})
      awful.mouse.client.resize(c)
    end)
  )

  awful.titlebar(c) : setup {
    {
      -- Left
      awful.titlebar.widget.iconwidget(c),
      buttons = buttons,
      layout  = wibox.layout.fixed.horizontal
    },
    {
      -- Middle
      {
        -- Title
        align  = "center",
        widget = awful.titlebar.widget.titlewidget(c)
      },
      buttons = buttons,
      layout  = wibox.layout.flex.horizontal
    },
    {
      -- Right
      awful.titlebar.widget.floatingbutton (c),
      awful.titlebar.widget.maximizedbutton(c),
      awful.titlebar.widget.stickybutton   (c),
      awful.titlebar.widget.ontopbutton    (c),
      awful.titlebar.widget.closebutton    (c),
      layout = wibox.layout.fixed.horizontal()
    },
    layout = wibox.layout.align.horizontal
  }
end)

-- -- Enable sloppy focus, so that focus follows mouse.
-- client.connect_signal("mouse::enter", function(c)
--   c:emit_signal("request::activate", "mouse_enter", {raise = false})
-- end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
