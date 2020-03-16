pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

#include math2d.p8
#include physics.p8
#include broadphase.p8
#include geometry.p8

vp = viewport()
s = scene{}

vlist = { [0]=ngon(0.5, 3), ngon(0.5, 4), ngon(0.5, 5), ngon(0.5, 6), ngon(0.5, 7), ngon(0.5, 8), ngon(0.5, 9), ngon(0.5, 10) }

listener = {
  on_event=function(args)
    if args.event==0x01 then
      printh('COLLISION ENTERED '..args.id..'x'..args.body)
    elseif args.event==0x02 then
      printh('COLLISION EXITED '..args.id..'x'..args.body)
    elseif args.event==0x03 then
      printh('SLEEPS '..args.id)
    elseif args.event==0x04 then
      printh('WAKES '..args.id)
    elseif args.event==0x05 then
      printh('DEAD '..args.id)
    end
  end
}

function _init()
  s.add_body{ x=-1.6, y=3.1, mass=0, moi=5, rest=0.6, verts=rectangle(3, 1) }
  s.add_body{ x=1.8, y=0.7, mass=0, moi=5, rest=0.6, verts=rectangle(3, 1) }
  s.add_body{ x=-1.8, y=-0.7, mass=0, moi=5, rest=0.6, verts=rectangle(3, 1) }
  s.add_body{ x=1.6, y=-3.1, mass=0, moi=5, rest=0.6, verts=rectangle(3, 1) }
end

function _update60()
  if (rnd(1)>0.95) s.add_body{ x=rnd(4)-2, y=5+rnd(2), verts=vlist[flr(rnd()*6)], listener=listener }
  s.update()
end

function _draw()
  cls()
  s.draw(vp)

  print(flr(stat(0)) .. ' kib', 5, 5, 0x7)
  print(flr(stat(1)*100) .. '% ' .. stat(7) .. 'fps', 5, 15, 0x7)
  rect(0, 0, 127, 127, 0x7)
end
