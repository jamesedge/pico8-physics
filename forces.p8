pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-->8
-- spring force

function spring(args)
  local scene, id1, x1, y1, id2, x2, y2, k, damp,
        px1, py1, px2, py2, vx1, vy1, vx2, vy2, dx, dy, rlen, len, f, fx, fy =
    args.scene, args.id1, args.x1 or 0, args.y1 or 0,
    args.id2, args.x2 or 0, args.y2 or 0, args.k or 0.1, args.damp or 0.1

  px1, py1 = transform(x1, y1, scene.position(id1))
  px2, py2 = transform(x2, y2, scene.position(id2))
  rlen = sqrt((px1-px2)^2+(py1-py2)^2)

  return {
    anchors=function() return px1, py1, px2, py2 end,
    apply=function(dt)
      px1, py1 = transform(x1, y1, scene.position(id1))
      vx1, vy1 = scene.velocity(id1)
      px2, py2 = transform(x2, y2, scene.position(id2))
      vx2, vy2 = scene.velocity(id2)
      dx, dy = px2-px1, py2-py1
      len = sqrt(dx^2+dy^2)
      dx /= len dy /= len
      f = k*(len-rlen)
      fx, fy = dx*f+(vx2-vx1)*damp, dy*f+(vy2-vy1)*damp
      scene.apply_force(id1, dt, fx, fy, px1, py1)
      scene.apply_force(id2, dt, -fx, -fy, px2, py2)
    end
  }
end

-->8
-- gravity force

function gravity(args)
  local scene, id1, id2, g = args.scene, args.id1, args.id2, args.g or 1
  g *= scene.mass(id1)*scene.mass(id2)

  return {
    apply=function(dt)
      local x1, y1, x2, y2, dx, dy, dist2, dist, f, fx, fy
      x1, y1 = scene.position(id1)
      x2, y2 = scene.position(id2)
      dx, dy = x2-x1, y2-y1
      dist2 = dx^2+dy^2
      f = g/dist2
      if f>0x0.001 then
        dist = sqrt(dist2)
        dx /= dist dy /= dist
        fx, fy = f*dx, f*dy
        scene.apply_force(id1, dt, fx, fy)
        scene.apply_force(id2, dt, -fx, -fy)
      end
    end
  }
end
