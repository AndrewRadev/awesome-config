local awful = require("awful")
local beautiful = require("beautiful")

return awful.widget.watch('acpi -t', 60, function(widget, stdout, _, _, exitcode)
  widget.font = beautiful.font

  if exitcode > 0 then
    widget:set_text("[error: exitcode]")
    return
  end

  local temp = {}
  for t in string.gmatch(stdout, 'Thermal %d+: %w+, (%d+.?%d*) degrees') do
    temp[#temp + 1] = tonumber(t)
  end

  if #temp == 0 then
    widget:set_text("[error: regex]")
    return
  end

  local color = '#900000' -- hot

  if temp[1] < 50 then
    color = '#009000' -- normal
  elseif temp[1] >= 50 and temp[1] < 60 then
    color = '#909000' -- warm
  end

  degrees = '<span foreground="' .. color .. '">C</span>'
  widget:set_markup(string.format('%.2f', temp[1]) .. ' ' .. degrees)
end)
