# Features, in no particular order

* Single player run-based game
	* "Run" as in a roguelike run, where the player has one save file at a time and they can either win or lose the run. This is analagous to a PVP "match" in which the factions are vying for mutually exclusive goals.
	* There is no metaprogression, unlocks, or other influence between runs.
	* Difficulty settings would be a nice stretch goal.
* Unit capture as the primary way of getting more units
	* Capture-attack as an alternative to attack as an order
	* Units making a capture attack do less damage than a lethal attack
	* Enemies must fall under a certain health threshold from a capture-attack without being outright killed to be captured.
	* When a unit despawns after a successful capture attack, it is sent to the queue of the nearest decontamination facility.
		* If all facilities have full visible queues, the unit is sent to an invisible queue, to be added later to an actual queue when a space opens up.
		* Note that capturing many units takes up space which could be used to heal units, and vice versa.
		* Capture mechanics are intended to reward skillful micro.
	* When the facility's timer is then up, the unit spawns as the purified variant, ready to be commanded.
* Slow, random unit income in addition to capture mechanism
	* This is where the starter units come from
	* Units spawn at the edge of the map with an order to approach the nearest command center (which for the player is the decontamination facility)
	* The player does not select the unit type; the unit type is random. The challenge of the game is to figure out how to best make use of the unit types given.
* Evil factions can build buildings that build units. This is something the player cannot do. Evil factions will grow in size quickly if not dealt with.
	* This is balanced by evil factions only being able to build buildings on their evil tile type. Evil tiles spread slowly to pure tiles.
	* Pure faction has no tile-based building restrictions. Decontamination facilities immediately turn tiles underneath them pure, stops spread of evil within range, and slowly re-converts evil tiles within range to pure.
	* Decontamination flags are small buildings that can be built in range of facilities, and essentially extend the decontamination effects of the facility.
* Unit types based off of animals (non-anthropomorphic)
	* Wild or purified units (player faction) appear like real wildlife
	* Evil units are recolors and variants of the same animal species
	* Different evil factions give a different appearance modifier and different starting bonuses
	* Unit upgrades are faction specific (some can only be attained on player units by capturing the upgraded unit and then purifying it)
* Tile-based isometric map with sprites pre-rendered from 3D
	* The tiles themselves are either pure or evil. The evil variant is a recolor with a sinister style.
	* The various evils have different color schemes and themes
		* "The Decay" is dark and purple, and its units often incorporate elements of mist or dark gaseous cloak. Forms are slightly more geometric with sharp edges. Its aesthetic is more of a fantasy evil.
		* "The Pestilence" has contrast between pale yellow, black sores, and bright, toxic green. Its units often incorporate elements of rashes, boils, or fungal growth. Its aesthetic is meant to evoke disease.
		* "The Sanguine" has a color palette of bone white and fleshy red. Its units often incorporate elements of bone, gore, and flayed sinew. It is meant to evoke injury.
		* "The Artifice" has a color palette of metallic grays, black iron, and blinky red/yellow/green/blue lights. Its units have cyborg parts or are fully robotic.
* Asymmetry between the factions
	* Evil units are slightly stronger than pure units
	* Evil factions have higher base resource income and can build more units directly in addition to having units come in from the map corner (at a faster rate than they do for the player)
	* Evil factions have more functional buildings, especially buildings with a defensive or economic purpose
	* Evil units are permanently removed when they fall from combat (or permanently join the purified faction on capture), whereas purified units will respawn at 25% health at their map corner after a timer elapses
	* Pure units can capture-attack, evil units can only true-attack. The pure faction cannot lose units (though it can lose quite a bit of time to respawning them)
	* The pure faction can only build decontamination facilities and decontamination flags
	* Evil buildings can only be built on evil tiles, whereas decontamination facilities can be built on pure or evil tiles.
	* Evil tiles will convert surrounding pure tiles to evil over time, with the exception of tiles within range of a decontamination facility/flag. Decontamination facilities/flags purify tiles in range over time.
	* The various evils have damage bonuses and penalties against each other. The Pestilence as a whole is strong against The Sanguine, which is weak against it. The Sanguine is strong against The Decay, which is weak against it. The Decay is strong against The Artifice, which is weak against it. Lastly, The Artifice is strong against The Sanguine, which is weak against it.
	* Evil tiles also have the ability to convert evil tiles of the type it is strong against to its own type.
	* Opposite pairs Pestilence and Decay have unit-specific bonuses and penalties against each other but otherwise have an even match-up. The same applies to the opposing pair Sanguine and Artifice. These paired evils cannot convert each other's tiles.
	* Two game modes: One is purity (player) against just one evil, and another is purity against two AI-controlled evils at once. While the player has a numbers disadvantage in the melee a trois scenario, the player may be able to benefit from the conflict between the evils.
	* During the jam period, only the single-evil mode will be implemented and only one evil faction as well
	* When the player is against a pair of evils with a neutral matchup, the evil-vs-evil conflict is expected to be long and drawn out. The player can either easily eliminate the faction they would rather fight now than later and prepare for fight against the other evil; alternatively the player may box one evil into its corner, letting the other evil expand and cut it off, then have an easier time eliminating the expansive evil next because the expanded evil will not be able to use the boxed-in evil's territory.
	* When one evil hard-counters the other evil in the melee a trois map, the player can expect the weaker evil to be eliminated, and must priorize capturing its units while there is still a chance while preparing to take on the conquering evil.
