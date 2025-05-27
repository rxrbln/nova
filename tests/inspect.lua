function inspect(value, depth)
  depth = depth or 0
  local indent = string.rep("  ", depth)

  if type(value) == "table" then
    local keys = {}
    for k in pairs(value) do
      table.insert(keys, k)
    end

    -- Sort keys: named keys first (strings), then numbers
    table.sort(keys, function(a, b)
      local ta, tb = type(a), type(b)
      if ta == tb then
        return tostring(a) < tostring(b)
      elseif ta == "string" then
        return true
      elseif tb == "string" then
        return false
      else
        return tostring(a) < tostring(b)
      end
    end)

    local items = {}
    for _, k in ipairs(keys) do
      local key
      if type(k) == "string" and k:match("^%a[%w_]*$") then
        key = k
      else
        key = "[" .. tostring(k) .. "]"
      end
      local val = inspect(value[k], depth + 1)
      table.insert(items, indent .. "  " .. key .. " = " .. val)
    end

    return "{\n" .. table.concat(items, ",\n") .. "\n" .. indent .. "}"
  elseif type(value) == "string" then
    return string.format("%q", value)
  else
    return tostring(value)
  end
end
