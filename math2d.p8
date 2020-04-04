pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

--[[
ROOT2     = 0x1.6109 --1.41421356237
PI        = 0x3.243f --3.14159265359
TWOPI     = 0x6.487e --6.28318530718
INV_TWOPI = 0x0.28be --0.159154943091
]]

-- zero small absolute values
function zero(x) return x<0x0.002 and x>0xffff.ffe0 and 0 or x end

-- returns min and max of x, y
function minmax(x, y) return min(x, y), max(x, y) end

-- trig function takes angle in radians
function cos_sin(a) a*=0x0.28be return cos(a), sin(-a) end

-- 2d transform
function transform(x, y, tx, ty, ta)
  local ca, sa = cos_sin(ta)
  return x*ca-y*sa+tx, x*sa+y*ca+ty
end