* Victory and loss
	* The game is won when all evil buildings have been destroyed
	* The game is lost when all tiles have become evil (type of evil is not checked, there must be 0 pure tiles left for the player to lose)
* Resources
	* There is a primary resource which acts like a currency that can buy most things. This includes all unit upgrades, all buildings for the evil factions, and for player decontamination flags. Facilities require both the primary resource and a special resource.
	* For the player, the primary resource is called "leaves". For the evil, the primary resource is internally called "Gold" but is never visible to the player.
	* The other resource, for the player only, are "forest hearts", which can be claimed from their spawn points, marked by a tile sprite which shows a blue glowing orb embedded in the ground (the tile switches back to a normal pure tile when claimed). One is required for each decontamination facility. When in the ground, they can be permanently lost if an evil tile converts the tile they spawned on to evil. But, once the player claims them, it cannot be lost for the rest of the run; if a decontamination facility is destroyed by the evil, the Forest Heart is immediately refunded. Only the Heart is refunded, the Leaves used to build it are still gone.
	* Factions gain Gold or Leaves slowly over time (like a MOBA), but the rate at which they go up can be increased by various milestones. Each Forest Heart claimed is a milestone which contributes to Leaf income, and every tile which has ever been in range of a decontamination facility or flag contributes to another milestone count as well (the tile is still flagged even if the building is destroyed). For evil factions' Gold, the milestones are instead based on their total buildings built count. These income rates do not decrease, allowing for swingy investments late in the run.
* Units each have two upgrade options. A unit can only be upgraded once (the upgrades are mutually exclusive). Upgrades are irreversible. The upgrades cost currency (gold or leaves). The effects of the options are thus:
	* Squirrel (basic attack is melee, small and low hp/attack power but has some melee resistance)
		* Digging claws: Additional damage to buildings.
		* Iron teeth: Additional damage to units.
	* Frog (basic attack is ranged, small and low hp/attack power)
		* Bullet Tongue: Additional range. 
		* Tongue Shiv: Additional damage to units.
	* Wolf (basic attack is melee, large and high attack power and has some melee resistance)
		* Lightning Paws: Additional resistance to melee and additional damage to buildings
		* Fang Plate: Additional resistance to ranged damage and additional damage to units
	* Tortoise (basic attack is melee, low damage output but significant resistance to melee and ranged damage, low speed)
		* Fortress Carapace: Additional resistance to melee and ranged, additional damage to buildings
		* Terrapin Ballista: Damage is now ranged but melee/ranged resistance is reduced
	* Owl (flying unit, basic attack is melee)
		* Feather Missles: Damage is now ranged but now weak to ranged damage
		* Digging Talons: Additional building damage
	* Swarm of Bees (flying unit, basic attack is melee, highly resistant to melee but highly weak to ranged)
		* Stinger Bullets: Damage is now ranged
		* Swarm Capture: Additional unit capture damage, and capture attack now cannot kill units (reducing enemy hp to 0 in a capture attack now captures the unit instead of killing it)
			* This upgrade might do something significantly different for evil factions instead of having minor stat variations or additional effects, because evil factions cannot capture.
			* This is also the only upgrade used during a capture attack. Other units will revert to their non-upgraded basic attack type for capture attacks.
* Upgrades have different stats for each faction (as usual, evil faction upgrades are slightly better than the pure faction). However, if a unit is captured and purified, the faction of its upgrade is persisted.
* If PVP is ever considered (low priority, not during the jam) it will be the only mode in which evil factions are playable, and PvP will always be evil-versus-evil and evil-specific counters (bonuses, penalties) are nullified for this mode.

