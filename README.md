NPC Movement System for Godot without NavMesh ------------------

This script provides a complete NPC movement system for 3D games in Godot. It allows an NPC to idle, wander, and chase a player with smooth movement, dynamic speed, and obstacle avoidance. The system relies on physics and raycasts instead of navigation meshes, making it lightweight and efficient.

Features ------------------

Health management with a visible 3D health bar
Wandering with random directions and configurable timers
Player detection and chase behavior with follow distance and maximum chase range
Strafe movement during chase for natural motion
Smooth rotation toward movement direction
Obstacle detection and avoidance using raycasts
Gravity application for realistic vertical movement
Configurable movement speeds, acceleration, deceleration, and turn speed

Setup ------------------

Assign the NPC script to a CharacterBody3D node.
Add the following child nodes for proper functionality

A front RayCast3D to detect obstacles

Left and right RayCast3D for obstacle avoidance

A ground RayCast3D to prevent falling off edges

Optional Health3D node with a SubViewport containing an HPBar and Label

Set the exported variables in the inspector to adjust movement speed, detection ranges, gravity, and chase parameters.

How it works ------------------

The NPC has three states: idle, wander, and chase. In idle state, the NPC stops moving and checks for player proximity. In wander state, the NPC moves in a random direction for a random duration while checking for obstacles and edges. In chase state, the NPC moves toward the player with adjustable speed, strafing behavior, and collision avoidance.

Health can be reduced using the _get_damage(damage) function. If health reaches zero, the NPC is removed from the scene.

The NPC rotation is smoothed using _smooth_look, which interpolates the rotation toward the target direction based on movement speed.

Obstacle avoidance checks the left and right rays and adjusts movement to prevent collisions.

The _physics_process loop handles movement and state updates, applying gravity, and controlling speed with acceleration and deceleration.

Usage ------------------

Call set_target(node) to assign the player or any other object as the chase target.
Use the exposed variables to fine-tune behavior such as wandering time, chase speed, and detection range.

This system can be used for enemies, allies, or NPCs that need dynamic movement without the overhead of navigation meshes.
