function inspect(value, depth)
  depth = depth or 0
  local indent = string.rep("  ", depth)

  if type(value) == "table" then
    local items = {}
    for k, v in pairs(value) do
      local key
      if type(k) == "string" then
        key = string.format("%q", k)
      else
        key = "[" .. tostring(k) .. "]"
      end
      local val = inspect(v, depth + 1)
      table.insert(items, indent .. "  " .. key .. " = " .. val)
    end
    return "{\n" .. table.concat(items, ",\n") .. "\n" .. indent .. "}"
  elseif type(value) == "string" then
    return string.format("%q", value)
  else
    return tostring(value)
  end
end
