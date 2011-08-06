-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- Obvious widgets
require("obvious.volume_alsa")
require("obvious.basic_mpd")
require("obvious.battery")
require("obvious.temp_info")

-- Vicious widgets
require("vicious")

require ("lib.summon")
local summon = lib.summon.summon

-- Variable definitions
local spawn      = awful.util.spawn

local terminal   = "urxvt"
local modkey     = "Mod1"

local home       = os.getenv("HOME")
local editor     = os.getenv("EDITOR") or "vim"

local editor_cmd = terminal .. " -e " .. editor

-- Initialize theme
beautiful.init(home .. "/.config/awesome/theme.lua")

-- Layout table
layouts = {
  awful.layout.suit.tile.bottom,
  awful.layout.suit.max,
}

-- Tags/workspaces
tags = {}
for s = 1, screen.count() do
  tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end

-- Menus
awesome_menu = {
  { "manual",      terminal .. " -e man awesome" },
  { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
  { "restart",     awesome.restart },
  { "quit",        awesome.quit }
}

main_menu = awful.menu({
  items = {
    { "awesome",       awesome_menu, beautiful.awesome_icon },
    { "open terminal", terminal }
  }
})

launcher = awful.widget.launcher({
  image = image(beautiful.awesome_icon),
  menu  = main_menu
})

function colorize(color, string)
  return '<span color="'..color..'">'..string..'</span>'
end

-- Textclock widget
text_clock = awful.widget.textclock({ align = "right" })

-- MPD widget
mpd = widget { type = "textbox" }
vicious.register(mpd, vicious.widgets.mpd, function(w, args)
  state = args['{state}']

  if state == "Stop" then
    return colorize('#009000', '--')
  else
    if state == "Pause" then
      state_string = colorize('#009000', '||')
    else
      state_string = colorize('#009000', '>')
    end

    return "Playing: "..args['{Title}'].." "..state_string
  end
end)

-- Separator
separator = widget { type = "textbox" }
separator.text = '<span color="#ee1111"> :: </span>'

-- Create a systray
systray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
wibox = {}
prompt_box = {}
layout_box = {}
taglist = {}
taglist.buttons = awful.util.table.join(
  awful.button({ },        1, awful.tag.viewonly),
  awful.button({ modkey }, 1, awful.client.movetotag),
  awful.button({ },        3, awful.tag.viewtoggle),
  awful.button({ modkey }, 3, awful.client.toggletag),
  awful.button({ },        4, awful.tag.viewnext),
  awful.button({ },        5, awful.tag.viewprev)
)

tasklist = {}
tasklist.buttons = awful.util.table.join(
  awful.button({ }, 1, function (c)
    if not c:isvisible() then
      awful.tag.viewonly(c:tags()[1])
    end
    client.focus = c
    c:raise()
  end),

  awful.button({ }, 3, function ()
    if instance then
      instance:hide()
      instance = nil
    else
      instance = awful.menu.clients({ width=250 })
    end
  end),

  awful.button({ }, 4, function ()
    awful.client.focus.byidx(1)
    if client.focus then client.focus:raise() end
  end),

  awful.button({ }, 5, function ()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
  end)
)

for s = 1, screen.count() do
  -- Create a promptbox for each screen
  prompt_box[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })

  -- Image box with the layout we're using
  layout_box[s] = awful.widget.layoutbox(s)
  layout_box[s]:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
    awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
    awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
    awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)
  ))

  -- Create a taglist widget
  taglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, taglist.buttons)

  -- Create a tasklist widget
  tasklist[s] = awful.widget.tasklist(function(c)
    return awful.widget.tasklist.label.currenttags(c, s)
  end, tasklist.buttons)

  -- Create the wibox
  wibox[s] = awful.wibox({ position = "top", screen = s })

  -- Add widgets to the wibox - order matters
  wibox[s].widgets = {
    {
      launcher,
      taglist[s],
      prompt_box[s],

      layout = awful.widget.layout.horizontal.leftright
    },
    layout_box[s],
    text_clock,
    separator,
    obvious.battery(),
    separator,
    obvious.temp_info(),
    separator,
    s == 1 and systray or nil,
    separator,
    mpd,
    separator,
    obvious.volume_alsa(0, "Master"),
    tasklist[s],

    layout = awful.widget.layout.horizontal.rightleft
  }
end

-- Mouse bindings
root.buttons(awful.util.table.join(
  awful.button({ }, 3, function () main_menu:toggle() end),
  awful.button({ }, 4, awful.tag.viewnext),
  awful.button({ }, 5, awful.tag.viewprev)
))

