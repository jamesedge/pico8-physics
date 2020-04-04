pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-->8
-- joint constraint

function joint(scene, id1, x1, y1, id2, x2, y2, beta)
  local lambda, j1, j2, j3, j4, j5, j6, b, jm, imass1, imoi1, imass2, imoi2 = 0

  imass1, imoi1 = scene.inv_mass(id1)
  imass2, imoi2 = scene.inv_mass(id2)

  return {
    eval=function(dt)
      local x, y, a, ca, sa, jx1, jy1, jx2, jy2, px1, py1, px2, py2, dx, dy, c
      x, y, a = scene.position(id1)
      ca, sa = cos_sin(a)
      jx1, jy1 = (x1*ca-y1*sa)+x, (x1*sa+y1*ca)+y
      px1, py1 = jx1-x, jy1-y
      x, y, a = scene.position(id2)
      ca, sa = cos_sin(a)
      jx2, jy2 = (x2*ca-y2*sa)+x, (x2*sa+y2*ca)+y
      px2, py2 = jx2-x, jy2-y
      dx, dy = jx1-jx2, jy1-jy2

      c = dx*dx+dy*dy

      if (c<0x0.001) return false

      -- warmstart
      local px, py = dx*lambda, dy*lambda
      scene.apply_impulse(id1, px, py, px1*py-py1*px)
      scene.apply_impulse(id2, -px, -py, -(px2*py-py2*px))

      j1, j2, j3, j4, j5, j6, b =
        2*dx, 2*dy, -2*(dx*py1-dy*px1), -2*dx, -2*dy, 2*(dx*py2-dy*px2), c*beta/dt
      jm = j1*imass1*j1+j2*imass1*j2+j3*imoi1*j3+j4*imass2*j4+j5*imass2*j5+j6*imoi2*j6

      return true
    end,
    solve=function()
      local vx1, vy1, va1 = scene.velocity(id1)
      local vx2, vy2, va2 = scene.velocity(id2)

      local del = -(j1*vx1+j2*vy1+j3*va1+j4*vx2+j5*vy2+j6*va2+b)/jm
      lambda += del

      scene.apply_impulse(id1, del*j1, del*j2, del*j3)
      scene.apply_impulse(id2, del*j4, del*j5, del*j6)

      return del*del<0x0.001
    end
  }
end
