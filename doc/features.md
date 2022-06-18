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
	* When the facility's timer is then up, the unit spawns as the purified variant, ready to be commanded.
* Slow, random unit income in addition to capture mechanism
	* This is where the starter units come from
	* Units spawn at the edge of the map with an order to approach the nearest command center (which for the player is the decontamination facility)
	* The player does not select the unit type; the unit type is random. The challenge of the game is to figure out how to best make use of the unit types given.
* Unit types based off of animals (non-anthropomorphic)
	* Wild or purified units (player faction) appear like real wildlife
	* Evil units are variants of the same unit type
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
* 
