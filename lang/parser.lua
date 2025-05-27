-- Tokenizer and Pratt Parser for a C-like language in Lua
local Parser = {}

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

-- Lexer: returns tokens as {type=..., value=...}
function Parser.tokenize(input)
  local keywords = {["fn"]=true, ["if"]=true, ["else"]=true, ["while"]=true, ["return"]=true}
  local tokens, i, len = {}, 1, #input

  local function is_space(c) return c == ' ' or c == '\n' or c == '\r' or c == '\t' end
  local function is_alpha(c) return c:match("%a") or c == "_" end
  local function is_digit(c) return c:match("%d") end

  while i <= len do
    local c = input:sub(i,i)

    if is_space(c) then
      i = i + 1

    -- comment
    elseif c == "/" and input:sub(i+1,i+1) == "/" then
      i = i + 2
      while i <= len and input:sub(i,i) ~= "\n" do i = i + 1 end

    elseif is_digit(c) then
      local start = i
      while i <= len and is_digit(input:sub(i,i)) do i = i + 1 end
      table.insert(tokens, {type=TokenType.Number, value=tonumber(input:sub(start, i-1))})

    elseif is_alpha(c) then
      local start = i
      while i <= len and input:sub(i,i):match("[%w_]") do i = i + 1 end
      local word = input:sub(start, i-1)
      local type = keywords[word] and TokenType.Keyword or TokenType.Ident
      table.insert(tokens, {type=type, value=word})

    elseif c == '"' then
      i = i + 1
      local start = i
      while i <= len and input:sub(i,i) ~= '"' do i = i + 1 end
      local str = input:sub(start, i-1)
      i = i + 1
      table.insert(tokens, {type=TokenType.String, value=str})

    else
      local sym = c
      if (c == '=' or c == '!' or c == '<' or c == '>') and input:sub(i+1,i+1) == '=' then
        sym = c .. '='
        i = i + 1
      elseif c == '&' and input:sub(i+1,i+1) == '&' then
        sym = '&&'; i = i + 1
      elseif c == '|' and input:sub(i+1,i+1) == '|' then
        sym = '||'; i = i + 1
      end
      table.insert(tokens, {type=TokenType.Symbol, value=sym})
      i = i + 1
    end
  end
  table.insert(tokens, {type=TokenType.EOF, value=""})
  return tokens
end

-- Parser setup
function Parser.new(tokens)
  local self = {
    tokens = tokens,
    pos = 1
  }

  function self:peek() return self.tokens[self.pos] end
  function self:next() local t = self:peek(); self.pos = self.pos + 1; return t end
  function self:expect(type_or_val)
    local tok = self:next()
    if tok.type ~= type_or_val and tok.value ~= type_or_val then
      error("Expected " .. type_or_val .. ", got " .. tok.value)
    end
    return tok
  end

  -- Pratt parser entry point
  function self:parse_expression(precedence)
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
  function self:nud(tok)
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
  function self:led(op_tok, left)
    local right = self:parse_expression(Precedence[op_tok.value])
    return {type="binary", op=op_tok.value, left=left, right=right}
  end

  function self:parse_call(name)
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

  function self:parse_statement()
    local tok = self:peek()

    if tok.type == TokenType.Keyword and tok.value == "fn" then
     return self:parse_function()
    elseif tok.type == TokenType.Keyword and tok.value == "if" then
      return self:parse_if()
    elseif tok.type == TokenType.Keyword and tok.value == "while" then
      return self:parse_while()
    elseif tok.type == TokenType.Keyword and tok.value == "return" then
      self:next()
      return {type="return", value=self:parse_expression()}
    elseif tok.type == TokenType.Ident then
      local next_tok = self.tokens[self.pos + 1]
      if next_tok and next_tok.type == TokenType.Ident then
        return self:parse_typed_declaration()
      end
    end

    return self:parse_expression()
  end

  function self:parse_block()
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

  function self:parse_typed_declaration()
    local type_name = self:expect(TokenType.Ident).value
    local name = self:expect(TokenType.Ident).value
    self:expect("=")
    local value = self:parse_expression()
    return {
      type = "declaration",
      varType = type_name,
      name = name,
      value = value
    }
  end

  function self:parse_function()
    self:expect("fn")
    local name = self:expect(TokenType.Ident).value
    self:expect("(")
    local params = {}
    if self:peek().value ~= ")" then
      repeat
        table.insert(params, self:expect(TokenType.Ident).value)
      until self:peek().value ~= "," or not self:next()
    end
    self:expect(")")
    local body = self:parse_block()
    return {type="function", name=name, params=params, body=body}
  end

  function self:parse_if()
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

  function self:parse_while()
    self:expect("while")
    local cond = self:parse_expression()
    local body = self:parse_block()
    return {type="while", cond=cond, body=body}
  end

  function self:parse()
    local program = {}
    while self:peek().type ~= TokenType.EOF do
      table.insert(program, self:parse_statement())
      if self:peek().value == ";" then self:next() end
    end
    return {type="program", body=program}
  end

  return self
end

return Parser
