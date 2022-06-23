# Development Process & Style Guide

* Always use branches for features in progress and rebase off of main. Submit features as pull requests. The only exception is updates to documentation, which can be done immediately on main branch.
* Game project goes within the `game/` directory.
* Main branch should always be in shape where project should run, export to all platforms, and run without major crashes. Test before committing and pushing.
* Do not track assets (png files) in the repository. This is because git's handling of binary files is subpar, but also because it enables separate licenses for assets and code.
	* Assets should be shared in a separate file sharing platform.
* Within the game project, never include "naked" text strings. Always give text a translation key and put the keys and the text in a `.csv` file. More info here: []()
	* Separate "campaign" text (unit and building names and description text) from "meta" text (button names in user interface, credits, and everything else).
* GDScript (or C#) should be used as a default for scripts. Only refactor to C++ with GDNative if it becomes necessary for performance; no premature optimization. The following are other optimizations to prefer BEFORE switching languages:
	* Reducing number of objects calling `_process()` or `_physics_process()` (Already planned with the event heap systemm)
	* Reducing use of Nodes (or Objects) in favor of lightweight data types
	* Using low-level servers instead of nodes (Use of Physics2DServer is already planned; VisualServer may be necessary if there are draw-related bottlenecks)
* Always use the optional static typing unless there is a reason not to (usually related to limits of doubling in the unit testing framework).
* Add integration tests in as soon as possible, especially when setting up the game's code structure and adding calls to empty methods. This is the main way of ensuring that the main branch is not broken.
	* Premptively writing unit tests is largely a waste of time during a game jam, but can be used as a tool on demand for debugging when something is broken and the debugger doesn't tell you why.
	* Unit tests might be ok to get guarantees of the quality of fiddly data-driven code which is less readable than object oriented, too, since a bunch of values in an array is less comprehensible in the debugger than variable names.