-- Key bindings
global_keys = awful.util.table.join(
  awful.key({ modkey, }, "Left",   awful.tag.viewprev       ),
  awful.key({ modkey, }, "Right",  awful.tag.viewnext       ),
  awful.key({ modkey, }, "Escape", awful.tag.history.restore),

  awful.key({ modkey, }, "j", function ()
    awful.client.focus.byidx( 1)
    if client.focus then client.focus:raise() end
  end),
  awful.key({ modkey, }, "k", function ()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
  end),

  -- Layout manipulation
  awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
  awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
  awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
  awful.key({ modkey,           }, "Tab", function ()
    awful.client.focus.history.previous()
    if client.focus then
      client.focus:raise()
    end
  end),

  -- Standard program
  awful.key({ modkey, },           "Return", function () spawn(terminal) end),
  awful.key({ modkey, "Shift"   }, "q",      awesome.restart),

  awful.key({ modkey, },           "l",     function () awful.tag.incmwfact( 0.05)    end),
  awful.key({ modkey, },           "h",     function () awful.tag.incmwfact(-0.05)    end),
  awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
  awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
  awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
  awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
  awful.key({ modkey, },           "space", function () awful.layout.inc(layouts,  1) end),
  awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

  -- sound & brightness
  awful.key({ modkey }, "F3", function () obvious.volume_alsa.mute(0, "Master")     end),
  awful.key({ modkey }, "F4", function () obvious.volume_alsa.lower(0, "Master", 5) end),
  awful.key({ modkey }, "F5", function () obvious.volume_alsa.raise(0, "Master", 5) end),
  awful.key({ modkey }, "F8", function () spawn("brightness down")                  end),
  awful.key({ modkey }, "F9", function () spawn("brightness up")                    end),

  -- music management
  awful.key({ modkey, "Shift" }, "p", function () spawn("mpc toggle") end),
  awful.key({ modkey, "Shift" }, ".", function () spawn("mpc next")   end),
  awful.key({ modkey, "Shift" }, ",", function () spawn("mpc prev")   end),

  -- prompt
  awful.key({ modkey }, "r", function () promt_box[mouse.screen]:run() end),
  awful.key({ modkey }, "p", function () spawn("gmrun")                end),

  -- applications
  awful.key({ modkey, "Shift" }, "f", function () summon("firefox-beta-bin", { class = "Firefox" }) end),
  awful.key({ modkey, "Shift" }, "m", function () spawn("firefox-beta-bin gmail.com") end),
  awful.key({ modkey, "Shift" }, "t", function () spawn("thunar") end),

  -- pixel-grabbing
  awful.key({ modkey }, "F11", function () spawn("grabc 2>&1 | xclip -i") end),

  -- screengrabbing
  awful.key({ modkey }, "F12", function () spawn("scrot -e 'mv $f /home/andrew/images/shots/'") end),

  awful.key({ modkey }, "x", function ()
    awful.prompt.run({ prompt = "Run Lua code: " },
    prompt_box[mouse.screen].widget,
    awful.util.eval, nil,
    awful.util.getdir("cache") .. "/history_eval")
  end)
)

client_keys = awful.util.table.join(
  awful.key({ modkey, },           "f",      function (c) c.fullscreen = not c.fullscreen  end),

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

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
  keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
for i = 1, keynumber do
  global_keys = awful.util.table.join(
    global_keys,
    awful.key({ modkey }, "#" .. i + 9, function ()
      local screen = mouse.screen
      if tags[screen][i] then
        awful.tag.viewonly(tags[screen][i])
      end
    end),

    awful.key({ modkey, "Control" }, "#" .. i + 9, function ()
      local screen = mouse.screen
      if tags[screen][i] then
        awful.tag.viewtoggle(tags[screen][i])
      end
    end),

    awful.key({ modkey, "Shift" }, "#" .. i + 9, function ()
      if client.focus and tags[client.focus.screen][i] then
        awful.client.movetotag(tags[client.focus.screen][i])
      end
    end),

    awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function ()
      if client.focus and tags[client.focus.screen][i] then
        awful.client.toggletag(tags[client.focus.screen][i])
      end
    end)
  )
end

client_buttons = awful.util.table.join(
  awful.button({ },        1, function (c) client.focus = c; c:raise() end),
  awful.button({ modkey }, 1, awful.mouse.client.move),
  awful.button({ modkey }, 3, awful.mouse.client.resize)
)

root.keys(global_keys)

-- Rules
awful.rules.rules = {
  -- All clients will match this rule.
  {
    rule = { },
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = true,
      keys = client_keys,
      buttons = client_buttons
    }
  },

  {
    rule =       { class = "MPlayer" },
    properties = { floating = true },
  },

  {
    rule =       { class = "gimp" },
    properties = { floating = true }
  },

  {
    rule =       { class = "Skype" },
    properties = { tag = tags[1][2] }
  },
}

-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
  if not startup then
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- awful.client.setslave(c)

    -- Put windows in a smart way, only if they does not set an initial position.
    if not c.size_hints.user_position and not c.size_hints.program_position then
      awful.placement.no_overlap(c)
      awful.placement.no_offscreen(c)
    end
  end
end)

client.add_signal("focus",   function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
