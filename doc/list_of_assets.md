# List of Assets

Remember: it's a game jam, quality does not matter, be willing to say "good enough" and move onto the next one. There is also no shame in finding something premade in a pinch.

## Visual

### Pre-production/Production Art

* Concept Art
	* HUD concept art
	* Squirrel upgrades 1 & 2
	* Frog upgrades 1 & 2
	* Wolf upgrades 1 & 2
	* Owl upgrades 1 & 2
	* Tortoise upgrades 1 & 2
	* Bees upgrades 1 & 2
	* Decay faction alternates of all units
	* Pestilent faction alternates of all units
	* Sanguine faction alternates of all units
	* Artifice faction alternates of all units
* Orthographic Views of Units
	* 1 layered image for each species (aside from swarm of bees) to set up the rig
	* draw variant features for different factions & upgrades on different layers
* Models of Units
	* 1 model file per species containing models for all of the variants; different faction variants can go into different objects in the same file (only one visible at a time per render)
	* 1 rig per species which all variants should be weight painted to
	* Textures for all model variants
	* Animations: idle, move, attack, death


### Baked Unit Sprite Sheets

* Sprite sheets including animations for: idle, move, attack, death
* 5 (species) x 3 (unupgraded + 2 upgrade options) x 5 (factions) x 5 (front, left-front, left, left-back, and back views) = 375 sprite sheets overall

Don't export the models manually, use a tool to render!

### Hand sprited sprite sheets

Swarms of bees should be hand-sprited due to the tininess of bees. If necessary only 1 view can be done to cut this in half.

* 1 (species) x 3 x 5 x 2 (only left-front and left-back) = 30 swarm-of-bees sprite sheets


### Static Isometric Sprites (2D-only pipeline)

* Purity building: Decontamination facility
* Purity building: Decontamination flag
* Decay building: economic building
* Decay building: basic unit maker building
* Decay building: midline economy building
* Decay building: upgraded unit maker building
* Pestilent building: economic building
* Pestilent building: basic unit maker building
* Pestilent building: midline economy building
* Pestilent building: upgraded unit maker building
* Sanguine building: economic building
* Sanguine building: basic unit maker building
* Sanguine building: midline economy building
* Sanguine building: upgraded unit maker building
* Artifice building: economic building
* Artifice building: basic unit maker building
* Artifice building: midline economy building
* Artifice building: upgraded unit maker building

Ground tiles

* Isometric ground tile with 2-3 base variants, x4 recolors for evil factions
* Tiles with various border configurations of evil/purity overlap for autotiling

Sprite sheet of background objects (includes 4x recolors for evil factions):

* 3-4 tree types
* 4-5 bush types
* 4-5 other small plants
* 4-5 rock types


### User Interface

* Title logo
* Title screen background
* Button 9patch
* HUD backdrop and decorations

## Audio

### BGM

As the subject matter is animals/nature, orchestral (Romantic period esque) music is desired here.

* Title screen theme
* Map/combat theme

### Sound Effects

* Forest Heart picked up notification
* Forest Heart lost notification
* Unit joined notification
	* Squirrels
	* Frogs
	* Wolf
	* Tortoise
	* Owl
	* Bees
* Unit attack effects
	* Squirrels
	* Frogs
	* Wolf
	* Tortoise
	* Owl
	* Bees
* Unit deaths
	* Squirrels
	* Frogs
	* Wolf
	* Tortoise
	* Owl
	* Bees
* Building destroyed
* Unit purification complete notification
* Unit respawned notification
* Victory fanfare
* Game over fanfare
* Interface select
* Interface cancel

