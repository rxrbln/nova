-- Tokenizer and Pratt Parser for a C-like language in Lua

local Object = {}

function Object:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   return o
end


-- Lexer: returns tokens as {type=..., value=...}

Tokenizer = Object:new()

function Tokenizer:new(input)
  o = Object.new(self)
  o.input = input
  o.i, o.len = 1, #input
  return o
end

-- Token types
local TokenType = {
  Number = "number",
  String = "string",
  Ident = "identifier",
  Symbol = "symbol",
  Keyword = "keyword",
  EOF = "eof",
}

-- Operator precedence levels
local Precedence = {
  ["="] = 1,
  ["||"] = 2,
  ["&&"] = 3,
  ["=="] = 4, ["!="] = 4,
  ["<"] = 5, ["<="] = 5, [">"] = 5, [">="] = 5,
  ["+"] = 6, ["-"] = 6,
  ["*"] = 7, ["/"] = 7, ["%"] = 7,
  ["("] = 8, -- function calls
}

local keywords = {
  ["fn"]=true, ["if"]=true, ["else"]=true, ["for"]=true, ["return"]=true,
  ["typedef"]=true, ["struct"]=true,
}

local function is_space(c) return c == ' ' or c == '\n' or c == '\r' or c == '\t' end
local function is_alpha(c) return c:match("%a") or c == "_" end
local function is_digit(c) return c:match("%d") end

function Tokenizer:next()
  local input, i, len = self.input, self.i, self.len
  while i <= len do
    local c = input:sub(i, i)

    if is_space(c) then
      i = i + 1

    -- comment
    elseif c == "/" and input:sub(i+1, i+1) == "/" then
      i = i + 2
      while i <= len and input:sub(i, i) ~= "\n" do i = i + 1 end

    elseif is_digit(c) then
      local start = i
      while i <= len and is_digit(input:sub(i, i)) do i = i + 1 end
      self.i = i
      return {type=TokenType.Number, value=tonumber(input:sub(start, i-1))}

    elseif is_alpha(c) then
      local start = i
      while i <= len and input:sub(i, i):match("[%w_]") do i = i + 1 end
      local word = input:sub(start, i-1)
      local type = keywords[word] and TokenType.Keyword or TokenType.Ident
      self.i = i
      return {type=type, value=word}

    elseif c == '"' then
      i = i + 1
      local start = i
      while i <= len and input:sub(i, i) ~= '"' do i = i + 1 end
      local str = input:sub(start, i-1)
      self.i = i + 1
      return {type=TokenType.String, value=str}

    else
      local sym = c
      if (c == '=' or c == '!' or c == '<' or c == '>') and input:sub(i+1,i+1) == '=' then
        sym = c .. '='
        i = i + 1
      elseif c == '&' and input:sub(i+1, i+1) == '&' then
        sym = '&&'; i = i + 1
      elseif c == '|' and input:sub(i+1, i+1) == '|' then
        sym = '||'; i = i + 1
      end
      self.i = i + 1
     return {type=TokenType.Symbol, value=sym}
    end
  end

  self.i = i
  return {type=TokenType.EOF, value=""}
end

function Tokenizer:peek()
  local i = self.i
  local token = self:next()
  self.i = i
  return token
end

