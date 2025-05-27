local Parser = require("lang/parser")

local code = [[
  fn add(a, b) {
    return a + b;
  }

  let result = add(10, 20);
]]

local tokens = Parser.tokenize(code)
local parser = Parser.new(tokens)
local ast = parser:parse()

require("inspect")
print(inspect(ast))
