- README
- Smoother air to ground transition (particularly in side-winds).
- Handle high mass config (Kilo, Bravo, ...)
- Manage high moment of inertia coefficient (side tanks / loads)
- Handle the various aspects of stability & fine tune their components.
- Link autopilot.
- replace the location of the actuators output. 

- Change the rate control law to a torque control law (ref for moment & forces formulas according to the FDM: https://jsbsim-team.github.io/jsbsim/FGAerodynamics_8cpp_source.html). (would solve pretty much all previous points)