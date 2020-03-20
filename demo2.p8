pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

#include math2d.p8
#include physics.p8
#include broadphase.p8
#include geometry.p8

vp = viewport()
s = scene{}

listener = {
  on_event=function(args)
    if args.event==0x01 then
      --printh('COLLISION ENTERED '..args.id..'x'..args.body)
    elseif args.event==0x02 then
      --printh('COLLISION EXITED '..args.id..'x'..args.body)
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
  vp.scale(0.8)
  --vp.translate(16, 0)
  s.add_body{ x=0, y=-3.5, mass=0, moi=0, rest=0.0, verts=rectangle(8, 1) }

  for i=0,6 do
    s.add_body{ x=-1.5, y=i-2.5, listener=listener }
    s.add_body{ x=0, y=i-2.5, listener=listener }
    s.add_body{ x=1.5, y=i-2.5, listener=listener }
  end

  for i=1,100 do s.update(1/60) end
end

function _update60()
  if (btnp(4)) s.apply_impulse(s.add_body{ x=-9, y=0 }, 50, 0, 0)
  s.update()
end

function _draw()
  cls()
  s.draw(vp)
  print(flr(stat(0)) .. ' kib', 5, 5, 0x7)
  print(flr(stat(1)*100) .. '% ' .. stat(7) .. 'fps', 5, 15, 0x7)
  rect(0, 0, 127, 127, 0x7)
end
