local Parser = require("lang/parser")

local code = [[
  typedef int myint;

  struct Vec3 {
    float x;
    float y;
    float z;
  }

  // test
  fn int, float square(int x, float y) {
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

local tokens = Parser.tokenize(code)
local parser = Parser.new(tokens)
local ast = parser:parse()

require("inspect")
print(inspect(ast))
