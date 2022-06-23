# Art Style and Pipeline

The graphics will be pixel isometric (2:1 width:height ratio of tiles) at a 64x32 size for ground tiles. Sprites for units and other objects can be a variable size so long as the center bottom of them fit on the 64x32 base.

Rather than doing straight up pixel art, sprite sheets pre-rendered from 3D models will be used. While this is more work up front, it allows the four different views of a unit (front, behind, diagonal up, diagonal down, left/right) to be based on consistent form and animation timing, and updates to the model and animation can be immediately reflected in all views, which should result in less work overall. In order for the sprites to be mirrored horizontally, top-down lighting with no directional component has to be used before rendering.

Indexing with dithering will be used, alongside a pre-chosen color palette, to force a consistent visual look. If any outside models are used for background objects, some re-texturing along with this method will ensure that those match custom assets created for this project.

Here is the asset process for creatures/units:

1. Concept drawing of the creature demonstrate an idea (no particular view enforced) (Tool used: physical pencil & paper, or Krita)
2. Orthographic drawings of the creature from the following views: front, side, top. This defines the form and allows for the model to match. (Tool used: Krita) New drawings of the different faction variants of each unit should be produced with individual details, but large-scale proportions should conform.
3. 3D models conforming to the orthographic views. As animations will be rendered to sprites, there is no poly count limit, so sculpting can be used if desired (so long as it will not complicate weight-painting). However, details not readable at a small size should be avoided. (Tool used: Blender)
4. Rig the model along its skeleton. Since units will have 3-5 variants, they should use the same skeleton. (Tool used: Blender)
5. Texture the different variants of the unit (this can be done any time after modeling and before rendering). (Tool used: Blender)
6. Create movement and attack animations for the unit. (Tool used: Blender)
7. Setup lighting for render and render the animations to a small size. Further processing afterwards to have the image sequence match a color palette, and/or lay out the sequence into a sprite sheet, can be used as well. (Blender and FFMpeg)

Asset process for static objects can be greatly simplified. They can be rendered to sprites from 3D models just the same, without a concept art or animation component, or directly sprited in 2D.

When texturing, setting up lighting for a render, the chosen indexed color palette should be taken into account and attempts should be made to match it, as to make the end processing step produce better results. Outside 3D model assets should be retextured, or, at least, have the lighting modified to produce results consistent with the look of the rest of the assets.

