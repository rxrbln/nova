local Parser = require("lang/parser")

local code = [[
  typedef int myint;

  struct Vec3 {
  float x, y, z;
  int id, count;
  }

  // test
  fn int, float square(int x, float y) {
    int a = 0, b = 1, c;
    a = x;
    if x > 0 {
      return x * x;
    } else
      return -x * x

    for x=2; x < 0; x+2 {
      x = x + 2
    }
  }

  int y = square(5);
]]

local code = [[
  fn int test(int x) {
    return x + 2
  }
]]


local tokens = Parser.tokenize(code)
local parser = Parser.new(tokens)
local ast = parser:parse()

require("inspect")
print(inspect(ast))

local Codegen = require("codegen/codegen")

codegen = Codegen:new()
insns = codegen:generate(ast.body)

print(inspect(insns))
