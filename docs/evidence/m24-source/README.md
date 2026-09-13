# Red Sea Baron

A playable Godot 4.7 action-RPG blockout in a 320 × 320 m Mediterranean coastal region. The reference images guide the red transforming motorcycle, warm village, farms and limestone cliffs. Geometry and animation are placeholders; this is an evolving vertical slice, not the completed 25 km world.

Open `project.godot` in Godot 4.7 and press F5, or run:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

For Web, run `tools/serve.sh` and open [the local game](http://127.0.0.1:8067/). The server must remain running. The build uses the Compatibility renderer, WebGL 2, matching Godot 4.7 templates and a single thread, with no external asset services.

## Controls and places

| Input | Action |
|---|---|
| WASD / arrows | Move; steer/throttle while riding |
| Shift | Sprint; reverse cargo/station action when held |
| Space | Jump; bike brake; aircraft takeoff/climb |
| Q / Ctrl | Dodge; descend while flying |
| Right drag / IJKL / wheel | Orbit / keyboard camera / zoom |
| 1 / 2 | Wrench / rifle |
| F or left click / G | Attack / heavy wrench attack |
| Alt / Tab / R | Aim / lock target / reload |
| E | Survey station or mount/dismount nearby bike |
| T | Deploy/fold wings on clear ground below 29 km/h |
| C | Hitch/detach nearby cart while stopped in bike mode |
| V / Shift+V | Load backpack into nearby cart / unload |
| U / Shift+U | Gather, deposit, trade, accept/deliver / withdraw or buy an olive |
| O at courier | Choose south quay or Longfield before accepting a parcel |
| B / P | Cargo and trade readout / buy rifle rounds at market |
| N | Worker orders; 0 harvest/sell routine, 3 ore, 4 olives, 5 courier, 6 market, 7 timber, 8 retry, 9 recall |
| M / Esc | Map / pause |
| H | Recover at checkpoint; recover bike and attached cargo while riding |
| F6 / F8 | Save / load while stopped and grounded |
| F9 | Traversal verifier |

Native play captures the mouse. Web uses right-drag/IJKL because the embedded browser rejected pointer lock.

The motorcycle and cart start at the workshop, east of the village center. Deploy wings, accelerate above 44 km/h, then hold Space to take off. Land and slow down before folding. Detach the ground cart before flight.

Use U at the courier desk near the workshop to accept a parcel. A nearby cart receives it; otherwise it goes into your backpack. Carry it to the south quay (39, 67) and press U while stopped to deliver for 75 crowns. B shows its status. Use C for the hitch and V to move backpack contents into the cart. After completing a delivery, Shift+U at the courier desk issues another parcel.

O at the courier selects Longfield waystation (900, 1116), paying 180 crowns. Its destination stays fixed after acceptance. For an air delivery, use Shift+V to unload the parcel into your pack and C to detach the cart before deploying wings. Fly southeast, land in clear terrain, fold, then ride to the desk south of the waystation. The map highlights your active delivery destination. Mara's courier job still uses the local south quay.

Olives are at the northwest farm (-48, -48), ore east of town (61, 29), and timber southwest (-27, 53). The warehouse is (-9, 8); the market is (-13, 1). Resources are finite; an exhausted orchard regrows after 15 seconds. Sold goods enter market stock. Buying costs twice their selling value. Mara starts by the warehouse; N opens her work orders. Press 0 to repeat harvesting and selling autonomously. Press 0 again to finish the current job and stop; blocked jobs retain cargo and can be retried with 8. Saves preserve routine progress, including a stopped job that is still finishing.

Hostiles are west of town. P at the market buys five rifle rounds for 12 crowns and consumes one stocked ore. Selling gathered ore replenishes this supply; reserve capacity is 100. Surveys establish recovery points. F6 saves a stopped, grounded session; F8 or the menu’s Load button restores it. Save data includes inventories, vehicles, contracts, enemy health, surveys and Mara’s active job. Web saves use browser storage, so clearing site data removes them.

## Verification

Each suite runs production controllers in the main scene. Isolated fixtures reposition actors; integrated routes physically travel between locations. Reports include explicit pass/fail results; a successful launch alone is not a pass.

```sh
tools/verify.sh
```

Select suites with `tools/verify.sh --suites combat,feedback --no-export`; add `--long` for the roughly twelve-minute continuous flight test. Native flags follow `--`: `--verify` for traversal, or `--verify-SUITE`. Suites include combat, bike, flight, cart, logistics, worker, world, save, ui, integration, feedback, ai, economy, highland, region, recovery, encounter, routine, routine_stop, backdrop, routes, airmail and cargo_access. Web uses `?verify=SUITE`, with `?verify=1` for traversal. A report appears as visible page text after completion. Leave controls idle during automated verification; reload the normal URL afterwards.

Rendered native runs accept `--capture` to save evidence at actual gameplay checkpoints. Headless runs cannot benchmark rendering. Evidence, failing attempts, current rubric scores and acceptance results live in `docs/GAUNTLET_PROGRESS.md` and `docs/evidence/`.

Native and Web evidence includes traversal, both weapons, driving and transformation, loaded cargo, worker contention, persistence across a browser reload, maps and a continuous 23.95 km flight. Each report identifies its exact assertions and platform. Consult the progress log for current regressions and pending acceptance; old passes do not automatically certify later changes.

The outer world streams a bounded 5 × 5 terrain window across a 25 km square domain. The authored core deactivates at distance; worker jobs continue in coarse simulation. Outer regions contain instanced woodland, dryland, grassland and highland scenery, with four discoverable landmarks. Red Mesa and Snowwatch have nearby hostile encounters whose health/deaths persist when the region retires. Most of the world is still procedural blockout scenery. Broad hardware testing, richer regional content and final art remain open. See `docs/ARCHITECTURE.md` for the current interfaces and `docs/PROJECT_BRIEF.txt` for the complete request.

The world map marks Greenreach timber camp (-3600, 700), Red Mesa quarry (4800, 1200), Snowwatch tower (-1060, -10000), and Longfield waystation (900, 1100). Close approaches record discoveries without changing your survey checkpoint. Red rings indicate hostile areas.
