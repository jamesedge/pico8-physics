pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

#include math2d.p8
#include physics.p8
#include broadphase.p8
#include geometry.p8
#include charcontrol.p8

local frame, anim, collide, vp, s, cc, box1, box2 = 0, 0, false

function _init()
  vp = viewport()
  s = scene{}
  cc = charcontroller(s, { x=-0.5 })

  s.add_body{ x=0, y=-3.5, mass=0, moi=0, rest=0, verts=rectangle(8, 1) }
  s.add_body{ x=-4, y=0, mass=0, moi=0, rest=0, verts=rectangle(1, 8) }
  s.add_body{ x=4, y=0, mass=0, moi=0, rest=0, verts=rectangle(1, 8) }

  s.add_body{ x=-3, y=-1.25, mass=0, moi=0, rest=0, verts=rectangle(3, 0.5) }
  s.add_body{ x=2, y=0.25, mass=0, moi=0, rest=0, verts=rectangle(5, 0.5) }
  s.add_body{ x=-0.5, y=2.75, mass=0, moi=0, rest=0, verts=rectangle(3, 0.5) }

  box1 = s.add_body{ x=1.5, y=1 }
  box2 = s.add_body{ x=-1.5, y=3.5 }

  s.add_body{ x=2, y=-3.5, a=1.2, mass=0, moi=0, rest=0, verts=rectangle(1.3, 4) }

  for i=1,100 do s.update(1/60) end
end

function _update60()
  frame += 1
  if (frame%8==0) anim = (anim+1)%3
  cc.update()
  s.update()
  if (btnp(5)) collide = not collide
end

-- adapted from @freds72 code
function rspr(sx,sy,x,y,a,w)
    local ca,sa=cos_sin(a)
    local srcx,srcy,addr,pixel_pair
    local ddx0,ddy0=ca,sa
    local mask=shl(0xfff8,(w-1))
    w*=4
    ca*=w-0.5
    sa*=w-0.5
    local dx0,dy0=sa-ca+w,-ca-sa+w
    w=2*w-1
    for ix=0,w do
        srcx,srcy=dx0,dy0
        for iy=0,w do
            if band(bor(srcx,srcy),mask)==0 then
                local c=sget(sx+srcx,sy+srcy)
                if (c>0) pset(x+ix,y+iy,c)
            end
            srcx-=ddy0
            srcy+=ddx0
        end
        dx0+=ddx0
        dy0+=ddy0
    end
end

function _draw()
  cls()

  local x, y, a, px, py

  x, y, a = s.position(box1)
  px, py = vp.to_screen(x, y)
  rspr(0, 104, px-16, py-16, a, 4)

  x, y, a = s.position(box2)
  px, py = vp.to_screen(x, y)
  rspr(0, 104, px-16, py-16, a, 4)

  local wx, wy = s.position(cc.id())
  local x, y = vp.to_screen(wx, wy)
  local state = cc.state()

  if state==0 then spr(anim*2, x-8, y-8, 2, 2, band(state, 0x02)>0)
  else
    if band(state, 0x04)>0 then spr(96+anim*2, x-8, y-8, 2, 2, band(state, 0x02)>0)
    elseif band(state, 0x08)>0 then spr(128+anim*2, x-8, y-8, 2, 2, band(state, 0x02)>0)
    elseif band(state, 0x10)>0 then spr(64+anim*2, x-8, y-8, 2, 2, band(state, 0x02)>0)
    else spr(32+anim*2, x-8, y-8, 2, 2, band(state, 0x02)>0) end
  end

  map(0, 0, 0, 0, 16, 16)

  if (collide) s.draw(vp)

  rect(0, 0, 127, 127, 0x7)
end
__gfx__
00000000000000000000000000000000000000000000000077777777000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000070000007000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000070707707000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000070077707000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000070777007000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000070770707000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000070000007000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000077777777000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000007770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077770000000000000777000000000000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077000000000000007700000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077000000000000007700000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077000000000000007700000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077000000000000007700000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077000000000000007700000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000707000000000000007700000000000000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000700700000000000007070000000000077777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000070700000007777007000000000070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000007000000007000007000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000000000000000007700000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000700000000000000070000000000777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077777700000000007777770000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077000000000000007700000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077000000000000007700000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077000000000000007700000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077000000000000007700000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000707000000000000007700000000000000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000700700000000000007070000000000077777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000070700000007777007000000000070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000007000000007000007000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000000000000000007700000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077770000000000007777000000000000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007770777000000000777077700000000077707770000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000700000000000700070000000000070007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007770000000000000777000000000000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007770000000000000777000000000000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000000000000070000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007000000000000000700000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000000000000070000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777700700777007007077777777700700707777777777777777000000000000000000000000000000000000000000000000000000000000000000000000
07007007007007077070070007007007007007000700700777007007000000000000000000000000000000000000000000000000000000000000000000000000
70070070070070077700700770070070070070077007007770070070000000000000000000000000000000000000000000000000000000000000000000000000
00700700700700777007007000700700700700700070070770700700000000000000000000000000000000000000000000000000000000000000000000000000
07007007007007077070070007007007007007000700700777007007000000000000000000000000000000000000000000000000000000000000000000000000
70070070070070077700700770070070070070077007007770070070000000000000000000000000000000000000000000000000000000000000000000000000
00700700700700777007007000700700700700700070070777700700000000000000000000000000000000000000000000000000000000000000000000000000
07007007007007077070070077777777007007007777777777777777000000000000000000000000000000000000000000000000000000000000000000000000
00770070000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000077777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07007007000077000000000000700777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07070070000707700000000007007007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700700000770077000000070070070070077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77007007000700707770000000700700700700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70070070007007007077700007007007007007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70700700007070070707777770070070070070070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008a8000700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00083000707077070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000700777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00330000707770070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00033000707707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000707770077700770700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000707700777007770700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000707007770077700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700077700777000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700777007770070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000707770077700770700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000707700777007770700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000707007770077700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700077700777000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700777007770070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000707770077700770700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000707700777007770700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
a10000000000000000000000000000a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a100000000c0000000000000000000a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a1000000a6a3a3a3a3a50000000000a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a10000000000000000000000000000a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a10000000000000000000000000000a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a10000000000000000000000000000a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a10000000000000000c00000b80000a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a1b7b7b7b7b7b7a6a3a3a3a3a3a3a3a400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a100000000000000b8000000000000a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a1a70000c000000000000000000000a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a4a3a3a3a500000000000000000000a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a10000000000000000000000000000a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a1b7000000000000b1b2a7a7a7a7a7a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a100000000000000b0a4b3b4b2a7a7a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a4a0a0a0a0a0a0a0a4a4a4a4a4a0a0a4a7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
