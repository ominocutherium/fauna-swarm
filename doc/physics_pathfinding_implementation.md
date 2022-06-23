# Physics & AI Implementation (orders, pathfinding)

Display looks like this:
![Image of a horizontal 2:1 diamond-shaped isometric grid]()

Where all tiles, unit, and building positions are translated from the actual physics simulation, which looks like this:
![Image of an upright square grid with units as circles, buildings as smaller squares, and terrain filling in squares too]()

This ensures for simplified collision checking and little distortion in small velocity changes while still representing the isometric space well.

This design is only possible by sufficiently decoupling physics from display. If, instead, all units each had self-contained data in a KinematicBody2D node, display would be either have to exactly match physics or require even more nodes to decouple (e.g. references to RemoteTransform2D nodes under a display parent elsewhere in the scene tree which is transformed by the matrix). While the main reason to avoid PhysicsBody2D nodes is performance and reducing the ceiling of nodes calling `_physics_process()`, this is another advantage.

The Units singleton holds position, velocity, and direction information for all of the units in the map in pooled arrays. It also holds hash maps containing lists of unit unique identifiers based on positions on the map, to aid with position-based lookups from the user interface. This singleton iterates over the array and makes Physics2DServer calls for each unit that needs to be moved. It also holds point paths units are following and distanced followed since last collision/point in path, updates this when it moves units, updates cooldowns for attacks and spawns hitboxes with signals when necessary (another object elsewhere is responsible for resolving combat events from these signals). Lastly, units in transit need periodic recalculations of the path they're following, to account for changing combat conditions. Path-update events go into the event heap. When a path is being updated, call `AStar2D.set_point_disabled()` for tiles occupied by buildings or enemy units. The kernel of the data is the pooled array of unit unique ids. Ids must be positive, so if the id is negative then that array index corresponds to a killed unit and should be skipped. Unused indices are kept for the purposes of spawning new units while keeping the arrays small in size.

Unit *objects* contain data and behavior for combat resolution (hit points, attack types, `take_damage()` methods) as well as by-unit data mentioned above, but any data relevant to physics and also tracked in the pool arrays is not kept up to date. The main purpose of position, velocity, order, path (etc.) in the unit object is for save & restore. Unit objects reference the static data singleton for static data values.
