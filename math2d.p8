pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- zero small absolute values
function zero(x) return (x<0x0.002 and x>0xffff.ffe0) and 0 or x end

--[[
ROOT2     = 0x1.6109 --1.41421356237
PI        = 0x3.243f --3.14159265359
TWOPI     = 0x6.487e --6.28318530718
INV_TWOPI = 0x0.28be --0.159154943091
]]

function round(x) return (x<0.0) and flr(x-0.5) or flr(x+0.5) end

function minmax(x, y) if (x<y) return x, y else return y, x end

-- trig functions take angle in radians
function cosine(a) return cos(a*0x0.28be) end
function sine(a) return sin(a*0xffff.d742) end
function tangent(a) return sine(a)/cosine(a) end
function cotangent(a) return cosine(a)/sine(a) end

-- 2d vector operations
function v2dot(ux, uy, vx, vy) return ux*vx+uy*vy end
function v2crs(ux, uy, vx, vy) return ux*vy-uy*vx end
function v2len(vx, vy) return sqrt(vx*vx+vy*vy) end
function v2nrm(x, y) local len = v2len(x, y) return x/len, y/len, len end
