# A simply minimal programming language for the future

In a world where new hyped language compilers and runtime std libraries are implemented in 4GB of sources, it's time for a reset.

At the foundation is Nýr, a portable micro-IR (µIR) designed for efficient and flexible code generation across RISC and CISC CPU ISAs. Built on top of Nýr is Nova, a new minimal high-level language that embraces modern programming principles. Together, Nýr and Nova represent a bold step toward a leaner, more elegant future in software development.
Nava isn't just a language it's a philosophy: that the complexity of modern systems is not a necessity but a choice. Nava chooses minimalism, portability and readability.

# 🛰️ Nova Language Syntax Sheet

Nova is a modern simplified C++ with a touch of Lua, designed for clarity and modern expression. It uses `fn` for function declarations, first class multiple return times and omits parentheses for conditional statements, and optional curly braces for single expression functions, too.

---

## 📃 Comments

```nova
// Single-line comment

/* 
  Multi-line
  comment 
*/
```

---

## 🧠 Keywords

```
fn       if       else     for      return
break    continue class    enum     import
typeof   sizeof   match    case     template
try      catch
```

---

## 🔤 Literals

```nova
123         // integer  
3.14        // float  
"hello"     // string  
'c'         // char  
true, false // boolean  
null        // null value
```

---

## 🧮 Operators

```nova
+   -   *   /   %         // arithmetic  
==  !=  <   >   <=  >=    // comparison  
&&  ||  !                 // logical  
&   |   ^   ~   <<  >>    // bitwise
=   +=  -=  *=  /=  ...   // assignment  
```

---

## 🏗️ Functions

```nova
fn main() {
  print("Hello, " + name)
}
```

*curly braces are optional for single expressions for functions, too*

```nova
fn main()
  print("Hello, " + name)
```

---

## 🔁 Control Structures

### If/Else

```nova
if x > 0 {
  print("Positive")
} else {
  print("Negative or zero")
}
```

### For (also to be use for while)

```nova
for int i = 0; i < 10; ++i {
  print(i)
}
```

*for iterators and generators, too*           

```nova
for string s = it.next() {
  print(i)
}
```

---

## 🧱 Data Structures

### Class

```nova
class Vec2 {
  float x,
  i32 y,
}
```

### Enum

```nova
enum Color {
  Red,
  Green,
  Blue,
}
```

---

## 🧩 Match Expression

```nova
match color {
  case Red:
    print("Stop")
  case Green:
    print("Go")
  default: 
    print("Wait")
}
```

---

## 📦 Modules

```nova
import math

fn main() {
  print(math.sqrt(16))
}
```

