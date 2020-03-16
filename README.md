# Pico8 Physics

This is an implementation of a constraint solver for rigid body physics in pico8/lua. This approach is based upon the Erin Catto's work on sequential impulses, see these [slides](https://box2d.org/files/ErinCatto_SequentialImpulses_GDC2006.pdf).

## Example

All physics objects (rigid bodies) are managed within a scene object. The following code can be used to create a scene, and add some rigid bodies.

'''
myscene = scene{ size=15 }
floor = myscene.add_body{ x=0, y=-4, mass=0, moi=0, verts=rectangle(10, 1) }
box = myscene.add_body{ x=0, y=4, mass=1, verts=rectangle(1, 1) }
'''



## Links

[pico-8 fantasy console](https://www.lexaloffle.com/pico-8.php)
[box2d](https://box2d.org/)
