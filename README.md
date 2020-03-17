# pico8 physics

This is an implementation of a constraint solver for rigid body physics in pico8/lua. This approach is based upon Erin Catto's work on sequential impulses, see these [slides](https://box2d.org/files/ErinCatto_SequentialImpulses_GDC2006.pdf).

## example

All physics objects (rigid bodies) are managed within a scene object. The following code can be used to create a scene, and add some rigid bodies.
```
function _init()
  myscene = scene{ size=15 }
  floor = myscene.add_body{ x=0, y=-4, mass=0, moi=0, verts=rectangle(10, 1) }
  box = myscene.add_body{ x=0, y=4, mass=1, verts=rectangle(1, 1) }
end
```
The parameter to the add_body method is a table containing values defining the rigid body in the physics scene. In this case the position (x, y), mass/inertia (mass, moi) and geometry (verts). The method returns an integer id for the body which can be used to retrieve information. In this example because the floor has mass and inertia 0, it is interpreted as infinite mass and so will not react to forces applied to it. All parameters are in SI units, metres and kg.

Every frame the update method of the scene must be called to cause the simulation to move forward. Update will apply gravity, perform collision detection and response, integrate velocity and move objects in the scene. The time step will be determined by the value of stat(7) - you should aim to keep the framerate constant because a fluctuating framerate can affect the simulation.
```
function _update60()
  myscene.update()
end
```
As positions are stored in metres in the scene, a viewport object can be created to transform these to screen space pixel units. Scene also has a draw method which will display the colliders given a viewport object.
```
function _draw()
  cls()
  vp = viewport{ scale=16 }
  myscene.draw(vp)
end
```
Several demos have been included to show how to use the code.

## links

- [pico-8 fantasy console](https://www.lexaloffle.com/pico-8.php)
- [Erin Catto's box2d](https://box2d.org/)
