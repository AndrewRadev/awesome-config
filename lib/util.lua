require("awful")

local awful = awful

module("lib.util")

function spawner(command)
  return function () awful.util.spawn(command) end
end

function colorize(color, string)
  return '<span color="'..color..'">'..string..'</span>'
end

function floating(window_class)
  return {
    rule       = { class = window_class },
    properties = { floating = true },
  }
end
