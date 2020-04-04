pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

#include math2d.p8
#include physics.p8
#include broadphase.p8
#include geometry.p8
#include forces.p8

function _init()
  vp = viewport{ scale=8 }
  s = scene{ g=0, size=100 }

  vlist = { [0]=ngon(1, 3), ngon(1, 4), ngon(1, 5), ngon(1, 6), ngon(1, 7), ngon(1, 8), ngon(1, 9), ngon(1, 10) }

  local num, bodies = 10, {}
  for i=1,num do
    bodies[i] = s.add_body{ x=rnd(32)-16, y=rnd(32)-16, mass=rnd(50), verts=vlist[flr(rnd()*6)] }
  end

  for i=1,num do
    for j=i+1,num do
      s.add_force(gravity{ scene=s, id1=bodies[i], id2=bodies[j], g=2 })
    end
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
