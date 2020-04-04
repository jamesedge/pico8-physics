pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

#include math2d.p8
#include physics.p8
#include broadphase.p8
#include geometry.p8
#include forces.p8

function _init()
  vp = viewport{}
  s = scene{}

  body = s.add_body{ x=0, y=3 }
  sp1 = spring{ scene=s, id1=s.add_body{ x=-3, y=3, mass=0, moi=0 }, id2=body, x2=-0.2, y2=0.2, k=10 }
  sp2 = spring{ scene=s, id1=s.add_body{ x=3, y=3, mass=0, moi=0 }, id2=body, x2=0.2, y2=0.2, k=10 }
  s.add_force(sp1)
  s.add_force(sp2)

end

function _update60()
  s.update()
end

function _draw()
  cls()
  s.draw(vp)

  local x1, y1, x2, y2 = sp1.anchors()
  x1, y1 = vp.to_screen(x1, y1)
  x2, y2 = vp.to_screen(x2, y2)
  line(x1, y1, x2, y2, 0x7)

  x1, y1, x2, y2 = sp2.anchors()
  x1, y1 = vp.to_screen(x1, y1)
  x2, y2 = vp.to_screen(x2, y2)
  line(x1, y1, x2, y2, 0x7)

  print(flr(stat(0)) .. ' kib', 5, 5, 0x7)
  print(flr(stat(1)*100) .. '% ' .. stat(7) .. 'fps', 5, 15, 0x7)
  rect(0, 0, 127, 127, 0x7)
end
