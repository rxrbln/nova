local Codegen = {}
Codegen.__index = Codegen

function Codegen.new()
  return setmetatable({
    instructions = {},
    regCount = 0,
    env = {},   -- varName -> register
    labelCount = 0,
  }, Codegen)
end

function Codegen:next_reg()
  self.regCount = self.regCount + 1
  return "r"..self.regCount
end

function Codegen:emit(instr)
  table.insert(self.instructions, instr)
end

function Codegen:new_label(prefix)
  prefix = prefix or "L"
  self.labelCount = self.labelCount + 1
  return prefix .. tostring(self.labelCount)
end

function Codegen:gen_expression(node)
  if node.type == "number" then
    local r = self:next_reg()
    self:emit(string.format("MOV %s, %s", r, node.value))
    return r
  elseif node.type == "variable" then
    return self.env[node.name] -- variable already in some register
  elseif node.type == "binary" then
    local left = self:gen_expression(node.left)
    local right = self:gen_expression(node.right)
    -- Assume left is dest, operate on it with right
    local op_map = {["+"]="ADD", ["-"]="SUB", ["*"]="MUL", ["/"]="DIV"}
    local op = op_map[node.operator]
    self:emit(string.format("%s %s, %s", op, left, right))
    return left
  else
    error("Unsupported expression type: "..tostring(node.type))
  end
end

function Codegen:gen_declaration(node)
  local r = self:next_reg()
  self.env[node.name] = r
  if node.value then
    local val_reg = self:gen_expression(node.value)
    self:emit(string.format("MOV %s, %s", r, val_reg))
  else
    self:emit(string.format("MOV %s, 0", r)) -- default init 0
  end
end

function Codegen:gen_if(node)
  local cond_reg = self:gen_expression(node.cond)
  local else_label = self:new_label("else")
  local end_label = self:new_label("endif")

  self:emit(string.format("JZ %s, %s", cond_reg, else_label))
  self:gen_block(node.then_block)
  self:emit(string.format("JMP %s", end_label))
  self:emit(else_label .. ":")
  if node.else_block then
    self:gen_block(node.else_block)
  end
  self:emit(end_label .. ":")
end

function Codegen:gen_block(block)
  for _, stmt in ipairs(block) do
    self:gen_statement(stmt)
  end
end

function Codegen:gen_statement(node)
  if node.type == "declaration" then
    self:gen_declaration(node)
  elseif node.type == "expression" then
    self:gen_expression(node.expr)
  elseif node.type == "if" then
    self:gen_if(node)
  elseif node.type == "block" then
    self:gen_block(node.statements)
    local ret_reg = self:gen_expression(node.value)
    self:emit(string.format("MOV r0, %s", ret_reg)) -- r0 = return register
  elseif node.type == "return" then
    self:emit("RET")
  elseif node.type == "function" then
    self.env = {}   -- clear env for new func
    self.regCount = 0
    self:emit(node.name .. ":")
    for _, param in ipairs(node.params) do
      local r = self:next_reg()
      self.env[param.name] = r
      -- assume parameters are passed in registers r1..rN
      self:emit(string.format("MOV %s, arg_%s", r, param.name))
    end
    self:gen_block(node.body)
    self:emit("RET")
  else
    error("Unknown statement type: "..tostring(node.type))
  end
end

function Codegen:generate(ast)
  for _, node in ipairs(ast) do
    self:gen_statement(node)
  end
  return self.instructions
end

return Codegen
