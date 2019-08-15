local awful = require("awful")

module("lib.util")

function spawner(command)
  return function () awful.spawn(command) end
end

function colorize(color, string)
  return '<span color="'..color..'">'..string..'</span>'
end
