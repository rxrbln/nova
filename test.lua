local Parser = require("lang/parser")

local code = [[
  // test
  fn square(int ) {
    return x * x;
  }

  int y = square(5);
]]

local tokens = Parser.tokenize(code)
local parser = Parser.new(tokens)
local ast = parser:parse()

require("inspect")
print(inspect(ast))
