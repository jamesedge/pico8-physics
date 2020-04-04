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

  bodies, trails = {
    s.add_body{ x=0, y=0, mass=2000, verts=ngon(1, 10) },
    s.add_body{ x=0, y=4, mass=1, verts=ngon(0.5, 10) },
    s.add_body{ x=5, y=0, mass=1, verts=ngon(0.5, 10) },
    s.add_body{ x=0, y=-7, mass=1, verts=ngon(0.5, 10) }
  }, {}

  foreach(bodies, function(b1)
    trails[b1] = {}
    foreach(bodies, function(b2)
      if (b2>b1) s.add_force(gravity{ scene=s, id1=b1, id2=b2 })
    end)
  end)

  s.apply_impulse(bodies[2], 20, 0, 0)
  s.apply_impulse(bodies[3], 0, -20, 0)
  s.apply_impulse(bodies[4], -18, 0, 0)
end

function _update60()
  s.update()

  local function extend_trail(trail, body, length)
    if #trail<length then trail[#trail+1] = { s.position(body) }
    else
      for i=2,length do trail[i-1] = trail[i] end
      trail[length] = { s.position(body) }
    end
  end
  foreach(bodies, function(body) extend_trail(trails[body], body, 30) end)
end

function _draw()
  cls()

  color(0x8)

  local function draw_trail(trail)
    local pos, x1, y1, x2, y2
    pos = trail[1]
    x1, y1 = vp.to_screen(pos[1], pos[2])
    for i=2,#trail do
      pos = trail[i]
      x2, y2 = vp.to_screen(pos[1], pos[2])
      line(x1, y1, x2, y2)
      x1, y1 = x2, y2
    end
  end
  foreach(bodies, function(body) draw_trail(trails[body]) end)

  s.draw(vp)

  print(flr(stat(0)) .. ' kib', 5, 5, 0x7)
  print(flr(stat(1)*100) .. '% ' .. stat(7) .. 'fps', 5, 15, 0x7)
  rect(0, 0, 127, 127, 0x7)
end
