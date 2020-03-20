pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

#include math2d.p8
#include physics.p8
#include broadphase.p8
#include geometry.p8
#include constraints.p8

vp = viewport{ scale=8 }
s = scene{ size=100 }

function _init()
  local prev = s.add_body{ x=0, y=7, mass=0, moi=0, layer=2 }
  for i=1,8 do
    local link = s.add_body{ x=2*i-1, y=7, layer=(i+1)%2, verts=rectangle(2, 0.5) }
    s.add_constraint(joint(s, prev, i>1 and 1 or 0, 0, link, -1, 0, 0.8))
    prev = link
  end
end

function _update60()
  s.update()
end

function _draw()
  cls()
  s.draw(vp)

  print(flr(stat(0)) .. ' kib', 5, 5, 0x7)
  print(flr(stat(1)*100) .. '% ' .. stat(7) .. 'fps', 5, 15, 0x7)
  rect(0, 0, 127, 127, 0x7)
end
