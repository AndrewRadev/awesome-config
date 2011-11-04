require("awful")

local awful = awful

module("lib.util")

function spawner(command)
  return function () awful.util.spawn(command) end
end

function colorize(color, string)
  return '<span color="'..color..'">'..string..'</span>'
end
