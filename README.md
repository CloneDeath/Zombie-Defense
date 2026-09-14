# Last Line

A responsive, browser-first zombie defense roguelite prototype made with Godot 4.

Survivors automatically defend the line, gain XP, level up, and can die permanently for the current run. Retreating heals surviving defenders and moves the fight to the next map, but every zombie still in the wave—and every zombie that already leaked through—follows you.

## Run locally

Open `project.godot` in Godot 4.3 or newer and run the project.

## Controls

- **Mouse/touch:** use the on-screen buttons
- **R:** retreat
- **Space:** rally the survivors (temporary fire-rate boost)
- **Enter:** start a new run after defeat or victory

## Assets

Visuals in this first proof of concept are intentionally lightweight and generated in code. The project is prepared to adopt Kenney's [Top-down Shooter](https://kenney.nl/assets/top-down-shooter) CC0 art as the visual direction.

## Web deployment

Every push to `main` builds the Godot Web export and deploys it to GitHub Pages. Enable **Settings → Pages → Source → GitHub Actions** once if Pages is not already enabled.