Parser = Object:new()

  function Parser:new(input)
    local o = Object.new(self)
    o.tokens = Tokenizer:new(input)
    return o
  end

  function Parser:peek() return self.tokens:peek() end
  function Parser:next() return self.tokens:next() end

  function Parser:expect(type_or_val)
    local tok = self:next()
    if tok.type ~= type_or_val and tok.value ~= type_or_val then
      error("Expected " .. type_or_val .. ", got " .. tok.value)
    end
    return tok
  end

  -- Pratt parser entry point
  function Parser:parse_expression(precedence)
    precedence = precedence or 0
    local t = self:next()
    local left = self:nud(t)
    while Precedence[self:peek().value] and Precedence[self:peek().value] > precedence do
      local op = self:next()
      left = self:led(op, left)
    end
    return left
  end

  -- Null denotation (prefix, literals)
  function Parser:nud(tok)
    if tok.type == TokenType.Number or tok.type == TokenType.String then
      return {type="literal", value=tok.value}
    elseif tok.type == TokenType.Ident then
      if self:peek().value == "(" then
        return self:parse_call(tok.value)
      end
      return {type="identifier", name=tok.value}
    elseif tok.value == "(" then
      local expr = self:parse_expression()
      self:expect(")")
      return expr
    elseif tok.value == "-" then
      local right = self:parse_expression(Precedence["-"])
      return {type="unary", op="-", right=right}
    end
    error("Unexpected token: " .. tok.value)
  end

  -- Left denotation (binary infix)
  function Parser:led(op_tok, left)
    local right = self:parse_expression(Precedence[op_tok.value])
    return {type="binary", op=op_tok.value, left=left, right=right}
  end

  function Parser:parse_call(name)
    self:expect("(")
    local args = {}
    if self:peek().value ~= ")" then
      repeat
        table.insert(args, self:parse_expression())
      until self:peek().value ~= "," or not self:next()
    end
    self:expect(")")
    return {type="call", name=name, args=args}
  end

  function Parser:parse_statement()
    local tok = self:peek()

    if tok.type == TokenType.Keyword and tok.value == "fn" then
     return self:parse_function()
    elseif tok.type == TokenType.Keyword and tok.value == "if" then
      return self:parse_if()
    elseif tok.type == TokenType.Keyword and tok.value == "for" then
      return self:parse_for()
    elseif tok.type == TokenType.Keyword and tok.value == "typedef" then
      return self:parse_typedef()
    elseif tok.type == TokenType.Keyword and tok.value == "struct" then
      return self:parse_struct()
    elseif tok.type == TokenType.Keyword and tok.value == "return" then
      self:next()
      return {type="return", value=self:parse_expression()}
    elseif tok.type == TokenType.Ident then
      local next_tok = self:peek()
      if next_tok and next_tok.type == TokenType.Ident then
        return self:parse_declaration()
      end
    end

    return self:parse_expression()
  end

  function Parser:parse_block()
    local one = self:peek().value ~= "{"
    if not one then self:expect("{") end

    local body = {}
    while self:peek().value ~= "}" do
      table.insert(body, self:parse_statement())
      if self:peek().value == ";" then
        self:next()
        if one then break end
      end
    end
    if not one then self:expect("}") end
    return body
  end

  function Parser:parse_struct()
    self:expect("struct")
    local name = self:expect(TokenType.Ident).value
    self:expect("{")

    local fields = {}
    while self:peek().value ~= "}" do
      local field_type = self:parse_type()

    -- Parse multiple field names separated by commas
      repeat
        local field_name = self:expect(TokenType.Ident).value
        table.insert(fields, {type=field_type, name=field_name})
      until self:peek().value ~= "," or not self:next()
      self:expect(";")
    end

    self:expect("}")

    return {type = "struct",name=name, fields=fields}
  end

  function Parser:parse_type()
    local base = self:expect(TokenType.Ident).value
    if self:peek().value == "[" then
      self:next()
      local size = self:expect(TokenType.Number).value
      self:expect("]")
      return {type = "arraytype", base = base, size = tonumber(size)}
    end
    return {type="type", name=base}
  end

  function Parser:parse_typedef()
    self:expect("typedef")
    local base = self:parse_type()
    local alias = self:expect(TokenType.Ident).value
    self:expect(";")
    return {type="typedef",alias=alias,base=base}
  end

  function Parser:parse_declaration()
    -- Parse the common type for all vars
    local var_type = self:parse_type()
    local decls = {}

    repeat
      -- Parse variable name
      local var_name = self:expect(TokenType.Ident).value

      -- Optional initializer for this variable
      local init = nil
      if self:peek().value == "=" then
        self:next() -- consume '='
        init = self:parse_expression()
      end

      table.insert(decls, {type = "decl", varType = var_type, name = var_name, value = init})
    until self:peek().value ~= "," or not self:next()

    self:expect(";")

    -- Return all declarations as a block or list
    return decls
  end

  function Parser:parse_function()
    -- 1. Match the 'fn' keyword
    self:expect("fn")

    -- 2. Parse return types (comma-separated identifiers)
    local return_types = {}
    repeat
      local tok = self:expect(TokenType.Ident)
      table.insert(return_types, tok.value)
    until self:peek().value ~= "," or not self:next()

    -- 3. Parse function name
    local name = self:expect(TokenType.Ident).value

    -- 4. Parse parameter list
    self:expect("(")
    local params = {}
    if self:peek().value ~= ")" then
      repeat
        local param_type = self:expect(TokenType.Ident).value
        local param_name = self:expect(TokenType.Ident).value
        table.insert(params, { type = param_type, name = param_name })
      until self:peek().value ~= "," or not self:next()
    end
    self:expect(")")

    -- 5. Parse function body
    local body = self:parse_block()

    return {type="function", name=name, returnTypes=return_types, params=params, body=body}
  end

  function Parser:parse_if()
    self:expect("if")
    local cond = self:parse_expression()
    local then_branch = self:parse_block()
    local else_branch = nil
    if self:peek().value == "else" then
      self:next()
      else_branch = self:parse_block()
    end
    return {type="if", cond=cond, thenBranch=then_branch, elseBranch=else_branch}
  end

  function Parser:parse_for()
    self:expect("for")

    -- Parse init statement
    local init = self:parse_statement()
    self:expect(";")

    -- Parse condition
    local cond = self:parse_expression()
    self:expect(";")
    -- Parse update expression (treat as a statement, e.g., assignment)
    local update = self:parse_statement()
    -- Parse body
    local body = self:parse_block()
    return {type="for", init=init, cond=cond, update=update, body=body}
  end

  function Parser:parse()
    local program = {}
    while self:peek().type ~= TokenType.EOF do
      table.insert(program, self:parse_statement())
      if self:peek().value == ";" then self:next() end
    end
    return {type="program", body=program}
  end

return Parser
