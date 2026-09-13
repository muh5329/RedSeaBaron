# Red Sea Baron — gauntlet progress

Latest update: 2026-09-12. Original work began 2026-09-11 local.

## Current status

Milestones 01–62 have recorded native/Web acceptance, with targeted checks for changes after the M48 fixed-source checkpoint. M40 passed 529 assertions including continuous long flight; M48 passed 585 assertions across 40 default suites with all 259 source hashes unchanged. Current systems include traversal, melee/rifle combat, transforming flight bike, cargo cart, worker jobs/routines, regional deliveries, economy, validated saves, bounded 25 km terrain streaming, regional landmarks/encounters, coastal/inland water safety and equipment tracking.

M56 passed its fixed 285-file /647-assertion checkpoint; M58 adds a verified quarry gallery and ore reserve; M59 has verified collision during wing motion; M60 rear assembly and M61 worker map tracking are accepted; M62 adds an accepted brook crossing; M63 runs the fixed full-source checkpoint and M64 reviews cliff geometry. Current conservative rubric average remains 7.85/10: vehicles are kinematic and the world is still sparse blockout scenery. Counts establish regression coverage, not final game quality. The user's continuing instruction supersedes the original per-milestone stopping rule.

Run `tools/serve.sh` for the local Web build at http://127.0.0.1:8067/. See README.md for controls and ARCHITECTURE.md for interfaces. Historical rounds and failures follow; the newest evidence is at the end of this file.

## Initial status (milestone 01)

**Milestone 01 — project foundation and player traversal.** The original directory contained only `.DS_Store`: no Godot project, assets, scenes, prior verifier or progress notes were present. There was consequently no existing game to run. Godot 4.7 stable and matching single-thread Web templates were already installed.

This milestone implements the brief's phases 1–2, with a small procedural region and survey interaction loop to integrate the foundations. Combat/lock-on belongs to the next milestone. It is not a completed action RPG or final vertical slice. No claim is made that the 25 km square world is implemented.

Stop condition: current milestone's native and Web verifier passes, with browser gameplay inspection and an adversarial pass. Six improvement rounds were used out of the 20-round cap. **14 rounds remain for this milestone if it is reopened.** No separate total-project iteration budget was specified.

## Round 01 — initialize a playable traversal foundation

- Objective: turn the empty workspace into an organized, Web-compatible Godot project with player movement and a test region.
- Files changed: `project.godot`, `export_presets.cfg`, `.gitignore`, `scripts/main.gd`, all initial `scripts/player/`, `scripts/world/`, `scripts/interaction/` and `scripts/ui/` files; original request copied to `docs/PROJECT_BRIEF.txt`.
- Scenes changed: created `scenes/main.tscn`; remaining scene graph is built by the composition root.
- Systems added: input actions, configurable locomotion, geometric player presentation, orbit/SpringArm camera, static terrain tiles, region landmarks, survey interaction and HUD.
- Bugs discovered: GDScript could not infer `cardinal` from a mixed array expression in the HUD; Main could not compile.
- Bugs fixed: none in this first round.
- Web export/runtime: not attempted while import failed. No success claim.
- Evidence: `evidence/import-round-01.log` records the exact parse error.
- Performance: not measured.
- Quality score: stability 0/10; remaining categories unverified.
- Failed approach: inferred type for an indexed literal array.
- Debt: procedural region layout and geometric animation are deliberate placeholders.
- Next highest-impact action: explicitly type the HUD string and run the actual scene.
- Remaining iteration budget: 19/20.

## Round 02 — resolve startup and inspect the Web canvas

- Objective: obtain clean native startup, export Web and inspect the real render.
- Files changed: `scripts/ui/game_hud.gd`, `scripts/player/player_visual.gd`; generated Web build.
- Scenes changed: behavior/render of `scenes/main.tscn` through those scripts.
- Systems modified: explicit HUD type; roll rotates around the player's center instead of through the ground.
- Bugs fixed: HUD type inference failure.
- Bugs discovered: right/bottom HUD panels were offscreen due to absolute `position` after setting anchors; lighting washed out terrain; distant rock sphere placeholders produced pointed columns and detached crown caps.
- Web export result: successful debug export; native scene printed `RSB_READY` without errors.
- Runtime evidence: `evidence/native-smoke-round-02.log`, `evidence/web-export-round-02.log`; browser canvas inspection reached the actual menu/world, not merely a loader.
- Performance: browser HUD about 120 FPS, not yet instrumented across traversal.
- Quality score: startup/Web 7; UI 4; visual readability 4. Milestone not complete.
- Failed approach: anchor-relative positioning via `Control.position`; overly bright lighting and crude spherical spires.
- Debt: no complete integration verifier yet.
- Next highest-impact action: repair visual/readability issues and implement real controller checks.
- Remaining iteration budget: 18/20.

## Round 03 — automated traversal verification and readability repairs

- Objective: measure real movement, stamina, collisions and integrated survey traversal.
- Files changed: `scripts/ui/game_hud.gd`, `scripts/world/coastal_region.gd`, `tests/traversal_verifier.gd`.
- Scenes changed: same main scene; added in-game verifier node at runtime.
- Systems modified: offset-based HUD placement, restrained lighting, faceted rock meshes, ASCII-safe UI symbols, full deterministic input runner.
- Bugs fixed: offscreen panels, overexposed terrain, detached cliff caps.
- Bugs discovered: verifier attempted inferred typing for a dynamically referenced SpringArm's `get_hit_length()` result, so its script failed to compile.
- Web export: Godot produced an export despite the dependent-script compile failure. This was correctly treated as failed verification; a zero export exit status alone is insufficient.
- Runtime evidence: `evidence/native-verifier-round-03.log`, `evidence/web-export-round-03.log`.
- Performance: not scored for this failed candidate.
- Quality score: UI/readability provisionally 7; verifier/stability 0 for this candidate.
- Failed approach: untyped dynamic test reference; relying only on export exit status would have missed it.
- Debt: verification driver couples intentionally to the composition root; fixtures use teleportation for setup.
- Next highest-impact action: explicit float type, then native and Web runs.
- Remaining iteration budget: 17/20.

## Round 04 — pass 21 checks natively and in Web

- Objective: prove traversal, input gating, camera obstruction and the full three-station route.
- Files changed: `tests/traversal_verifier.gd`; rebuilt Web export.
- Scenes changed: same main scene and runtime test runner.
- Systems modified: explicit type for camera hit distance.
- Bugs fixed: verifier compile failure.
- Bugs discovered: embedded Chromium rejected pointer-lock requests with `UnknownError: If you see this error we have a bug. Please report this bug to chromium.` Gameplay continued through right-drag/keyboard alternatives, but console acceptance was not clean.
- Web result: all 21 controller/route assertions passed; not accepted as the final build because of the pointer-lock error.
- Evidence: `evidence/native-verifier-round-04.log`, `evidence/web-report-round-04.json`, `evidence/web-console-round-04.json`.
- Manual browser evidence: visible Begin button entered gameplay; physical Q input displayed DODGE and reduced stamina to 73.
- Performance: Web median 120 FPS during the ~60-second traversal suite, 806 nodes, 679 draw calls in the sampled frame. Headless native FPS is not a graphics benchmark.
- Quality score: movement 8; camera 7 (Web input issue); UI 8; Web compatibility 6 due to console error.
- Failed approach: pointer capture on embedded Chromium. No attempt was made to change browser security settings.
- Debt: no scaling benchmark beyond the resident blockout; architecture/shadow draw calls need reduction before expansion.
- Next highest-impact action: default Web to right-drag/IJKL and rerun the complete suite.
- Remaining iteration budget: 16/20.

## Round 05 — Web camera fallback, final verification and handoff

- Objective: finish the milestone with clean native/Web results and a reproducible handoff.
- Files changed: `scripts/main.gd`, `scripts/ui/game_hud.gd`, `tools/verify.sh`, `tools/serve.sh`, `README.md`, `docs/ARCHITECTURE.md`, this file, and evidence artifacts.
- Scenes changed: `scenes/main.tscn` behavior through Main/HUD; no new gameplay scene.
- Systems modified: Web mouse remains visible with right-drag/IJKL camera; native retains captured mouse. Verification script rejects script/runtime errors in logs even if Godot exits zero.
- Bugs fixed: embedded browser pointer-lock errors removed at the application level.
- Failed approaches: none added.
- Native result: final `tools/verify.sh` passed 21/21 in 59.6 s, then exported Web successfully. A separate rendered native run initialized Compatibility/OpenGL on the Apple M4 Pro and reached the main game with no errors.
- Web result: final browser run passed 21/21 checks in 59.8 s, with no errors or warnings after final reload. Median 120 FPS, 806 nodes, sampled 679 draw calls. Gameplay reached the region and completed all three route interactions.
- Evidence: `evidence/import.log`, `evidence/native-verifier.log`, `evidence/native-report.json`, `evidence/web-export.log`, `evidence/native-rendered-round-05.log`, final browser report/logs/screenshots.
- Technical debt: explicit limits remain in `ARCHITECTURE.md`; no new gameplay debt hidden as completed features.
- Next highest-impact action: implement and verify the combat milestone before vehicle or world expansion work.
- Remaining iteration budget: 15/20.

## Round 06 — close the manual keyboard verification gap

- Objective: correct a real browser input failure discovered after the automated suite passed.
- Files changed: `scripts/main.gd`, `tests/traversal_verifier.gd`, `scripts/ui/game_hud.gd` (map legend glyphs), handoff documentation and evidence.
- Scenes changed: main scene's global input routing.
- Bug discovered: M did not open the map through browser keyboard input, although invoking the map handler worked. GUI event handling prevented the shortcut reaching `_unhandled_input`.
- Bug fixed: global shortcuts now use `_input`, reject echo events and retain verification/menu state gates. The map test now dispatches actual `InputEventKey` press/release events instead of invoking the handler directly.
- Runtime evidence: manual browser M now opens the field map and a second M closes it; `RSB_UI` logs confirm both transitions. `evidence/web-map.jpg` captures the open map. Final native/Web assertions and logs are saved to the standard evidence paths.
- Web export result: successful. The final native suite passed 21/21 in 59.7 s and Web passed 21/21 in 59.9 s with no errors or warnings. Median Web 120 FPS; 806 nodes; sampled 679 draw calls. Manual M open/close and Esc pause checks also passed.
- Performance observation: no world/renderer changes; same region and batching.
- Quality score: the completed milestone scores 8.0/10 across its eight critical categories; none below 7. This does not score the unimplemented full RPG as complete.
- Failed approach: handler-only map test was insufficient; retained as a documented test-coverage lesson.
- Technical debt: physical browser input coverage still complements rather than completely duplicates the synthetic action suite.
- Next highest-impact action: proceed to the combat milestone. This round satisfies the current-milestone stop condition.
- Remaining iteration budget: 14/20.

## Current rubric

Scores are engineering assessments of the implemented scope, not external ratings. Unimplemented categories are recorded as 0; they are not silently counted as passing. The milestone-critical average is 8.0/10. This is not the average or completion score of the final requested RPG.

| Category | Score / 10 | Evidence / limit |
| --- | ---: | --- |
| Player movement | 8 | Measured walk/sprint, normalized diagonal, jump/land, stamina, dodge, collision, sloped integrated route. No controller or touch testing. |
| Camera | 8 | Camera-relative direction; arm contracts 6.20 → 2.88 m at wall and recovers; Web drag/keyboard fallback. |
| Melee combat | 0 | Not implemented. |
| Rifle combat | 0 | Not implemented. |
| Enemy AI | 0 | Not implemented. |
| Bike handling | 0 | Not implemented. |
| Flight handling | 0 | Not implemented. |
| Vehicle transformation | 0 | Not implemented. |
| Cargo/cart physics | 0 | Not implemented. |
| Worker automation | 0 | Not implemented. |
| Job architecture | 0 | Not implemented. Survey stations are not worker jobs. |
| Resource/logistics loop | 0 | Not implemented. Survey stamps are not economy resources. |
| Economy | 0 | Not implemented. |
| Open-world architecture | 3 | 100 independent resident terrain tiles, bounded recovery; no streaming proof. Not critical to this foundation milestone. |
| Visual readability | 7 | Clear geometric player, road, landmarks and map; placeholder art with some collisionless scenery. |
| UI clarity | 8 | Controls, stamina, state, nearby prompt, route stamps, map and pause. |
| Web compatibility | 9 | Single-thread Compatibility export; actual playable browser verification. Only one browser/device tested. |
| Performance | 8 | ~120 FPS Web median on test Mac; high draw calls limit extrapolation. |
| Code modularity | 8 | Separate player/config/presentation, camera, interactions, region, HUD and verifier. Procedural region needs subdivision later. |
| Stability | 8 | 21 deterministic tests, error-free final startup, full traversal loop; not extended soak testing. |

Milestone-critical categories: movement, camera, visual readability, UI, Web, performance, modularity and stability. Every one must be at least 7. Combat, vehicles, workers, economy and streaming remain future milestones with their own gates.

## Adversarial checks and remaining limitations

Tested simultaneous/repeated jump+dodge, zero/low stamina, sprint exhaustion, sprinting into a wall, rolling into a wall, camera beside a wall, moving/acting while paused, opening/closing map, out-of-bounds recovery, repeating interactions and attempting to interact from far away. The integrated route physically crosses sloped terrain and completes three interactions; maximum grounded discrepancy from the analytic height function was 0.057 m (the rendered/collision terrain is piecewise triangulated).

Not tested because the systems do not exist: firing during mount, transforming with cart, worker resource contention, save/reload with cargo, region unload with jobs. No claim is made for those integration cases.

Known debt: procedural blockout layout; all tiles resident and generated synchronously; no worker navigation/streaming/save system; geometric animation; some collisionless scenery; high draw calls; one desktop/browser performance sample. See `ARCHITECTURE.md` for precise boundaries.

## Exact handoff files

- `project.godot`, `export_presets.cfg`: startup, renderer, collision layers and Web export.
- `scenes/main.tscn`, `scripts/main.gd`: composition, lifecycle, pause and input routing.
- `scripts/player/player_controller.gd`: movement, stamina, jump/dodge, recovery.
- `scripts/player/movement_config.gd`: reusable movement Resource.
- `scripts/player/orbit_camera.gd`: camera and collision probe; future aim/vehicle follow target.
- `scripts/player/player_visual.gd`: replaceable placeholder animation.
- `scripts/interaction/interaction_controller.gd`, `scripts/interaction/survey_site.gd`: interaction and signal examples.
- `scripts/ui/game_hud.gd`: current HUD/map; future combat UI extension point.
- `scripts/world/coastal_region.gd`, `scripts/world/blockout_kit.gd`: current terrain, environment and test wall.
- `tests/traversal_verifier.gd`: regression suite to preserve while adding combat.
- `tools/verify.sh`, `tools/serve.sh`: repeatable native/export and local Web pipeline.
- `docs/ARCHITECTURE.md`: next milestone breakdown and world expansion boundaries.
- `docs/PROJECT_BRIEF.txt`: full original acceptance criteria.

## Accepted final evidence

- `evidence/native-report.json`: 21/21, native headless, final keyboard regression included.
- `evidence/web-report.json`: 21/21, Web, 59.942 seconds, median 120 FPS.
- `evidence/web-console-final.json`: final run only, no errors or warnings.
- `evidence/web-verifier.jpg`: actual browser-rendered verifier report.
- `evidence/web-route.jpg`: route completion and dodge motion during the suite.
- `evidence/web-map.jpg`: keyboard-opened field map.
- `evidence/web-gameplay.jpg`: normal game canvas.
- `evidence/build-manifest.json`: source and export SHA-256 hashes for reproducibility.

No failing assertions or runtime errors remain in the accepted milestone. All deferred systems and technical limits above remain outstanding.

# Continued gauntlet — authorization updated 2026-09-12

The user requested continuation through all milestones with adversarial self-critique until told to stop. Passing a milestone now triggers advancement rather than a final handoff. Original safety boundaries and honest verification requirements remain in force.

## Milestone 02 / round 01 — combat implementation

- Objective: integrated wrench/rifle, lock-on, human and monster combat AI.
- Files/scenes: new `scripts/combat/{health_component,damage_system,weapon_config,player_combat}.gd`, `scripts/ai/{state_machine,combat_brain,enemy_actor}.gd`, `tests/combat_verifier.gd`; updates to Main, player/controller input and HUD. Existing main scene remains the composition root.
- Systems: faction/death-aware health; per-swing target registry; light/heavy/combo stamina costs; hitscan with camera ray and muzzle-cover obstruction; finite magazine/reserve, timed atomic reload; recoil/flash/tracer; lock validity; death/recovery; 10 Hz enemy decisions, reduced distant decisions; Idle/Pursue/Attack/Hit/Return/Dead states.
- Native/Web: initial 31/31 combat checks passed in both, Web console clean. Baseline native startup also clean.
- Evidence: `m02-baseline.log`, `m02-combat-native.log`, `m02-web-report-round1.json`, `m02-web-round1.jpg`, `m02-web-export.log` in `docs/evidence/`.
- Bugs prevented/fixed: point-blank cover exploit (second world ray), duplicate melee damage (per-swing registry), reload duplication on cancel (commit only at completion), dead-target lock persistence, UI click leaking into a first attack.
- Adversarial critique: handler/state tests alone do not prove physical collision or visible animation. Player still ignored enemy collision layer; dodge invulnerability lacked timing assertions; verifier did not restore selected weapon. Those block acceptance of this round.
- Quality: provisional melee/rifle/AI 7, integration/stability 6 until adversarial repairs are verified. Placeholder silhouettes and motions remain visually crude; no sound or attack-input buffering yet.
- Debt: enemy pursuit is line-of-sight based and does not path around complex architecture. No loot, respawn schedule or ammunition purchases until economy integration. Combat state is separate from movement but needs explicit vehicle control ownership in the next milestone.
- Next action: verify enemy-body blocking, finite dodge immunity, visible windup, state restoration, and traversal regression.
- Remaining round budget: 19/20 for combat.

## Milestone 02 / round 02 — adversarial regression

- Objective: address the first review's concrete gaps before advancing.
- Changed: player world/enemy collision mask, stronger combat verifier, combat-verifier menu entry, compact controls menu, verification pipeline.
- Added checks: player cannot walk through an enemy; dodge rejects damage during its window and accepts it after expiry; actual visible arm displacement during wrench windup. Verifier restores weapon selection.
- Native traversal regression: 21/21 after combat integration. Final combat/Web rerun in progress; acceptance will be recorded below.
- Failed approaches: visibility of a weapon and a swing counter were insufficient evidence of animation; the assertion now observes arm rotation.
- Performance: no full-frame AI added beyond the small actor set; decisions are throttled. No new large-world claim.
- Technical debt: input buffering and more sophisticated navigation remain later polish/integration work.
- Next action: finish current verifier, visually inspect combat, then begin bike control/seat ownership.
- Remaining round budget: 18/20 for combat.

Milestone 02 round 02 acceptance: 34/34 native (31.618 s), 34/34 Web (31.796 s), clean Web console, plus 21/21 native traversal regression. Stronger animation, collision and immunity assertions passed. Current scores: melee 7, rifle 8, enemy AI 7, lock/camera 8, integration/stability 8, modularity 8. These meet the current systems' minimum gates, but do not imply final polish. Exact evidence: `combat-native-report.json`, `m02-adversarial-native.log`, `combat-web-report.json`, `combat-web-console.json`, `combat-web-verified.jpg`.

The next milestone is bike mounting/driving. Flight and cargo will follow as separately verified extensions. The main adversarial risk is control ownership: mounting during a roll, combat while seated, blocked dismounts, pausing while riding, and dying while mounted must preserve a single player and vehicle.

## Milestone 03 / round 01 — grounded motorcycle and seat

- Objective: stable grounded driving with exclusive player/vehicle control transfer.
- Files/scenes: `scripts/vehicles/{bike_visual,bike_controller,vehicle_seat}.gd`, `tests/bike_verifier.gd`, Main/HUD and player collision mask. One main scene; injected seat references.
- Systems: CharacterBody3D motorcycle, red/brass placeholder bike, rider proxy, acceleration/reverse/steering/brake, visual lean without physical rollover, distance/ground/action-gated mounting, clearance-checked dismount, mounted pause and death recovery.
- Verification: 23/25 native. Acceleration reached 16 m/s and travelled 16.13 m in two seconds; both blocked-dismount tests failed. No acceptance of that candidate.
- Exact failure: enclosed capsule inside a concave box collider was not reported by an overlap query, allowing a dismount inside a wall. Follow-up dismount then failed because the rider had already left.
- Evidence: `m03-native-round1.log`.
- Adversarial critique: checking that a point is "unoccupied" is not sufficient when colliders are hollow triangle shells. Dismount must also be reachable and at compatible elevation. Seat physics now executes before player/combat, preventing same-frame fire/mount races; jump/dodge inputs explicitly reject mounting.
- Quality: bike handling 7, control transfer 7, collision/stability 5 pending correction.
- Debt: kinematic arcade handling, no wheel suspension physics. No flight/cargo yet.
- Next action: solid box colliders plus reachability/elevation checks, then all shared-system regressions.
- Remaining budget: 19/20.

## Milestone 03 / round 02 — solid collision and shared regression

- Changes: BlockoutKit boxes now use BoxShape3D bodies, not concave triangle shells; terrain remains tiled concave geometry. Seat checks a clear path and a maximum 1 m vertical difference before dismount. Combat HUD gains a readable panel; rifle gets a shoulder offset and compatible lock aim. Cancelling combat resets camera FOV/offset for vehicle transfer.
- Native bike: 25/25. Web bike: 25/25 in 15.289 s, console clean. Shared native combat: 34/34 including locked rifle hits after shoulder adjustment. Traversal regression rerun with the new solids.
- Evidence: `m03-native-round2.log`, `m03-combat-regression.log`, `m03-traversal-regression.log`, `bike-web-report.json`, `bike-web-console.json`, `bike-web-verified.jpg`.
- Bugs fixed: dismount into solid enclosure; camera aim offset potentially persisting after mount; weak combat text contrast.
- Quality: bike handling 8, seat/control stability 8, camera 8, Web 8, modularity 8. Kinematic wheels and placeholder rider pose remain art/physics debt, not simulated motorcycle suspension.
- Failed approach: timed external screenshots missed the brief driving segment. Added optional native engine-frame capture at the actual driving checkpoint for reliable visual inspection; no gameplay assertions bypassed.
- Next action: inspect the riding pose, then implement wing deployment and flight as a separate controller.
- Remaining budget: 18/20.

Milestone 03 visual review: engine-frame capture showed backward-bending rider legs. Corrected the seated proxy's hips/limbs and added a dark vehicle readout panel. Rendered native bike run remains 25/25 (`m03-pose-review.log`, `bike-native-driving.jpg`). Traversal 21/21 and combat 34/34 regressions passed with solid box colliders.

## Milestone 04 / round 01 — transformation and arcade flight

- Objective: deploy wings, take off, climb/turn/descend/land, fold, and preserve rider ownership.
- Files: `scripts/vehicles/{vehicle_transformation,bike_flight_controller,bike_controller,vehicle_seat}.gd`, input/HUD/Main, `tests/flight_verifier.gd`; same integrated main scene.
- Systems: reversible 1.1-second deployment, expanded wing collision, ground/speed/clearance guards, recheck clearance before activation; flight lift/pitch/yaw/throttle/stall sink, landing, airborne exit/fold rejection, forced-death recovery.
- Native run: 21/22. Descent assertion used altitude captured before an intervening steering segment, so it included residual climb. Controlled landing itself passed. Corrected the comparison to the start of the descent input and allowed pitch response time; acceptance pending rerun.
- Adversarial critique: initial-only wing clearance could miss an obstacle appearing during deployment. Added final clearance check and safe folding abort; new-obstruction test passed. Speed and grounded guards prevent transition abuse. Aircraft is an arcade kinematic controller, not an aerodynamic simulation; altitude readout estimates height above terrain, not rooftops.
- Web: pending native acceptance and export.
- Quality: flight 6 pending verified descent; transformation 7, ownership 8, modularity 8. No final-art claim.
- Performance: constant-size wing geometry/collider, no per-frame node allocation.
- Next: corrected native and Web flight verifier, frame capture, then cargo and resources.
- Remaining budget: 19/20.

## Milestone 04 / round 02 — verified flight

- Native rendered verifier 22/22, Web 22/22 (18.426 s), Web console clean. Export passed. Evidence: `m04-flight-round2.log`, `flight-native-report.json`, `flight-native-climb.jpg`, `flight-web-report.json`, `flight-web-console.json`, `flight-web-verified.jpg`.
- Corrected descent sampling now measures from the actual start of descent: 21.86 m to 15.96 m during input, then a controlled ground contact. Screenshots show visibly deployed wings and the rider in the one aircraft.
- Scores: flight handling 7, transformation 8, ownership/stability 8, UI 7, Web 8, modularity 8. Aircraft collision stays upright while visual pitch changes; larger-world flight and difficult terrain landings remain future stress tests.
- Next: hitch, load, carry, detach and unload cargo with conservation/capacity tests. Ground cart must be detached before flight.
- Remaining budget: 18/20.

## Milestone 05 / rounds 01–04 — cargo conservation and constrained towing

- Files: `resources/{item_definition,inventory}.gd`, `vehicles/{cargo_cart,hitch_system}.gd`, BikeController, transformation guard, Main/input, `tests/cart_verifier.gd`.
- First pass 23/24. The wall assertion wrongly reused the bike's longitudinal extent: the narrower cart correctly stopped at x=35.17 against the wall's x=36 face. Corrected the expected bound using its 0.825 m half-width; did not remove collision verification.
- Adversarial round added a wall between cart and bike. It exposed a real 6.56 m center separation despite eventual braking. Fixed by limiting outward bike velocity before motion when separation reaches 4.4 m. New run holds gap=4.41 m, speed=0. Cargo retains 40 ore units across load, drive, detach, reattach, partial unload, pause and recovery.
- Collision layer includes the world bit so actors, camera and weapons recognize the cart as an obstacle. Visual cargo updates only on inventory changes. Inventory transfers commit both sides before locked change notifications, reject negative/unknown/excess/self transfers, and return independent snapshots.
- Native 25/25 (`m05-cart-round4.log`); Web 25/25 (12.104 s), clean console (`cart-web-report.json`, `cart-web-console.json`). Web export passed. Earlier round 3 repeated the known hitch failure while the next test was prepared; no acceptance claimed.
- Quality: cargo correctness 8, towing 7, capacity/transactions 8, Web 8, stability 8. Kinematic trailer and parking friction are approximations; no rigid hitch joint, suspension or free-rolling slope simulation yet.
- Next: full resource → storage → shop and accepted parcel → driven cart → reward loops.
- Remaining budget: 16/20.

## Milestone 06 / round 01 — resources, storage, shops and delivery

- Files: `resources/{resource_source,storage}.gd`, `economy/{shop,delivery_contract,logistics_world}.gd`, Main/HUD/input, `tests/logistics_verifier.gd`.
- Added finite ore/timber sources, renewable olives, backpack/cart/warehouse transfers, stock-backed buying/selling, one-shot parcel contract, near-station interaction guards, B cargo readout and U use/Shift+U reverse actions. Same integrated scene.
- First native 18/21: resource/trade/capacity tests passed; automated straight-line driver overshot the delivery destination after lateral terrain drift. Added heading correction and gradual arrival speed control to the input driver; no teleport to delivery used. Completion/reward assertions remain required.
- Adversarial review also found a signal reentrancy gap in contract state changes. Acceptance and delivery now enter temporary transaction states before inventory notifications, preventing nested acceptance or payment attempts.
- Web logistics pending native corrected run. Cargo suite separately Web verified above.
- Scores: resources 7, economy 6 and delivery integration 5 pending real-route acceptance.
- Debt: limited catalog and one player contract; no persistent save, recurring contract generation, worker execution or large-world streaming yet.
- Next: finish physical-route proof, reentrant contract test, Web, then data-driven workers.
- Remaining budget: 19/20.

## Milestone 06 / rounds 02–03 — driven delivery accepted

- Round 2: controller added steering, but fixture had rotated the bike after hitching, putting the trailer on the wrong side and causing a jackknife. Corrected fixture to align bike and cart before mounting/hitching, then drive using throttle/steering/brake inputs. No delivery teleport.
- Round 3 native 22/22: 63.23 m cargo trip, stopped 3.48 m from destination; one parcel consumed, exactly 75 crowns rewarded. Signal-reentrant acceptance test passed. Web 22/22 (11.411 s), clean console. Evidence: `m06-logistics-round3.log`, `logistics-native-report.json`, `logistics-web-report.json`, `logistics-web-console.json`, `m06-web-export.log`.
- Scores: resources 8, inventory/logistics 8, economy 7, delivery integration 8, Web 8, stability 8. Catalog and contracts are intentionally small. No save or full-world claim.
- Source and architecture documents updated to reflect implemented systems instead of stale milestone-01 descriptions.
- Next: data-driven worker jobs with real navigation, shortages, full destinations, recall and removed-source recovery.
- Remaining budget: 17/20.

## Milestone 07 / round 01 — autonomous jobs reveal unreachable market

- Files: `ai/{navigation_controller,worker_actor}.gd`, `jobs/{job_definition,job_executor,worker_manager}.gd`, Main/input and `tests/worker_verifier.gd`.
- Added incremental local A* grid, explicit shared state-machine workers, transactional job execution, order UI, retries/recall, debug state labels. Farm, Gather/Mine, Transport, Deliver and ShopKeep share job resources and source/destination interfaces.
- Native first autonomous harvest completed over 189.5 m and deposited five olives. Market stocking then failed: the market desk was inside the tavern's solid blockout. Prior trade fixtures teleported the player there, hiding spatial accessibility. Stopped the dependent run rather than treat later failures as independent defects.
- Fix: moved market to (-13, 1) in the outdoor frontage. Added solid-overlap checks for every logistics endpoint. Logistics regression now 23/23; worker second run has passed harvest and market stocking and is continuing.
- Adversarial lesson: valid inventory transactions do not establish navigable placement. Actual autonomous travel must supplement fixtures. Jobs retain cargo on blocked delivery and never reacquire after an acquired stage.
- Web worker pending; prior logistics Web 22/22 predates the new endpoint assertion and will be repeated. No worker acceptance yet.
- Quality: automation 6 pending complete suite, job architecture 8, navigation 6 until blockage recovery verified.
- Debt: navigation remains local and conservative, no worker scheduling/wages or persisted jobs. Distant simulation/streaming next, after worker acceptance.
- Remaining budget: 19/20.

Milestone 07 round 02 native acceptance: 21/21 in 145.907 s (`m07-worker-round2.log`, `worker-native-report.json`). Farm → warehouse, warehouse → market sale, ore → warehouse and courier → quay all completed autonomously, including return to idle. Full destination retained carried stock, clearing space resumed delivery without duplication, replenished sources retried, recall returned cargo, and removed sources failed safely. Native scores: automation 8, job architecture 8, resource integration 8, navigation 7, stability 8. Web is running this same suite. Further adversarial tests will add an actual blocked corridor and two concurrent actors; the current contention assertion only exercises shared executor transactions.

## Milestone 07 / round 03 — physical obstruction and concurrent workers

- Added an enclosing set of physical walls around a worker, then removed it. Worker entered Blocked and resumed the route automatically. Added a second real NPC competing for five timber units; exactly five reached the warehouse, with no duplicate carried stock.
- Native 25/25 in 158.866 s; Web 25/25 in 159.097 s, clean console. Evidence: `m07-worker-round3.log`, `worker-web-report.json`, `worker-web-console.json`. Scores: worker automation 8, job architecture 8, resource integration 8, navigation 7, stability 8, Web 8.
- Remaining debt: coarse local paths, no wages or schedules. Remaining round budget: 17/20.

## Milestone 08 / round 01 — bounded streaming and distant simulation

- Files: `world/{terrain_chunk,world_streamer,world_manager}.gd`, CoastalRegion height function, worker simulation tier, player/bike bounds, Main, `tests/world_verifier.gd`.
- Added 5×5 streamed terrain residency, one chunk build per physics tick, nearest-first generation and retirement of off-window chunks. The authored region's collision/rendering deactivates at distance; its logical inventories and job records remain. Distant workers run a coarse 1 Hz simulation without collision movement; returning restores physical simulation.
- Native 13/13, Web 13/13 (67.659 s), clean console. Continuous flight crossed more than 500 m, terrain remained ready, a distant timber job completed, far quadrants supported actual player collision, and boundary recovery restored the core. Max measured build: native 1.46 ms, Web 14.10 ms. This is one machine, not a universal frame-rate guarantee.
- Evidence: `world-native-report.json`, `world-web-report.json`, `world-web-console.json`, `m08-world.log`. Initial parse error from an inferred dynamic-reference type was fixed with an explicit bool annotation before runtime verification.
- Scores: architecture 8, streaming stability 8, performance 7, distant logistics 8. Sparse far terrain uses placeholder regional height/palette variation; it is not completed regional content. Authored assets remain in memory while disabled; generated outer chunks are actually freed.
- Next: sustained cross-domain flight and save/load. Remaining budget: 19/20.

## Milestone 09 / round 01 — sustained cross-domain flight

- Added `tests/distance_verifier.gd` and a dedicated long-test flag. Flight uses normal mount, transformation, throttle and climb controls; no mid-journey teleports or time scaling.
- Native 6/6 after 719.038 s. Crossed 23,953.7 m after takeoff, created 1,895 chunks, retired 1,870, peak 25 resident, max build 1.61 ms. No missing terrain or loss of flight ownership. Evidence: `m09-distance.log`, `distance-native-report.json`.
- Web long-distance run started and remains pending. The shorter Web streaming test already passed separately. Do not substitute the native result for Web acceptance.
- Full shared native regressions after streaming passed: traversal 21, combat 34, bike 25, flight 22, cargo 25, logistics 23, worker 25, world 13 (`m09-full-regression.log`).
- Added configurable verification runner, fresh-report validation and timeouts. Main's repeated suite setup now shares one runner.
- Score: sustained native streaming 8; overall large-world content remains incomplete. Next: Web long run, persistence, map and rendering optimization. Remaining budget: 19/20.

## Milestone 10 / rounds 01–02 — validated persistence

- Files: `persistence/{save_schema,save_system}.gd`, Inventory restoration, explicit seat restoration, input/Main, `tests/save_verifier.gd`.
- Version 1 snapshots preserve player/equipment, pack/cart, hitch/seat, source and storage stock, contracts/credits, survey flags, enemy health/death and a worker's acquired/delivered job stage. Grounded/stopped saves only; workers may be carrying cargo. Full schema validates before live mutation. Writes use a temporary file then rename.
- Native first run had 19 passing state assertions but logged an engine JSON error on a truncated file. Replaced the logging convenience parser with explicit parse-result handling. Round 2: native 19/19, Web 19/19 (24.851 s), clean logs/console. Evidence: `m10-save-round2.log`, `save-web-report.json`, `save-web-console.json`.
- Verified repeated restore does not reacquire goods, restored workers finish once, invalid quantities/versions/coordinates/partial saves cannot clear live state, and mounted load restores exclusive ownership. Active courier recall is rejected so its parcel cannot become orphaned.
- Scores: persistence correctness 8, schema/modularity 8, stability 8. Cross-page browser persistence is still unverified; current Web test saves and loads through the filesystem in one session. No save-during-flight support, no multi-worker roster persistence yet (one user worker currently exposed).
- Next: browser reload probe, map usability, measured draw-call reduction. Remaining budget: 18/20.

Milestone 09 Web acceptance: 6/6 after 719.103 s, 23,953.7 m continuously flown after takeoff, 1,895 chunks created / 1,870 retired, peak 25 resident, max chunk build 13.00 ms; clean console. Evidence: `distance-web-report.json`, `distance-web-console.json`, `distance-web-complete.jpg`. This run predates the subsequent core terrain optimization; that change has its own regressions below.

## Milestone 10 / round 03 — stronger restoration and browser restart

- Adversarial review found that normal `equip()` is input-gated and therefore cannot restore a changed weapon while loading is paused. Added an explicit validated restoration interface; stronger test changes rifle to wrench before loading and checks rifle geometry/state restore. Clears stale dodge/jump buffers, restores camera/facing and native mouse mode, and resets resurrected enemy presentation. Rejects fractional ammunition rather than truncating it.
- Native 22/22 (`m10-save-round3.log`); Web 23/23 including a saved browser-restart probe (`save-web-report.json`). Reloaded the page into a fresh game and loaded that probe: 4/4 (`resume-web-report.json`), including worker parcel preservation. Both Web consoles clean. Probe files are separate from the user's ordinary save and removed after testing.
- Added a load button to the start/pause menu. Save version 1 remains limited to grounded/stopped vehicle/player state and the one user-facing worker. A courier already carrying a parcel must complete/retry rather than be recalled into an orphaned contract.
- Remaining budget: 17/20.

## Milestone 11 / rounds 01–04 — map, draw calls and a terrain regression

- Files: `ui/{field_map,game_hud}.gd`, worker/cargo panel input, `world/static_batcher.gd`, CoastalRegion terrain tiling, PlayerVisual torso batching, bike floor-contact handling, Main, UI/bike/world verifiers.
- Added readable local/world maps, logistics/hostile markers, mouse-picked waypoints and field-note distance. Readout panels are mutually exclusive; pause menu scrolls instead of extending beyond the viewport.
- First rendered run: incorrect synthetic click coordinates, worker-panel reopening failure, 411 draw calls against an under-400 budget. Corrected test coordinates through the viewport stretch transform, changed panel toggles to rising-edge input latches, and batched only static torso details while preserving animated arms. Labels remain separate when their sign meshes are batched.
- Rendered native 13/13, Web 13/13; both measured 389 median draw calls and 120 FPS in the village on this machine, versus the earlier 679 baseline. 248 scenery meshes batched; authored terrain changed from 100 × 32 m tiles to 25 × 64 m tiles. Evidence: `m11-ui-round3.log`, `ui-web-report.json`, `ui-web-console.json`, `ui-native-*.jpg`.
- Shared world regression exposed a genuine bike defect: its speed was clamped after all slide contacts, including ordinary floor contacts, causing permanent acceleration loss at a terrain seam. Diagnostics identified floor normals (~0.037, 0.999, 0), not a wall. Restricting speed loss to wall contacts fixed it. Added a real seam-crossing assertion (z=96.66, speed=15.83 m/s). Bike 26/26, flight 22/22, world 13/13 passed (`m11-terrain-regression.log`).
- Scores: UI 8, performance 8, map 8, bike stability 8, visual readability 7. Outer terrain remains sparse; batching preserves collision but retains hidden source geometry for now. Remaining budget: 16/20.

## Milestone 12 / rounds 01–02 — combined combat, delivery and workers

- Added `tests/integration_verifier.gd`. Only initial fixtures position the player/vehicle; all subsequent approach, travel, combat positioning and remounting use movement/input.
- First pass 12/14: driver stopped outside effective aggro/melee range, so the wrench swung in air; an intermediate return waypoint also failed its arrival requirement. Revised the camp approach and explicitly walked into melee range and back to the motorcycle.
- Round 2 native 16/16 in 108.766 s (`m12-integration-round2.log`). Accepted parcel, drove 111.3 m to encounter, dismounted, wrench hit for 26, rifle finished hostile using ammunition, walked back/remounted, delivered parcel for 75, assigned harvest, and stocked/sold the resulting olives for another 20. Cargo and ownership remained valid.
- Web combined scenario pending current export. Flight remains separately verified; the example integration sequence makes flight optional, and the ground cart still must detach before flight.
- Scores: combined integration 8, logistics 8, combat 8 for this scenario. Remaining budget: 18/20.

## Milestone 13 / round 01 — buffered melee and sound feedback

- Files: PlayerCombat signal/buffer interface, `audio/game_audio.gd`, original WAVs generated by `tools/generate_sfx.py`, Main, `tests/feedback_verifier.gd`.
- A 0.28-second recovery input buffer allows one follow-up wrench attack. Pause/dodge cancel it; stamina is charged only when the next attack actually starts. Sound hooks cover swings, hits, rifle, reload, steps, jump, delivery reward and a quiet looping vehicle engine, using a fixed eight-voice pool. No external samples or paid services.
- Native rendered 10/10: combo hit count/damage, cancellation, stamina rejection, valid clips, bounded voice count, one native playback voice, pause silence. Evidence: `m13-feedback.log`. Web verifier will validate events/resources and silence gates; actual browser playback requires the normal Begin gesture and separate manual checking.
- Scores: melee feel 8, sound architecture 8; placeholder sound quality 6 pending listening/polish. No claim of final audio.
- Next: combat regression/export, Web integration/feedback, then remaining gameplay depth and regional content. Remaining budget: 19/20.

## Current rubric (before final content/polish acceptance)

| Category | Score / 10 | Limit or evidence |
|---|---:|---|
| Player movement | 8 | Traversal 21 checks |
| Camera | 8 | Collision, shoulder aim, seat transfer |
| Melee combat | 8 | Per-swing damage and buffered follow-ups |
| Rifle combat | 8 | Ammo/reload, aim, muzzle cover |
| Enemy AI | 8 | Native/Web 10 checks; tall/low cover, sight memory, leash and return paths |
| Bike handling | 8 | 26 checks including terrain seam regression |
| Flight handling | 7 | Arcade controls; no realistic aerodynamic model |
| Transformation | 8 | Clearances, obstruction abort, ownership |
| Cargo/cart physics | 7 | Constrained kinematic trailer; no suspension |
| Worker automation | 8 | Real routes, shortages, full storage, two-worker contention |
| Job architecture | 8 | Shared definitions/executor/state machine |
| Resource/logistics loop | 8 | Source → inventory → storage/market |
| Economy | 8 | Repeat parcels and ore-backed ammunition; native/Web 21 checks |
| Open-world architecture | 8 | Sustained native/Web 24 km streaming proof |
| Visual readability | 7 | Readable blockout; sparse outer world |
| UI clarity | 8 | Maps, waypoints, cargo/worker panels, scrollable controls |
| Web compatibility | 8 | Verified suites and restart persistence on one browser |
| Performance | 8 | 389 village draw calls, bounded outer residency |
| Code modularity | 8 | Separate controllers, resources, transactions, jobs, world tiers |
| Stability | 8 | Recorded adversarial failures repaired and rerun |

Current average 7.85/10. The final vertical-slice target of 8/10 average has not been declared achieved. Regional content, AI navigation, economy continuity and final art/audio remain improvement areas.

## Milestone 13 / round 02 — Web feedback acceptance

- Combat regression 34/34 natively. Web feedback 9/9, clean console (`feedback-web-report.json`, `feedback-web-console.json`). The normal Web Begin gesture also enabled play; equipping/firing the rifle visibly changed the magazine from 5 to 4 without console errors. No claim of a listening-quality review from this visual check.
- README and architecture documentation now describe streaming, persistence, map, audio and the expanded verifier runner instead of the obsolete pre-worker state.
- Remaining budget: 18/20. Sound quality remains provisional.

## Milestone 14 / rounds 01–02 — hostile navigation and distant pause lifecycle

- Files: CombatBrain, Main, WorldManager, SaveSystem, AI/world verifiers, verification runner. Hostiles share local navigation, remember the last visible target position for eight seconds, request paths at most once per second and return through obstacles. Restored enemies receive the navigation reference.
- Round 1 native AI 7/8 (`m14-ai.log`): leaving the leash during Attack waited for the entire attack recovery. Added an explicit leash check during Attack; round 2 native 8/8. The hostile made a 4.85 m detour around an 8 m wall, attacked after reacquiring sight and returned home. Further low-obstacle adversarial review is pending.
- Found a separate lifecycle regression: pause/resume far from the core reenabled parked vehicle/enemy simulation without terrain. Main now preserves distance/core gates. World native 14/14, including hidden core geometry and far pause/resume. Combat native 34/34. Evidence: `m14-round2.log` and suite reports. Web acceptance pending export.
- Integration Web round 2 was 15/16 despite eventual delivery and worker completion. One intermediate driving waypoint missed its arrival bound (`integration-web-round2-report.json`); added per-leg position/time diagnostics. This remains a verifier failure until rerun and resolved.
- Current AI score remains 7 pending Web and the additional adversarial case. Remaining budget: 18/20. Next: close Web regressions, then economy continuity and regional content.

Milestone 14 / rounds 03–04: the added 0.85 m barrier test failed as predicted (native 9/10, hostile stuck at z=56.35). Eye-height sight alone incorrectly implied a traversable route. Added leg-height clearance and reset cached paths on pursuit/return transitions. Native now 10/10; the low barrier required a 4.88 m detour (`m14-low-cover-round1.log`, `m14-round4.log`). Web low-cover acceptance pending. Remaining budget: 16/20.

Milestone 12 / rounds 03–04: route diagnostics reproduced the Web waypoint failure, stopping 28.31 m from the first return waypoint after 1,500 frames. The native abrupt turnaround consumed 1,290 frames, making the automated driver brittle across platforms. Replaced it with a broad two-corner turnaround through (-72,23) and (-72,43), retaining physical driving and the same arrival bounds. Pending native/Web acceptance; no successful rerun claimed yet. Failure evidence: `integration-web-round3-report.json`, `integration-web-round3-console.json`. Remaining budget: 16/20.

Milestone 14 / round 05: Web world regression was 13/14. Boundary recovery could run up to 0.25 seconds before core collision reactivated, letting the player fall through the checkpoint terrain; native timing had hidden this defect. WorldManager now refreshes simulation tiers synchronously on the player's recovered signal, and keeps pause guards when doing so. Added a forced worst-case timer assertion for immediate checkpoint collision, plus position/floor diagnostics. Native and Web reruns pending. Evidence: `world-web-m14-round2-report.json`. This is a real recovery bug, not a relaxed test tolerance. Remaining budget: 15/20.

Milestone 14 AI acceptance: native and Web 10/10, clean Web console (`ai-web-report.json`, `ai-web-console.json`). Enemy AI score raised to 8 for the verified local navigation scope. World recovery acceptance remains separate and pending.

Milestone 12 acceptance: broader physical turnaround passed native 16/16 in 102.244 s and Web 16/16 in 103.042 s, with clean console (`integration-web-report.json`, `integration-web-console.json`). No waypoint tolerance or timeout was relaxed.

Milestone 14 recovery acceptance: native 15/15 and Web 15/15 in 69.066 s, clean console. Forced immediate recovery asserted core collision active after two physics frames; player settled at the checkpoint without falling below terrain. Web max chunk build 15.80 ms on this run. Evidence: `m14-world-recovery.log`, `world-web-report.json`, `world-web-console.json`.

## Milestone 15 / rounds 01–02 — repeat courier work and ammunition supply

- Files: `economy/{field_supplies,shop,delivery_contract,logistics_world}.gd`, input/Main, SaveSchema/SaveSystem, economy verifier, HUD glyph fix. P at market buys five rifle rounds for 12 crowns and consumes one actual market ore. Six ore start on market shelves; selling gathered ore replenishes the supply. Reserve is capped at 100 and purchases reject during reload, pause, distance/LOS failures or shortage.
- Shift+U at the courier desk reissues a completed contract, with capacity checks, one current parcel and retained completion count. Completed receipts retire when a new parcel issues. Normal duplicate acceptance/delivery still reject. Completion count is an optional version-one save field for backward compatibility.
- Shop transactions now guard reentrant callbacks and commit money before stock notifications; failures roll back money. FieldSupplies stays separate from the commodity shop and player combat controllers.
- Round 1 import rejected inferred types from the dynamic game reference in two verifier snapshot variables. Explicit Dictionary annotations fixed compilation. Round 2 runtime verification pending (`m15-round1.log`, `m15-round2.log`). No economy acceptance claimed yet. Remaining budget: 18/20.

Milestone 15 / round 03 acceptance: native economy 21/21, logistics 23/23 and save 22/22. Web economy 21/21 in 14.440 s with no new warnings/errors after its RSB_READY marker. Browser console history persists across page navigation; current-run evidence filters by that marker rather than misattributing an earlier error. The first Web test deleted its temporary save during asynchronous IndexedDB synchronization, generating a missing-file error. Cleanup now waits six seconds before and after deletion (`economy-web-round2-console.json`, `economy-web-console.json`). Economy score 8; remaining budget 17/20. Catalog breadth and regional trade remain limited.

## Milestone 16 / rounds 01–03 — flight above highlands

- Added a highland flight verifier at (-1000,-10000), using normal streaming, mounting, deployment and takeoff input. Round 1 required an explicit int annotation for a dynamic-reference verifier counter. Round 2 reproduced a real defect: ground height 124.48 m exceeded the fixed 115 m ceiling; the aircraft stayed at only 0.30 m AGL (2/3 assertions, early termination). Evidence: `m16-round1.log`, `m16-round2.log`.
- Flight ceiling now allows 110 m above local terrain, while retaining the 115 m minimum absolute ceiling near sea level. Round 3 tests climb across chunk boundaries, bounded altitude, low-speed sink, descent/landing, folding and dismount. Native/Web acceptance pending. Remaining budget: 17/20.
- M15 visual review found cargo text partly occluded by the combat HUD. Cargo and worker panels now use a foreground UI layer; cargo readout also exposes market ore stock and rifle reserve. Recheck pending the next Web export.

Milestone 16 / round 04: native 8/8 plus flight 22/22 and UI 12/12 headless. Round 3 reached 7/8: the landing succeeded but the test incorrectly required the landing terrain to remain above 115 m after travelling into a lower area. Replaced that assumption with actual terrain-height agreement, grounded contact and exactly one landing. Takeoff still explicitly starts above 120 m. Native measured takeoff AGL 14.25 m, bounded climb AGL 112.92 m and low-speed sink -4.30 m/s. Evidence: `m16-round3.log`, `m16-round4.log`. Web pending. Remaining budget: 16/20.

Milestone 16 Web acceptance: 8/8 in 38.091 s, clean current-run console. Takeoff/climb, streamed traversal, bounded AGL, low-speed sink, actual-ground landing, folding and dismount all passed (`highland-web-report.json`, `highland-web-console.json`). UI Web regression also 13/13, 389 draw calls / 120 FPS on this machine. Flight score remains 7 until broader handling/content review; the highland integration defect is resolved.

## Milestone 17 / round 01 — streamed regional scenery and discovery

- Files: RegionDefinition, RegionCatalog, RegionManager, RegionScenery, TerrainChunk, Main, FieldMap, persistence, region verifier. Four named landmarks: Greenreach timber camp, Red Mesa quarry, Snowwatch tower, Longfield waystation. Forest, dryland, grassland and highland chunks use different bounded instanced vegetation/rock distributions. Shared source meshes stay cached; chunk-owned instances and landmark nodes retire with terrain.
- Discovery occurs on a close physical approach, emits once per landmark and persists through optional version-one save data. World map marks these destinations. Landmarks are exploration blockouts, not operating regional economies; only Port Solis has the full jobs/trading loop.
- Verifier tests real walking approaches after initial distant fixture placement, all four landmarks, bounded scenery, node retirement, deterministic regeneration, repeat visits, pause and save validation. Native/Web acceptance and visual review pending. Remaining budget: 19/20. No completed-world claim.

Milestone 17 / round 02: native regional checks 18/18, UI 14/14 headless (two new same-frame key-pulse checks), save 22/22 and world 15/15. Rendered regional rerun 18/18 with no shader/runtime errors. Initial Snowwatch screenshot was blocked by a nearby pine despite passing functional checks; widened clearings and added near-camera foliage fading. `region-native-snowwatch-occluded-round1.jpg` preserves the failure; `region-native-snowwatch.jpg` shows the corrected view. Initial Web region run 18/18, max chunk build 16.20 ms; final shader/UI Web reruns pending. Remaining budget: 18/20.

## Milestone 18 / rounds 01–02 — distant mounted/death recovery

- Adversarial review traced another recovery entry point: BikeController.recovered restored the seat/cart positions but did not immediately reactivate authored home collision. A dedicated test used a loaded distant bike, H recovery, a second actual distant takeoff and lethal damage.
- Round 1 native 5/8 (`m18-round1.log`): immediate home collision failed for both mounted recovery and airborne death; after death the bike was below home terrain at y=-0.42. Normal eventual player recovery hid part of this defect.
- WorldManager now listens to both player and bike recovery, after seat/hitch listeners restore their positions. Round 2 recovery, cargo and highland regressions pending. Remaining budget: 18/20.

Milestone 17 final Web acceptance: 18/18 in 34.088 s, clean current-run console, max decorated chunk build 14.80 ms. Updated UI Web 15/15, including same-frame cargo/worker key pulses, with 389 village draw calls. Scenery remains blockout quality; no visual rubric increase claimed solely from functional checks.

Milestone 18 acceptance: native and Web recovery 8/8 (Web 12.685 s), plus native cargo 25/25 and highland 8/8. Loaded mounted H recovery and death after a real distant takeoff both reactivate home terrain immediately. Evidence: `m18-round2.log`, `recovery-web-report.json`, `recovery-web-console.json`.

M18 validation checkpoint: copied 164 source/asset files to `docs/evidence/m18-source` and recorded SHA-256 hashes in `m18-source-manifest.json`. Full native regression runs against that fixed snapshot while later development continues. Web repeated the uninterrupted decorated-world crossing: 6/6, 23,954.0 m in 719.856 s, peak 25 chunks, 1,895 created / 1,870 retired, max build 13.60 ms, clean current-run console. Evidence: `distance-web-m18-report.json`, `distance-web-m18-console.json`, `distance-web-m18-complete.jpg`. Earlier M09 reports archived separately. Native long run remains active.

## Milestone 19 / round 01 — persistent regional encounters

- Added SpawnManager; RegionDefinition supplies hostile kinds for Red Mesa and Snowwatch. Nearby encounters own a 31×31 local navigation grid and one/two reusable EnemyActors. Actors retire before terrain collision is removed; health/death/position records remain. Cleared enemies stay dead across region retirement, and validated save data can restore an earlier wounded state.
- NavigationController now accepts local origin and grid size; the original worker grid retains its 79×79 defaults. Main, map danger rings and persistence wire the manager through explicit references.
- Native encounter 16/16, region 18/18 and save 22/22 (`m19-round1.log`). Used locomotion to approach a regional hostile, fired the rifle for 48 damage, killed it, retired/reloaded the region, restored the wounded snapshot and rejected invalid records. Web encounter pending. Remaining budget: 19/20.

## Milestone 20 / round 01 — autonomous job routines

- Added JobRoutine resource and a worker routine runner. N then 0 starts/stops a repeating Farm → ShopKeep sequence. Stopping retains the current job/cargo; recall also stops future routine assignment. Routine phase/cycle state is optional version-one save data, validated against the active job's delivery stage.
- Tests cover input, pause, automatic harvest/sale, saved carrying state, stop-mid-job, full warehouse failure/retry and resource conservation. Native/runtime verification pending (`m20-round1.log`). Remaining budget: 19/20.

Milestone 19 Web acceptance: 16/16 in 18.424 s, clean current-run console (`encounter-web-report.json`, `encounter-web-console.json`). Regional combat now uses real rifle input, local navigation and persistent actor records; no far-away full-world navigation grid is retained.

Milestone 20 initial native run: 16/16 in 188.486 s. Automatic harvest/sale, restored carrying state, stopping mid-farm and full-storage failure/retry preserved stock; worker/save regressions still running. A new focused adversarial test targets stopping during the final sale and restoring that stopped state. Web verifier dispatch now matches the exact query parameter so `routine_stop` cannot accidentally run `routine`.

Milestone 20 / round 02: main routine 16/16, worker regression 25/25 and save 22/22 natively. Focused stop-final-job test then failed 2/4 (`m20-stop-round1.log`): payment and goods were correct, but stopping disabled the completion counter, including after restoring the stopped snapshot. Added a separate persisted flag for whether the current job belongs to the routine, independent of whether repetition remains enabled. Schema validates that flag against job phase; stop-final-job rerun pending (`m20-stop-round2.log`). Remaining budget: 18/20.

M18 fixed-source full regression completed: 323/323 assertions across 18 native suites, including the 719.695 s / 23,954.0 m flight. Native long run peak 25 chunks, 1,895 created / 1,870 retired, max decorated build 8.09 ms while other verification ran. All 164 source/asset hashes still match the checkpoint manifest. Results copied to `m18-validation/`; complete summary is `m18-full-regression.log`. Later M19/M20 changes have their own focused results and are not silently included in this checkpoint claim.

Milestone 20 stop accounting rerun: native 4/4 in 52.0 s plus save 22/22 (`m20-stop-round2.log`). The in-progress routine-job flag now survives stop/save/load and credits a completed final cycle exactly once. Full Web routine currently running.

## Milestone 21 / round 01 — distant flight horizon

- A rendered highland cruise screenshot exposed a visible terrain-window edge and a mostly empty sky beyond it, despite correct nearby collision (`highland-native-cruise-no-horizon.jpg`).
- Added one reusable GPU-displaced WorldBackdrop mesh and increased camera far distance to 1,600 m. It follows the player on a coarse grid, uses a visual-only height approximation and supplies no collision. The existing 25-chunk window remains authoritative for gameplay. Distant backdrop has no shadows and reuses one mesh/material instead of generating a larger collision world.
- Native rendered verification/visual review pending. Remaining budget: 19/20. Shader duplicates the visual height formula; this is explicit rendering debt, not a second collision authority.

Milestone 20 Web acceptance: full routine 16/16 in 188.728 s and stopped-final-job persistence 4/4 in 52.804 s, both clean current-run consoles. Evidence: `routine-web-report.json`, `routine_stop-web-report.json` and matching console files. Native focused stop case 4/4 and save regression 22/22 also passed. Routine controls are now documented. Worker automation remains 8/10: this is one exposed worker with a configured two-job sequence, not a general scheduling UI.

Milestone 21 / round 02: native structural checks 7/7, UI 14/14 and world 15/15. First rendered highland run 8/8 but visual review failed: excessively bright uniform terrain exposed the near/far square. Preserved `highland-native-cruise-horizon-round1.jpg`. Added a shared near/far terrain palette with macro surface variation and reused the near-chunk material. The second flight view removes the visible square but remains sparse rolling terrain. Web round-one UI 15/15 at 390 draw calls / 119 FPS. Revised shader Web acceptance and rendered budget checks pending. Remaining budget: 18/20; no visual rubric increase claimed.

Milestone 21 acceptance: revised backdrop native 7/7 headless and 8/8 rendered; Web 8/8 in 11.247 s, 162 distant draw calls / 120 FPS, clean current-run console. Highland flight with revised shading native and Web 8/8; region regression 18/18 native. Rendered UI 15/15 at 390 village draw calls / 120 FPS. Worker panel visual capture `ui-native-workers.jpg` fits all routine controls and status. Evidence: `m21-backdrop-rendered.log`, `m21-round2.log`, `backdrop-web-report.json`, `highland-web-m21-report.json`, matching consoles and `highland-native-cruise.jpg`. The horizon solves near-window exposure; authored mountains and richer scenery remain unbuilt. Visual readability remains 7/10.

## Milestone 22 / rounds 01–02 — regional parcel route and flight integration

- Files: DeliveryRoute resource/catalog, DeliveryContract configuration guard, LogisticsWorld remote endpoints/selection, WorldManager visibility, input, HUD/map, persistence, routes/airmail verifiers. O at the courier cycles south quay (75 crowns) and Longfield (180 crowns); active parcels lock the destination. Distant endpoints activate individually without keeping home stations visible. Save data optionally records route identity and derives endpoint/reward from configuration.
- HUD shows the current regional name and delivery distance; map highlights the active destination. Local worker courier jobs retain their original south-quay endpoint.
- Round 1 import rejected an inferred Vector3 from a dynamic test reference. Added the explicit annotation. No runtime acceptance claimed yet. The airmail verifier allows only initial fixture placement, then walks/drives, unloads the cart into the backpack, detaches, takes off, flies, lands and delivers using controls.
- Remaining budget: 18/20. Next: endpoint/save adversarial checks and complete native/Web route. New content remains one small regional desk, not a functioning regional town.

Milestone 22 native: routes 16/16, complete airmail integration 12/12 in 99.490 s; logistics 23/23, save 22/22 and world 15/15. UI rendered 15/15, 390 draw calls / 117 FPS, cargo panel fits. Web route/save checks 16/16 with clean current-run console; full Web flight delivery still running. The integrated trip drove from town, unloaded and detached the cart, flew beyond 1.17 km, landed, folded, drove to Longfield and paid exactly once. Native rendered evidence capture is running separately.

## Milestone 23 / rounds 01–02 — cargo access and hitch geometry

- A new adversarial suite failed 4/9 on unchanged cargo code: load/unload crossed a solid wall; a stationary but airborne bike attached a grounded cart and transferred cargo; a knee-high drawbar obstacle did not block hitching. Evidence: `m23-round1.log`, `cargo_access-native-round1-report.json`.
- HitchSystem now checks participant grounding and physical lines of access. Queries exclude the actor/bike/cart themselves, because the cart also uses the world collision bit. Attachment checks the actual low drawbar height, and blocked access leaves inventories unchanged.
- Fixed native/Web runs pending. Remaining budget: 18/20. Cargo score stays 7 pending acceptance; these are correctness guards, not suspension improvements.

Milestone 22 acceptance: native airmail 12/12 (99.490 s), rendered 12/12 (100.160 s) and Web 12/12 (99.792 s), with clean current-run browser console. Native screenshot `airmail-native-complete.jpg`, Web `airmail-web-m22-complete.jpg`, reports/consoles preserve evidence. No actor/vehicle pose changes occurred after parcel acceptance. Route selection/save checks native/Web 16/16. Route controls are now documented. Sparse regional scenery remains visible in the capture; the milestone adds a working purpose for travel rather than claiming a finished landscape.

Milestone 23 / round 03: initial guards passed native 9/9 and existing cart 25/25. A second adversarial route through warehouse interactions still bypassed cargo line-of-sight (10/11, `m23-station-round1.log`). Centralized `can_access_cart` and made station container selection use the same grounded/access rules. Final expanded native/Web acceptance pending. Remaining budget: 17/20.

Milestone 23 focused acceptance: native/Web expanded cargo access 11/11, Web 6.101 s, clean current-run console. Native route 16/16, logistics 23/23, cart 25/25. Initial guard airmail regression 12/12; latest shared-access Web airmail regression remains running. No cargo stock was lost by rejected transfers. Evidence: `m23-round3.log`, `cargo_access-web-report.json` and matching console.

## Milestone 24 / rounds 01–02 — directional shadow artifacts

- Rendered screenshots showed striped ground artifacts. Increased shadow bias/normal bias did not remove them. Disabling shadows in an isolated UI capture removed the stripes, confirming the shadow pass as the source (`village-shadow-before.jpg`, `ui-native-village-no-shadows.jpg`). The diagnostic is opt-in and does not disable shadows in ordinary play.
- Testing reverse face culling with modest bias to prevent front-facing ground from shadowing itself. No visual acceptance claimed yet. The brighter shadowed-light appearance is a documented Compatibility renderer color-space difference, not evidence of duplicate light nodes: https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html#tweaking-shadow-bias .
- Remaining budget: 18/20. Next: verify visible shadow contacts and artifacts, then Web rendering. No engine replacement or global shadow removal is planned.

Milestone 23 final integration acceptance: shared access guard Web airmail 12/12 in 99.757 s, clean current-run console (`airmail-web-m23-report.json`, matching console). The stricter cart rules preserve the complete delivery trip.

Milestone 24 / rounds 03–04: reverse face culling removed most ground striping; lower, warmer-neutral sunlight reduced clipped color. Road and plaza overlays now receive shadows without casting them onto their own ground, removing the remaining plaza artifact. StaticBatcher preserves this choice by leaving nonstandard shadow casters unmerged. Rendered UI 15/15, 377 draw calls / 118 FPS; regional rendered checks 18/18 with retained contact shadows and no scene/shader errors. Evidence: `m24-lighting-round4.log`, `m24-region-rendered.log`, `ui-native-village.jpg`, `region-native-snowwatch.jpg`. Web final acceptance is recorded in `ui-web-m24-final-report.json` and matching console. Remaining budget: 16/20. Roof shadow edges remain limited by the existing shadow-map resolution; final art quality is not claimed.

Milestone 24 final Web: UI 15/15 in 4.030 s, 377 draw calls / 120 FPS, clean current-run console. Preserved 192 source/asset files in `m24-source` with SHA-256 manifest `m24-source-manifest.json`. Full native regression runs against that immutable copy while later work continues. The long crossing is not repeated here: M18 already verified the unchanged streaming/collision architecture over 24 km, and M21 separately tested the visual horizon's bounded rendering.

## Milestone 25 / rounds 01–02 — boarding and wing-safe dismount

- New adversarial suite tests moving/falling bike boarding, departure during wing transitions, own-wing collision at aircraft exit, grounded settling, ground-mode airborne exit and forced recovery. First import found the verifier inherited from a base without the shared report writer; corrected the test base. Production seat code remains unchanged for the baseline run.
- Remaining budget: 18/20. Next: reproduce and repair any ownership or overlap failures, then native/Web regressions.

Milestone 25 baseline: native 3/12 (`m25-round2.log`, `seat_safety-native-round2-report.json`). Moving/falling bikes allowed boarding; wing transitions allowed leaving; deployed-aircraft exit chose a point inside its own wing collider and did not settle on the ground; ground-mode airborne departure and forced transition cancellation were also unguarded. Added stable-floor/speed/mode boarding rules, transition/ground dismount guards, own-vehicle overlap checks and nose/outboard aircraft exit candidates. Forced recovery cancels unfinished wing movement. Fixed rerun pending. Remaining budget: 17/20.

Milestone 25 acceptance: native/Web seat safety 12/12 (Web 7.897 s), clean current-run console. Aircraft exit now uses the clear nose position (0,2.08,77.8) in the test and settles without overlap correction. Native bike 26/26, flight 22/22, save 22/22 and recovery 8/8 also passed (`m25-round3.log`, `seat_safety-web-report.json`, matching console). Existing ownership controls remain modular in VehicleSeat.

## Milestone 26 / rounds 01–02 — coastal water behavior

- Added a WaterBody resource describing the same bounds/level as the visible coast, and prepared a WaterSafety controller for wading and inventory-preserving deep-water recovery. It is not connected during the baseline test. Initial verifier import needed an explicit integer annotation for an Array element; fixed that and placed the shore cart at its own sampled ground height.
- Verifier covers normal movement, shallow wading, pause/recovery timing, unsafe save rejection, loaded-bike recovery, detached-cart recovery, flight over water and water landing. Runtime baseline pending. Remaining budget: 18/20. This milestone provides wading/recovery, not a swimming controller or boat simulation.

Milestone 26 baseline: native 7/12 in 30.624 s (`m26-baseline-round2.log`, `water-native-baseline-report.json`). Shallow movement had full dry speed; deep submerged saves were allowed; player/loaded bike/detached cart did not recover through a deliberate water rule. The existing below-world fallback happened to recover the plane, so the final verifier additionally requires the water controller's recovery count to prove the correct path. Connected WaterSafety, independent surface movement multiplier, unsafe-save guard and WADING HUD state. Water recovery retains inventories and uses existing actor/vehicle recovery listeners. Fixed runtime checks pending; remaining budget 17/20.

Milestone 26 / round 04: first connected run 10/12 (`water-native-round3-report.json`). Diagnostics showed the loaded bike stopped against an authored coastal rock at (99.08,-1.97,0.03), still above the water; it never entered the hazard. Moved the test approach through the actual beach gap at z=7.5 instead of weakening collisions. The plane's water recovery itself worked, but its expected cumulative count depended on that failed first approach. Made the flight assertion compare its own before/after recovery count. Wading measured 2.76 m/s versus dry 4.60 m/s; all player/pause/save/detached-cart checks passed. Rerun pending; remaining budget 16/20.

Milestone 26 native acceptance: water 12/12 in 24.641 s and rendered 12/12 in 25.317 s. Screenshot `water-native-wading.jpg` shows the readable waterline and WADING state. Native traversal 21/21, save 22/22, cargo access 11/11, seat safety 12/12 and airmail 12/12 passed. The renderer and water safety now share the same injected WaterBody resource so editable bounds/level cannot diverge. Final Web test is running.

M24 fixed-source regression completed: 399/399 assertions across 24 native suites. All 192 SHA-256 hashes still match. Results copied to `m24-validation`; complete summary `m24-full-regression.log`. Later M25/M26 changes have separate targeted acceptance and are not included in that snapshot claim.

Milestone 26 Web acceptance: 12/12 in 24.933 s, clean current-run console (`water-web-report.json`, `water-web-console.json`). Both water-triggered vehicle recoveries preserve their cargo; flying safely above the surface does not recover the plane. Wading/recovery are implemented; swimming remains outside this milestone.

## Milestone 27 / rounds 01–02 — vehicle ground contact

- Baseline compound-slope test 6/11 (`m27-baseline.log`, `vehicle-ground-native-baseline-report.json`): motorcycle rear tire clearance error 0.568 m; trailer left tire error 0.376 m. Physical movement/hitch/parking remained stable, but upright visuals did not follow the slope.
- Added GroundPose, which samples actual collision under a vehicle and adjusts only its visual pitch/roll/height. Bike retains steering lean and its upright physics body; cart geometry has a separate visual root. Corrected the cart box's lower edge from 0.3 m above the wheel base to ground level while keeping its upper extent.
- Fixed slope verification and cart/seat/flight/water/save/delivery regressions pending. Remaining budget: 18/20. This is ground alignment with kinematic physics, not a full suspension simulation.

Milestone 27 acceptance: native/Web slope 11/11 (Web 7.414 s), clean current-run console; native rendered 11/11 with contact screenshot `vehicle-ground-native-slope.jpg`. Tire errors on the compound test ramp round below 0.001 m. Native cart 25/25, seat 12/12, flight 22/22, water 12/12, save 22/22, integration 16/16 and airmail 12/12 passed (`m27-round2.log`). Physics bodies remain upright; only visual surface pose follows slopes. Full suspension remains unimplemented.

## Milestone 28 / rounds 01–02 — vehicle chase camera

- Baseline 8/12 (`m28-baseline.log`, `chase-camera-native-baseline-report.json`). Camera followed vehicle position but retained its old compass direction, leaving it 180 degrees from the expected rear view on the first driving leg. Manual orbit, pause and stationary save orientation already worked.
- Added smooth vehicle-heading follow above 2 m/s, with a three-second manual-look grace period. Right drag and IJKL suspend chase, stationary vehicles retain the selected view, and VehicleSeat explicitly installs/clears/restores heading ownership. Pitch/zoom remain player-controlled.
- Fixed native/Web and movement/combat/flight/save/integration regressions pending. Remaining budget: 18/20.

## Milestone 29 / rounds 01–02 — optional verifier isolation

- Fault injection in a temporary project copy confirmed that a syntax error in an unused camera verifier prevents ordinary main-scene startup. All three baseline checks fail: ordinary play, selected broken verifier diagnostics, and unknown-suite diagnostics (`m29-baseline-round2.log`, archived `m29-baseline-startup-*`). The first harness attempt referenced a nonexistent top-level shaders directory; corrected it to copy the actual assets directory.
- Next: load only a requested suite, share the suite catalog with the native runner, and report invalid requests promptly. The test mutates only its disposable project copy. No gameplay fixture or user save is altered.
- Remaining budget: 18/20. Modularity/stability stay 8 pending verification; this addresses a reproduced developer workflow failure, not a new gameplay feature.

Milestone 28 native: chase camera 12/12, traversal 21/21, combat 34/34, flight 22/22, save 22/22, integration 16/16 and airmail 12/12. Web 11/12 with clean console: stopped right-drag assertion fails while keyboard/free-look/heading/ownership/save checks pass. Preserved round-2 Web report; instrumenting actual drag state and yaw delta before deciding whether this is controller behavior or input-fixture scaling. Remaining budget 17/20.

Milestone 29 round 03: native fault isolation 3/3. Main loads only a requested test script; tests/suites.json now supplies native runner membership, thresholds/timeouts and game dispatch membership. Web export explicitly includes that catalog. Unknown or uncompilable selected suites emit RSB_VERIFICATION_ERROR and native exit status 2. Removed 26 redundant main-scene test wrappers. Valid-suite/native/Web regressions pending; remaining budget 17/20.

Milestone 28 round 04: diagnostics show drag starts correctly but a 100-pixel synthetic movement rotates only -0.187 rad in Web, versus -0.300 native. The camera used content-scaled `relative`; Godot documents resolution-dependent sensitivity and recommends unscaled `screen_relative` (https://docs.godotengine.org/en/stable/classes/class_inputeventmousemotion.html#class-inputeventmousemotion-property-screen-relative). Switched camera input to unscaled motion and populated that field/button mask in the synthetic event. Tightened the assertion to the expected -0.300 ±0.010 rad instead of weakening the threshold. Rerun pending; remaining budget 16/20.

Milestone 29 acceptance: native fault isolation 3/3; valid lazy-loaded suites UI 14/14, chase camera 12/12 and exact `routine_stop` dispatch 4/4. Web export builds with the shared catalog; valid camera suite runs (its separate M28 sensitivity failure is documented above), unknown query visibly reports the requested ID, and ordinary Begin/cargo controls work with a clean current-run console. Evidence: `m29-round3-regressions.log`, `startup-web-unknown.json`, `startup-web-playable.jpg` and matching console. Code modularity/stability remain 8/10; test-body runtime hangs still rely on the runner timeout. No scene changes.

Milestone 28 focused acceptance: corrected native/Web camera 12/12 (Web 22.721 s), exact injected mouse yaw -0.300 rad, clean current-run console. Native full driving/combat and regional flight journeys passed before the sensitivity-only change; latest Web driving/combat integration is running. Camera remains 8/10: automatic heading and deliberate free look work, but extended human camera comfort testing remains.

Correction to M29 normal-flow evidence: the saved screenshot proves Begin reached the playable HUD; it was captured too soon to establish the cargo panel state. Existing UI suite covers cargo behavior. The optional-test startup claim is unchanged.

## Milestone 30 / round 01 — motorcycle visual readability

- Reference comparison: current red tank/engine/frame are mostly boxes; wheels have solid disc faces and little mechanical silhouette. Improve procedural geometry within the existing wheel centers, seat and collision envelope. Preserve source as `bike-visual-before-m30.gd.txt`.
- Plan: faceted tank, tubular frame, open spoke wheels, fenders, engine fins, exhaust and luggage rack; batch rigid pieces by material, keep steering/wheel spin independent. Verify native/rendered/Web bike, transformation and ground pose. No final-art claim.
- Remaining budget: 19/20. Visual readability stays 7 until rendered review.

M28 integrated Web acceptance: 16/16 in 103.088 s, full loaded-cart drive, wrench/rifle encounter, delivery and worker economy, clean current-run console (`integration-web-m28-*`).

M30 round 02: first import rejected type inference for a float derived from an untyped Array iteration. Added explicit float annotation; no runtime acceptance claimed from that attempt. Rendering helper captures the real workshop scene and production wing transition; it does not count presentation captures as gameplay tests. Remaining budget 18/20.

M30 rendered round 02: bike 26/26 and compound ground pose 11/11 pass. Mechanical silhouette/spokes/engine are readable, but the tank's triangle winding is inverted, exposing internal frame instead of the exterior tank. Reversed tank faces and changed the detail camera to inspect the opposite side. First capture preserved as `motorcycle-native-detail-round2.jpg`; 246 draw calls for that workshop view, 292 with wings. Remaining budget 17/20.

M30 round 04: isolating the tank from batching makes it visible, proving the earlier face-order diagnosis was incomplete. Mixed indexed primitive meshes and unindexed custom triangles lose the unindexed geometry in StaticBatcher. Normalize unindexed input to indexed geometry before appending. Added a conservation check requiring every source triangle and both separated bounds to survive a batch, with an animated-child exclusion check. No collision changes. Remaining budget 16/20.

M30 round 05: first normalization attempt called an ArrayMesh-only index-count method on primitive meshes, causing runtime errors. Restricted that conversion to ArrayMesh; verifier counts triangles through the common Mesh surface arrays. The new lazy-loader correctly rejected the failed verifier promptly rather than hanging. Remaining budget 15/20.

M30 native final: mixed geometry 5/5; UI 14/14 headless, 15/15 rendered; regions 18/18. Fixed capture shows the complete tank, open spoke wheels, engine, tubular frame, mudguards and rack. Bike 26/26, slope 11/11, flight 22/22 and seat 12/12 passed during geometry work. Final village UI capture measures 375 draw calls / 118 FPS versus the earlier 377, so the extra detail has not expanded submissions in the same view. Workshop close-up 159 calls / aircraft 196 are different views and not comparative benchmarks. Web bike 26/26; final batching/Web flight checks pending. Evidence `m30-round5.log`, `m30-ui-rendered.log`, `motorcycle-native-detail.jpg`, `motorcycle-native-aircraft.jpg`, `bike-web-m30-*`.

## Milestone 31 / round 01 — village ground readability

- Rendered village review shows the flat plaza disk floating above downhill terrain and disappearing into uphill ground. Replaced it with a subdivided circular surface sampled against the authored ground triangles, maintaining a small shadow-receiving offset. Terrain collision and heights stay unchanged.
- Files: `world/coastal_region.gd`; before capture `plaza-native-before.jpg`. Use existing traversal/UI acceptance and rendered native/Web comparisons for this visual correction. No extra mirrored geometry test.
- Remaining budget 19/20. Visual readability remains 7 pending review; circular edges/placeholder landscape remain art debt.

M30 final Web acceptance: bike 26/26 in 17.957 s; mixed geometry 5/5 with 72/72 triangles preserved; flight 22/22 in 18.487 s. Clean current-run consoles. Overall visual readability remains 7/10 because this detailed vehicle sits in sparse blockout scenery; bike handling 8, transformation 8, performance 8, modularity 8 and stability 8. No final art or full suspension claim.

M31 round 02: traversal assertions passed, but the runner correctly rejected the run because a typed-Array ternary failed while constructing the plaza, leaving it absent. The rendered UI run showed the same error; neither run is accepted. Changed the temporary point collection to PackedVector2Array and rerunning. Remaining budget 18/20.

M31 native acceptance: corrected traversal 21/21 and UI 14/14 headless; rendered UI 15/15, no script errors. The plaza now follows the slope with grounded edges. Final Web UI is running. Collision/terrain height functions remain unchanged; the new height sampler is only for the authored plaza surface.

## Milestone 32 / round 01 — locate parked equipment

- Review found no map markers for the motorcycle or detached cart, making equipment difficult to find after a distant trip. Added explicit bike/cargo markers, selectable tracking, and Clear. Tracking follows the actual node position at the existing HUD refresh rate, selects world scope for remote equipment, and plain map clicks replace tracking with a fixed waypoint.
- Files: `ui/field_map.gd`, `ui/game_hud.gd`; no teleport or inventory mutation. A text-replacement guard caught a mismatched HUD line before writing the HUD change; applied the exact patch instead. Next: real map-input tests including overlapping marker positions, remote cart, pause, save/load movement and clearing; native/Web layout review.
- Remaining budget 19/20. UI remains 8 pending acceptance; generic/asset waypoints are session-only as before.

M31 final Web UI acceptance: 15/15 in 4.027 s, 375 draw calls / 120 FPS, clean current-run console and capture `plaza-web-m31.jpg`. Visual readability stays 7; this repairs ground attachment, not final landscape art.

M32 rounds 02–03: initial verifier could not infer dynamic values; its inventory copy also used a nonexistent API. Replaced that with Inventory.contents() and explicit Dictionary/bool types. The failed verifier returned before producing a report, so terminated only that test process and retained its log. Production tracking is not yet accepted. Remaining budget 17/20.

M32 acceptance: equipment map native 12/12, rendered 12/12 (3.980 s), Web 12/12 (3.637 s), clean current-run logs. Native UI 14/14 and save 22/22 pass. Captures `ui-native-equipment-local-map.jpg` and world-map counterpart show controls within bounds. UI clarity 8, stability 8, modularity 8; markers are session-only and do not move equipment.

Current rubric after M32: movement 8; camera 8; melee 8; rifle 8; enemy AI 8; bike 8; flight 7; transformation 8; cargo physics 7; worker automation 8; job architecture 8; logistics 8; economy 8; world architecture 8; visual readability 7; UI 8; Web 8; performance 8; modularity 8; stability 8. Average 7.85. Stronger vehicle detail and tracking do not erase sparse scenery, limited flight/suspension realism, placeholder character animation/audio or the lack of broader hardware testing.

M32 fixed checkpoint: 215 source/asset files preserved in `m32-source` with SHA-256 manifest. Full default native regression started against that copy; no combined pass claim until completion.

## Milestone 33 / round 01 — cargo cart presentation

- Current cart is an undetailed open box with solid wheels. Added a modular CartVisual with wooden slats, corner straps/bolts, red wheel guards, open spokes, drawbar and tied canvas roll within the existing approximate height. Shared wheel construction with the motorcycle. No canopy/physics expansion.
- Replaced cargo mesh destruction/recreation with three fixed MultiMesh pools for up to eight strapped crates; inventory still owns exact quantities/mass. CargoCart retains movement/collision and delegates visual load/spin. Existing cart, ground, cargo-access, bike and save verification plus rendered/Web inspection will check integration.
- Remaining budget 19/20. Visual/cart scores remain 7 pending acceptance. M32 fixed-source regression runs separately and its source remains immutable.

M33 native: cart 25/25, slope 11/11, cargo access 11/11, bike 26/26 and save 22/22. Rendered loaded cart shows slatted sides, red guards and tied roll with retained wheel contacts. The render probe performed 100 load/unload cycles: 177 cart descendants before and after, then 80 mass displayed; no node growth. Evidence `m33-rendered-round1.log`, `cart-native-detail-empty.jpg`, `cart-native-detail-loaded.jpg`. Web cart and same-view rendering budget checks pending. Remaining budget 18/20.

## Milestone 34 / rounds 01–02 — readable enemy strike commitment

- Baseline native 6/10: attack turned instantly after the visible windup, hitting targets moved behind/to the side. Hit interruption also left Hit sooner than its configured duration because accumulated pre-hit decision time carried into the new state. Baseline report archived. Front damage/one-hit, pause, cover and death already passed.
- Added a 0.35 s aim-commit point before the 0.55 s strike, a 100-degree forward hit cone, and reset decision accumulation on state transitions. A single reusable ground-sector cue and timed arm motion show windup/strike direction. Damage/range and cover checks remain unchanged.
- Files: `ai/combat_brain.gd`, `ai/enemy_actor.gd`, new `ai/enemy_attack_cue.gd`, `tests/enemy_strike_verifier.gd`. Native/Web and combat/AI/encounter/integration checks pending. Remaining budget 18/20.

M33 final acceptance: Web cart 25/25 in 12.160 s and UI 15/15 in 4.027 s, clean current-run logs. Village rendering is 387 draw calls / 120 FPS in Web; native same-view 387 / 111 FPS while other checks were running. This is +12 draw calls for the cart detail, within the existing <400 budget. Fixed cargo pooling showed no growth through 100 load/unload cycles. Cart physics remains 7, visual readability 7, performance 8, modularity 8, stability 8. No full suspension or finished asset claim.

M34 native acceptance: enemy strike 10/10, rendered 10/10 (10.403 s), combat 34/34, AI 10/10, regional encounters 16/16 and integration 16/16. `enemy-native-windup.jpg` shows the visible forward strike area. Web pending.

## Milestone 35 / round 01 — food and recovery

- Olives already pass through the resource/worker/shop economy but had no player recovery use. Added X to eat one carried olive for up to 25 HP while stopped on foot. Full health, missing food, pause, movement, dodge, riding, attacks/reloads and death reject consumption.
- New `resources/consumable_use.gd` owns input latching and guarded food/health transaction; Main injects references and pause state. Health commits before inventory notification, with rollback if removal fails and a guard against recursive use. No new save fields: existing health/backpack state carries the result.
- Native/Web input, concurrency, conservation, source-to-food and save checks pending. Remaining budget 19/20. Gameplay/economy scores remain 8 pending acceptance.

M34 final Web: enemy strike 10/10 in 10.294 s, full integration 16/16 in 103.077 s, clean current-run consoles (`enemy-strike-web-*`, `integration-web-m34-*`). AI/readability involved remain 8; fixed ground cue is an approximate planar indicator on sloped terrain.

M35 first native 16/16 in 5.3 s. Added an explicit same-frame X+attack case beyond the existing active-attack rejection and an opt-in rendered healing capture. Expanded 17-check run pending; remaining budget 18/20.

M32 fixed-source regression completed: 463/463 assertions across 30 native suites; all 215 source/asset hashes still match. Summary `m32-regression-summary.json`, full log `m32-full-regression.log`, reports/logs copied to `m32-validation`. Later M33–M35 work has separate targeted results and is not included in this checkpoint claim.

M35 expanded native acceptance: food 17/17, rendered 17/17 (6.349 s), UI 14/14; previous combat 34/34, save 22/22 and logistics 23/23 pass. Capture `ui-native-food-recovery.jpg` shows orchard stock reduced by one and health 65/100 after eating. Final Web pending.

## Milestone 36 / round 01 — distinct enemy silhouettes

- Raider and Cinder beast previously shared a box-person shape, differing mainly in color/horns. Added separate EnemyVisual presentation: clothed masked humanoid with limbs/tool, and a compact horned quadruped with claws/tail/spines. Actor collision, health, navigation and attack rules stay in EnemyActor/CombatBrain. Rigid pieces batch by material; movement joints remain independent.
- Reused the live strike suite for both kinds, with each kind's configured damage, plus combat/encounter regressions and native/Web render review. Files: `ai/enemy_visual.gd`, `ai/enemy_actor.gd`, strike verifier factory and `beast_strike_verifier.gd`. Remaining budget 19/20; visual readability stays 7 pending inspection.

M35 final Web acceptance: food 17/17 in 5.902 s, clean current-run console (`food-web-report.json`, `food-web-console.json`). Food uses real pack stock and existing health persistence; no revival or remote cart consumption. Economy/stability remain 8.

M36 round 02: corrected gait phase ordering and attack-arm ownership after reviewing the initial joint list. Both kinds pass native/rendered/Web strike 10/10; native combat 34/34 and encounters 16/16. Side captures show distinct silhouettes, while the head-on beast capture is occluded by the player; lock-on framing will receive a separate adversarial pass. UI native rendered 15/15, 355 calls /119 FPS, but Web 14/15 with 411 calls /119 FPS exceeds the existing <400 budget. Not accepted yet. No console errors. Retained failed report/capture as `ui-web-m36-*`; remaining budget 18/20.

M36 round 03 diagnosis: native UI screenshot faced 287 degrees and had fired one unintended round, while Web retained the intended 0-degree view. A menu-close pointer capture during native verification allowed external mouse movement to change the benchmark. Verification sessions now keep the native pointer visible, including momentary real-key dispatch, and the budget sample pins its intended camera. The Web over-budget finding remains valid. Added a narrow ColorBatch for opaque BlockoutKit pieces, baking color into one surface per rigid joint; other materials stay untouched. Existing batching checks now include geometry/color conservation. Godot vertex-color setting reference: https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html#class-basematerial3d-property-vertex-color-is-srgb . Remaining budget 17/20.

M36 round 03 results: new color batching passes 8/8 native; Web UI now passes 15/15 at 376 calls /120 FPS. Native fixed view also measures 376 /119 FPS, but its final screenshot waits forever when the native window stops drawing in the background. Capture now requests a render explicitly instead of awaiting a future frame; the incomplete run is retained. Remaining budget 16/20.

## Milestone 37 / round 01 — lock-on framing

- Actual camera-ray baseline: 11/12 native. A locked beast at melee range is centered but its head is hidden behind the player; human head visibility, framing, pause, unlock, range, cover, death and moving target follow pass. Add a modest melee lock shoulder offset, with character facing kept directed at the enemy, then verify the camera/collision/combat consequences. Baseline report/log retained. Remaining budget 19/20.

M36 final acceptance: ColorBatch geometry/color 8/8 native/Web, both enemy strike kinds 10/10 native/rendered/Web before the batching-only optimization; optimized native strike suites remain 10/10 each. Corrected UI 15/15 native/rendered and Web, matching 376 submissions. Final native capture completes using force_draw; its reported 137 FPS includes forced capture frames and is not a runtime performance claim. Web normal loop measures 120 FPS. Side captures retain both colors and silhouettes. Visual score remains 7, performance/modularity/stability 8; geometric animation and short-enemy occlusion are still named limitations.

M37 round 02: shoulder offset fixes the hidden beast, but the suite remains 11/12 because pause allows the orbit pivot's residual smoothing to continue. This was hidden with the old centered camera. Main now suspends orbit physics alongside the player when paused; explicit camera snap during restore still works. Rendered frame and focused/regression rerun pending. Remaining budget 18/20.

M37 native acceptance: 12/12 headless and rendered, combat 34/34, chase camera 12/12, save 22/22 and UI 14/14. The rendered beast head is visible beside the player. Web underway.

## Milestone 38 / round 01 — shoulder-camera clearance

- Baseline 3/6 native: a wall beside the player contains the offset pivot and the camera itself (x=0.700 inside x=0.45–0.75). Existing rear SpringArm compression/recovery passes. An origin already inside cover cannot be rescued by the rear arm sweep.
- Added a small sphere sweep from the player pivot toward the requested shoulder position, also constraining the smoothed position and explicit snap. Lock aim uses the actual constrained offset. World collision mask stays 1. Verify immediate wall appearance, shoulder recovery, rear arm behavior and native/Web regressions. Baseline preserved; remaining budget 19/20.

M37 final Web acceptance: 12/12 in 13.762 s, clean current-run console (`lock-framing-web-*`). Camera/melee/stability remain 8. M38 separately addresses adjacent-world collision; this pass does not claim that pending work is complete.

M38 first corrected native: 6/6. Expanded to eight checks requiring new side cover to resolve within three physics frames and handling a rotated wall/camera. Existing backward-arm checks still pass. Remaining budget 18/20.

M38 native acceptance: expanded rendered clearance 8/8 (5.861 s); initial focused 6/6 plus lock framing 12/12, traversal 21/21, combat 34/34, chase camera 12/12 and saves 22/22. Side-cover pivot is constrained to 0.230 m versus the failing 0.700 m baseline. Web eight-check run underway.

## Milestone 39 / round 01 — traveler and worker presentation

- Render review still shows a box torso, disconnected neck/head and flat boots on the player and friendly worker. Updated shared PlayerVisual with a shaped coat, connected neck, goggles, scarf, strapped backpack/roll, cylindrical limbs and grounded boots. Stable joint origins and animation interfaces preserve weapon attachments and bike rider pose.
- Reuse ColorBatch per rigid joint, and existing traversal/combat/bike/worker/UI tests plus actual close renders. This is visual refinement within the collision envelope, not a new rig or final character art. Original source/image preserved. Remaining budget 19/20.

M39 round 02: presentation helper captured the previous camera pose because force_draw does not flush Node3D transform notifications by itself. First images are not accepted. Added two physics frames between setting a new capture camera and forcing the render. This is a helper issue, not a new runtime camera failure. Remaining budget 18/20.

M38 final Web acceptance: shoulder clearance 8/8 (5.497 s) and lock framing 12/12 (13.725 s), clean current-run consoles. Camera/stability remain 8; no claim of exhaustive tight-interior human camera testing.

M39 second rendered review: front/back and mounted views now show the correct current camera transform. The actual seat API reports mounted=true; the rider's gloves remain at the bars and boots/legs remain coherent. Front wrench attachment stays at the hand. Captures `avatar-m39-front/back/riding/worker.jpg`. Traversal 21/21 and combat 34/34 pass; bike/worker/UI and Web pending. Remaining budget 17/20.

M39 native: traversal 21/21, combat 34/34, bike 26/26, worker 25/25 (158.8 s), UI 14/14 and rendered 15/15. Pinned native village 335 calls /119 FPS. Web combat 34/34 (31.999 s), clean; bike/UI pending.

## Milestone 40 / round 01 — fixed current-source regression

- Added `tools/checkpoint.py` to preserve uniquely named source copies, SHA-256 manifests, full native logs/reports and a summary which rejects any changed file, missing suite, failed assertion or low assertion count. Existing checkpoint paths are never overwritten.
- Native save/economy verifier files now include the process ID, so concurrent verification processes cannot clobber each other's fixtures. Web resume probes remain intentionally stable; production user saves remain unchanged. Verification mouse-session flag resets after the suite returns.
- Current catalog: 35 default suites /523 minimum assertions; adding continuous flight gives 36 /529. Full fixed-source run, including long flight, will run alongside separate Web checks. No combined pass claim before completion.

M39 final Web acceptance: combat 34/34, bike 26/26, UI 15/15 (4.155 s), clean current-run consoles. Matching village submissions: 335 native/Web; Web 117 FPS with concurrent native work. Visual score remains 7; this is still simple geometry and animation, with a floating rifle carry pose queued for review.

M40 fixed snapshot created: 243 managed source/asset files; full 36-suite native run seeks 529 assertions including continuous flight. Source: `m40-source`; manifest: `m40-source-manifest.json`. A separate Web export is being built under `builds/web/checkpoints/m40` so later live edits cannot change its long-flight run. No completion claim yet.

## Milestone 41 / round 01 — attached rifle and weapon presentation

- Before render `avatar-rifle-before-m41.jpg` confirms the rifle floats while both hands hang down. Added `WeaponVisual` for wrench/rifle geometry, rifle hand attachment and a small reload bolt motion; PlayerCombat still owns timing, damage, cover rays, ammunition and action gating.
- Rifle adds a wooden stock, cylindrical barrel, bands, sights and bolt silhouette. Wrench adds a cylindrical shaft and open jaw. This is a simple one-hand placeholder carry/aim pose, not full two-hand IK or a final reload animation. Existing combat/feedback/save/integration and rendered/UI checks will verify compatibility. No new mirror test for geometry. Remaining budget 19/20.

M41 first render: rifle is visibly attached to the right glove with a clearer wood/metal silhouette (`avatar-rifle-m41.jpg`); native combat 34/34 and feedback 9/9 pass. Capture helper now accepts a prefix to keep later weapon pictures from overwriting earlier avatar evidence. Regenerating M39's static presentation views from the untouched M40 snapshot; those source visuals match M39. No snapshot source edits. Remaining budget 18/20.

M41 native acceptance: combat 34/34, feedback 9/9, save 22/22, integration 16/16 (102.6 s), UI 14/14 and rendered 15/15 (335 calls /119 FPS). Web checks wait for the separate fixed-source long-flight run; current Web export builds cleanly.

## Milestone 42 / rounds 01–02 — cargo/orders combat input gate

- Baseline 5/15 native: cargo/worker panel clicks and keyboard inputs fire weapons; a pending swing/reload continues when the panel opens; simultaneous panel-open/attack leaks a shot. Movement, held-input close, fresh attack and dodge lifetime already pass.
- Panel owners expose `blocks_combat_input`, including pending or same-frame toggles. Main injects a Callable into PlayerCombat; the gate rejects actions and cancels pending attacks/reloads while preserving movement and the current dodge immunity window. HUD says PANEL OPEN and hides the rifle crosshair. Weapon visuals remain attached while the panel is live.
- Changes: PlayerCombat, Main, LogisticsWorld, WorkerManager, GameHUD and a 15-case real-input suite. Existing worker/logistics/UI/combat/save interactions require regression checks. Remaining budget 18/20.

M42 focused native acceptance: 15/15 in 8.4 s. Added an opt-in rendered worker-panel capture for the PANEL OPEN status and hidden crosshair. Broader regressions are running. Remaining budget 17/20.

M42 rendered round 02 failed 14/15 despite focused headless 15/15: the first cargo-click assertion fails; remaining panel, concurrency and immunity checks pass. Added diagnostic values to distinguish a leaked shot from a panel-opening fixture problem. No rendered acceptance claim. Screenshot confirms PANEL OPEN and hidden crosshair in the later worker case. Remaining budget 16/20.

M42 rendered round 03 diagnosis: panel=false, ammo=4, gate=false. The first fixture's synthetic Input.action_press lasted two physics ticks while initial native rendering batched those ticks before LogisticsWorld._process could observe them; no cargo panel was actually open. Real key events use the existing latched toggle. Changed panel setup to inject physical key events and wait for an idle frame before clicking; retained the same-frame key concurrency cases. Production input gate unchanged. Remaining budget 15/20.

M42 corrected rendered acceptance: 15/15 (9.754 s), first cargo case explicitly reports panel=true, ammo=5, gate=true. Screenshot shows the live worker panel with PANEL OPEN and no crosshair. Native focus-loss handling now checks the whole verification session, so brief global-key dispatch cannot accidentally pause a rendered test. Ordinary gameplay focus-loss pause remains active. Remaining budget 14/20.

M40 fixed Web long flight: 6/6 in 719.933 s; 23,954 m continuously crossed, peak 25 terrain chunks, 1,895 created /1,870 retired, maximum build 4.70 ms, no missing terrain and clean current-run console. Evidence `distance-web-m40-report.json`, console and capture; served from the fixed `/checkpoints/m40/` export. This validates architecture/performance, not populated content across that distance. Full native checkpoint remains in progress.

M42 native final: corrected real-input suite 15/15 (8.7 s), combat 34/34, UI 14/14, food 17/17, logistics 23/23, worker 25/25, save 22/22 and rendered panel 15/15. Final Web suite is running against the latest live export.

M42 final Web acceptance: 15/15 in 9.135 s, clean current-run console. Live panel clicks, keyboard attacks and simultaneous open/fire no longer spend rounds; interrupted reload/swing transactions cancel; movement and dodge immunity retain their normal behavior. UI/combat/stability remain 8, with later fixed-source regression still separate.

## Milestone 43 / rounds 01–02 — deployed wing collision follows attitude

- Baseline 3/8 native. Visible wingtips leave the level collision box during both banks and a climb; an attitude can also put a wing through a nearby solid. Real takeoff, the sampled descent and grounded pose pass.
- Wing collision now follows BikeVisual's local transform, including pitch/bank and visual ground offset. Proposed fully deployed attitudes are checked against world geometry; a blocked attitude retains the previous visual/collision pose. Deployment clearance uses the same transformed wing shape. Upright main vehicle collision and flight control laws stay unchanged.
- Files: VehicleTransformation, BikeController and wing_pose verifier. Focused and flight/seat/ground/save/airmail regressions pending; remaining budget 18/20. Partial folding geometry still uses the existing disabled wing collider and remains a separate limitation.

M40 native progress: all 35 default suites have passed (523 assertions); the final continuous-flight suite is still running, so the complete 36-suite checkpoint has not yet been accepted.

M43 first corrected native: 7/8. Both bank directions, climb/descent, grounded wings and blocking an intersecting attitude now pass. The final cleared-obstacle attitude assertion fails; added pose/support/process diagnostics before changing production behavior. Remaining budget 17/20.

M43 round 03 diagnosis: cleared wing collision is supported=true, but the world tier updater re-enabled the deliberately frozen fixture bike, easing its roll from 0.300 to 0.238 before inspection. Disabled tier updates only for the staged obstacle-pose fixture. Real takeoff/bank/climb/descent cases still run normal vehicle physics. Production change unchanged; remaining budget 16/20.

M41/M42 combined Web acceptance: combat 34/34, UI 15/15 and full delivery/combat/worker integration 16/16 (103.587 s), clean current-run consoles. Latest weapon visuals and the panel gate coexist through the real drive, dismount, wrench/rifle encounter, remount, delivery and automated harvest/sale. Rifle/UI/stability remain 8; no full two-hand rig claim.

M43 native acceptance: wing pose 8/8, rendered 8/8 (11.295 s), flight 22/22, seat safety 12/12, vehicle ground 11/11, highland flight 8/8, save 22/22 and regional airmail 12/12 (99.5 s). Web wing checks underway.


M40 final acceptance: 529/529 across 36 native suites in 1,827.049 s, including 719.670 s continuous flight; all 243 source/asset hashes unchanged. `m40-regression-summary.json` accepted=true and `m40-validation` preserve results. Its separate fixed Web long flight passed 6/6. Conservative rubric remains 7.85; streaming distance is not a content-density claim.

M43 final Web acceptance: wing pose 8/8 (10.883 s), flight 22/22 (18.576 s), clean current-run consoles. Flight remains 7 and transformation/stability 8; wings now follow their visible bank/pitch but partial transformation collision remains limited.

## Milestone 44 / rounds 01–02 — undercarriage touchdown support

- Baseline 4/8: a deployed wing resting on an elevated narrow ledge sets landed=true while the chassis floats at y=18.541 above the base terrain; landing count increments and folding/saving become available. A proper elevated runway already passes.
- BikeFlightController now requires a short actual-world support ray beneath at least one chassis axle as well as a floor contact. The upright physical chassis defines support, preserving the arcade controller's decorative pitch. Normal checks retain walkable slopes; elevated geometry is supported without relying on the procedural terrain height.
- Focused corrected native 8/8 and normal flight 22/22. Flight/highland/wing/seat/save/airmail regressions, native capture and Web are pending. Flight stays 7; no physical landing-gear suspension claim. Baseline report/source retained. Remaining budget 18/20.


M44 native acceptance: touchdown 8/8 headless and rendered (4.278 s), flight 22/22, highland 8/8, wing pose 8/8, seat safety 12/12, save 22/22 and regional airmail 12/12 (99.5 s). Rendered ledge capture shows wheels hanging below the supported wing. Web export built; browser focused checks underway.

## Milestone 45 / rounds 01–02 — loaded towing maneuvers

- Baseline 10/12: full-load forward turn overlaps bike/cart bodies for 42/240 frames; reverse turn overlaps for 213/240. Distance constraints, cargo conservation and forward recovery pass. Test uses normal mounting/hitching/input on a flat elevated fixture to separate steering defects from terrain.
- Cart previously ignored the bike collision layer; it now collides with world + bike (mask 9). A shared VehicleClearance shape query rejects yaw changes that would rotate attached bike/cart into each other; CharacterBody continues to sweep translation.
- Files: CargoCart, BikeController, VehicleClearance, towing verifier/catalog. No suspension or trailer momentum model added. Focused corrected run pending; broad native/rendered/Web towing and integration are required before acceptance. Cargo/cart remains 7. Baseline source/report retained. Remaining budget 18/20.


M45 round 03: original 12/12 and rendered 12/12 pass with no solid overlap, but an expanded straight-recovery check fails (14/15). The cart stays beside/ahead of the bike after 34 m of straight driving: local (-1.472, 0.070, -0.384). Merely measuring motion and maximum separation was insufficient. Source computes its drawbar target from smoothed yaw, so a collision-blocked rotation continually drags the cart sideways. Target now uses the actual hitch-to-axle direction, independently of collision-safe visual yaw. Expanded native 15-check run pending. Remaining budget 16/20.


M44 final Web acceptance: touchdown 8/8 (3.746 s), regional airmail 12/12 (99.895 s), clean current-run consoles. Normal parcel flight crosses 1,172 m, lands on destination terrain, folds, rides to the desk and pays once. Flight remains 7; M45 cart work is separately pending.

M45 round 04: expanded native 15/15 (24.139 s). Forward/reverse/recovery have zero penetrating frames; the final straight pull restores the cart to local (0.000004, 0.070002, 3.300017), after 33.977 m. The initial regression pipeline began before the final drawbar correction, so it is exploratory evidence and will not be claimed as validation of the final source. Repeating relevant checks on the final source and an updated native capture/Web build. Remaining budget 15/20.


M45 focused Web acceptance: 15/15 (24.638 s), clean current-run console. The cart returns to 3.300 m behind the bike after straight recovery; full-load turn/reverse/recovery have zero penetrating frames. Expanded native render 15/15 (24.963 s). Final production towing source is unchanged while broader regression/integration completes.

## Milestone 46 / round 01 — vehicle state guidance

- Render critique: the deployed aircraft HUD always suggests climb, even below takeoff speed, and provides no persistent low-airspeed warning. General movement hints still say jump/dodge while mounted.
- Added VehicleHUD as a presentation-only component: speed strip, cargo weight, clear deployed/takeoff-ready/in-flight/low-airspeed states, AGL units and appropriate controls. Ground/flight laws remain in vehicle controllers. GameHUD updates general mounted control hints.
- Reuse existing UI and real flight suites, with captures at actual runway/ready/climb/descent states. No additional assertions for cosmetic implementation. Initial native UI 14/14 and flight 22/22; native visual review and Web pending. UI remains 8, flight/visual 7. Remaining budget 19/20.


M45 final acceptance: final towing code passes cart 25/25, bike 26/26, cargo access 11/11, ground pose 11/11, seat safety 12/12, integration 16/16 (102.5 s) and save 22/22 native. Web full delivery/combat/worker integration 16/16 (103.618 s), clean. Cart remains 7 because motion is kinematic without suspension or trailer momentum; correcting overlap does not establish realistic physics.

M46 native visual acceptance: flight 22/22 rendered (18.961 s), highland 8/8 rendered (39.050 s). Actual low-speed flight at 5 m/s and vertical -4.30 m/s displays LOW AIRSPEED / Hold W to recover; runway and ready captures show the correct distinct guidance. Web highland 8/8 (38.599 s) with clean console. UI/Web final result recorded separately; no extra visual-only assertions were added.

## Milestone 47 / round 01 — Greenreach delivery destination

- The forest camp is a discoverable landmark but had no delivery role. Added a third courier offer to Greenreach (-3600,716), paying 500 crowns. O now cycles the catalog; save validation derives accepted IDs from that same catalog. Existing route locks, receipt transactions and legacy default are reused.
- RegionScenery adds timber stockpiles and a cutting bench to distinguish the forest camp. Its delivery desk already uses the bounded remote-station visibility interface.
- Extended route checks for catalog cycling, acceptance and forest save restore. Shared airmail driver now takes scenario data; a second scenario must physically cross over 3.2 km, land, approach the camp and deliver once, with no pose changes after acceptance. Existing Longfield flight remains a separate regression.
- Files: DeliveryRoute, LogisticsWorld, RegionScenery, routes/airmail/forest_airmail verifiers and catalog. Current native pipeline pending. World/economy 8, visual 7; this is one additional useful endpoint, not a populated forest region. Remaining budget 19/20.


M46 final Web acceptance: UI 15/15 (4.187 s), matching 335 village draw calls /118 FPS, clean console. Together with Web highland 8/8 and native state captures, contextual instruments are accepted. No flight handling score increase from display changes.

M47 route checks: 20/20 native including the new three-offer input cycle and forest parcel save restore. Both native headless and rendered forest journeys have accepted the parcel, prepared the cart, driven out of town and taken off; long-route traversal/arrival remain in progress. Remaining budget 18/20.


M47 native forest journey: 12/12 headless (171.064 s) and rendered (171.992 s); 3,636.7 m traversed before descent, real landing and ground approach, 500 crowns paid exactly once, parked cart intact. The arrival capture is before the HUD's 0.25-second text refresh and still displays IN TRANSIT despite the committed transaction; it is retained as timing evidence, not a completed-status screenshot. Browser forest flight and existing-route/region/save regressions are underway.

## Milestone 48 / round 01 — next fixed-source regression

- Frozen 259 source/asset files as `m48-source`; SHA-256 manifest preserved. Run all 40 default suites, seeking 585 minimum assertions on this exact copy, while live work remains independent. Includes the longer forest delivery. The twelve-minute continuous-flight architecture was already checked in M40; this checkpoint focuses on the expanded default gauntlet.
- Completion requires every suite, minimum counts and all source hashes to match. No full-source acceptance before the process completes. Remaining budget 19/20.


M47 native regression acceptance: route transactions/save 20/20, forest airmail 12/12, original Longfield airmail 12/12 (99.5 s), region 18/18 and save 22/22. Web forest journey 12/12 (171.630 s), clean current-run console; over 3.6 km flown before landing/ground approach, correct single payment. Forest route transactions in Web remain to be recorded separately. The world still has sparse procedural scenery between useful landmarks.

## Milestone 49 / round 01 — camera-proximity foliage in the core

- M46's runway capture shows a near tree crown covering a large part of the view. Regional foliage already dithers near the camera, but the authored core's tree/cypress materials stay opaque.
- Extracted the existing regional fade into cached FoliageFade materials and a shared shader, then applied it to core tree trunks/crowns and cypresses. MultiMesh instances preserve their centers; custom shader meshes stay outside static material batching. Small shrubs/grass keep their existing materials.
- This is camera readability, with collision and terrain generation unchanged. Reuse native/Web UI/region/flight tests and repeat the same runway capture; no mirror assertion for shader code. Native UI 14/14 and region 18/18 pass; image/performance review and Web pending. Camera stays 8 and visual 7. Remaining budget 19/20.


M49 first rendered review: flight 22/22 (19.320 s); repeated runway capture shows the formerly opaque near crown dithering so terrain and the wing remain visible. Clustered crowns fade independently; this is a cheap camera-proximity effect, not final foliage or transparency. Native UI 14/14, region 18/18 and flight 22/22 pass. Rendered/UI budget and Web checks underway. Flight capture helper now accepts an explicit prefix to preserve earlier milestone images. Remaining budget 18/20.


M47 final Web route acceptance: 20/20 (4.975 s), clean console, including O cycling all three offers and forest parcel save restore. M47 now has native/rendered/full-flight Web acceptance. Economy/world remain 8 and visual 7.

M49 UI budget: 15/15 rendered (4.597 s) and Web 15/15, matching 346 draw submissions. Web measured 113 FPS with concurrent native verification; native 118 FPS. The 11-call increase comes with separate camera-fading cypress materials and remains under the existing 400-call budget. Streamed region/Web compatibility checks still underway.

## Milestone 50 / round 01 — persistent rider health

- Review of mounted captures: the only health readout lived inside the combat panel, which hides while riding. The persistent lower-left panel showed stamina instead, so a wounded rider had no visible HP.
- GameHUD now keeps labeled health and stamina bars together, in both on-foot and mounted states. The combat card focuses on weapon/action/ammo; the stamina state says RIDING while mounted. No changes to damage, immunity or recovery.
- Reuse UI, bike, combat and food regressions. A presentation helper applies production hostile-faction damage to a mounted player and captures the damaged and post-death recovered readouts. This helper is not an enemy-AI encounter claim and adds no cosmetic assertion count. Native/UI/Web review pending. UI/stability stay 8. Remaining budget 19/20.


M49 final Web acceptance: region 18/18 (33.877 s), including deterministic regeneration, and flight 22/22 with a clean current-run console, alongside UI 15/15 /346 calls. Camera/visual scores remain 8/7; independent crown fading and simple dither remain limitations.

M50 native acceptance: UI 14/14, bike 26/26, combat 34/34, food 17/17; rendered UI and damage/recovery captures complete. Production damage helper reports mounted=true, accepted=true, health=65, readout=65/100; after mounted death, mounted=false, actor visible=true, health/readout=100/100. No enemy encounter was staged for the helper. Web export/regression pending.


M50 final Web acceptance: UI 15/15 with 349 submissions /112 FPS, and bike 26/26 (18.162 s), clean consoles. Native rendered UI 15/15 (4.959 s) at 349 /119 FPS. Mounted damage/readout and death/recovery captures show the persistent health display. UI/stability remain 8.

## Milestone 51 / rounds 01–02 — stable resource source identity

- Expanded baseline 1/9: two wood sources holding 17 and 9 units serialize to the same source_wood entry and both restore as 9. Reordering the source array also assigns the wrong source to a worker timber job. Duplicate/missing source identities and invalid secondary stock are not rejected.
- ResourceSource now has explicit source_id/save_key. The three original nodes keep IDs olive/ore/wood, preserving existing v1 keys. Save validation rejects missing/duplicate registered IDs and validates each independent stock before mutation. Worker jobs resolve source IDs through LogisticsWorld instead of array positions.
- Files: ResourceSource, LogisticsWorld, WorkerManager, SaveSchema/System and a nine-case source_identity verifier. No new harvest node is registered yet. Focused corrected native 9/9 and save 22/22 pass; worker/routine/routes and Web remain in progress. Baseline source/report retained. Persistence/modularity remain 8. Remaining budget 18/20.


M51 final acceptance: native source identity 9/9, save 22/22, worker 25/25 (158.9 s), routine 16/16 (188.5 s), routes 20/20. Web identity 9/9 (1.505 s), save 23/23 (31.208 s) and fresh-page resume 4/4 (1.954 s), clean consoles. Stock quantities, original v1 keys and worker cargo survive reload. Worker/routine runs started before M52; the final route regression also coexists with the subsequent optional regional stock extension.

## Milestone 52 / rounds 01–03 — harvestable Greenreach timber

- Initial feature baseline confirms no registered forest reserve (0/1). Added an independent 60-unit wood source at (-3613,716), with proximity visibility and the existing gather/pack/market APIs. Timber sources now display cut logs instead of a generic gray resource sphere.
- Stock revision 2 adds regional depletion to snapshots. A missing revision means the old revision 1: only sources introduced later receive their configured initial stock. Current-revision missing/invalid stock is rejected; old core keys and quantities remain intact. Save version remains 1 with an explicit optional stock revision.
- Initial native forest checks 14/14, source identity 9/9, save 22/22 and logistics 23/23. Strengthened the migration fixture to deplete the original timber yard to 17, so a buggy blanket reset to 60 cannot pass. Focused rerun, native source capture and Web are pending.
- Tests cover distance gating, gathering/capacity, independent save restore, malformed/current/future saves, legacy migration, leaving/returning and sale of harvested timber. Endpoint tests deliberately relocate the player; M47 separately proves travel to Greenreach. Remaining budget 17/20. Logistics/world remain 8; forest content is still limited.


M48 final fixed-source acceptance: 585/585 across all 40 native suites in 1,325.190 s. All 259 managed source/asset hashes unchanged; `m48-regression-summary.json` accepted=true, with logs/reports in `m48-validation`. This snapshot predates M49–M53; later work is validated separately. Rubric stays 7.85.

M52 native strengthened acceptance: forest resource 14/14 headless and rendered (6.837 s), including legacy migration preserving village=17 while initializing forest=60. UI 15/15 rendered (4.608 s), unchanged 349 calls /120 FPS. Web forest resources 14/14 (6.051 s), save 23/23 (31.236 s) and restart 4/4 (1.929 s), clean consoles. The four-check restart probe proves general persisted state, but did not explicitly assert forest depletion; expanded the probe to store 17 forest timber, restore live stock, then require 17 after a fresh page. This stronger Web check is pending. Remaining budget 16/20.

## Milestone 53 / round 01 — Willowmere inland lake

- Added a small lake near Longfield, center (620,1150), with a 90 m water radius and a 110 m terrain basin. RegionalLake supplies the CPU carving parameters and the distant horizon shader uniforms. A single visual-only surface has a 1,000 m visibility range; the world map labels Willowmere.
- WaterBody supports elliptical bounds. WaterSafety checks the sea plus a bounded list of additional bodies through the same depth/recovery/save rules. Regional foliage skips submerged ground. Existing coastline remains active through its original resource.
- New lake verifier: 14/14 native, covering shared bounds, ellipse corners, horizon parameters, dry bank/wading, underwater collision, save rejection, pause/recovery, inventory preservation, bike recovery and bounded surface/residency. Existing coastal water 12/12 and Longfield airmail 12/12 pass; world/backdrop/region/save and native visual review/Web are pending.
- No swimming, boat, river simulation or full hydrology is implied. The lake is an authored addition to otherwise sparse terrain. World/logistics remain 8 and visual 7 pending review. Remaining budget 19/20.


M53 native acceptance: lake 14/14 headless and rendered (14.980 s); sampled wading depth 0.979 m, basin collision y=7.984. Shore capture shows the lake surface bounded by actual terrain. Coastal water 12/12, original airmail 12/12, world 15/15, backdrop 7/7, region 18/18 and save 22/22 pass. Browser checks are next. Rendering and safety share ellipse bounds, but no swimming/shore waves or hydrology simulation has been added. Remaining budget 18/20.


M52 final strengthened Web acceptance: save 23/23 and fresh-page resume 5/5, clean consoles. The probe saves forest stock=17, restores live stock, reloads a fresh page and explicitly requires 17. This closes the cross-page depletion coverage gap rather than inferring it from other saved fields. M52 accepted; logistics/persistence remain 8.

M53 Web lake acceptance: 14/14 (14.864 s), clean current-run console, with the same inland wading/collision/save/pause/recovery/bounds behavior as native. Native UI 15/15 at 349 calls /109 FPS under concurrent work; browser world-map/UI review is underway.

## Milestone 54 / rounds 01–02 — delivery completion feedback

- Arrival review: the success signal's reward message is overwritten by generic Done, and repeating U replaces it with an inaccurate approach-a-desk error. The completed objective still suggests U accept although repeating needs Shift+U.
- LogisticsWorld now formats feedback from the committed delivery state: paid amount on success, already-completed/repeat guidance afterwards, and current destination when a parcel is still in transit. GameHUD shows the completed-route command. Short two-line notifications keep long route names readable.
- Transaction logic and input guards remain unchanged. Reuse economy/routes/UI regressions and a rendered transaction fixture; no new cosmetic assertions. First native economy/routes/UI pass, final shorter wording and captures are being checked. UI/economy remain 8. Remaining budget 18/20.


M53 final UI/Web acceptance: 15/15, 349 submissions /113 FPS, clean console. M54 final acceptance: native economy 21/21, routes 20/20 and UI 14/14; Web economy 21/21 and routes 20/20 (4.162 s), clean consoles. Rendered fixture shows the 75-crown notification and an unchanged 95-crown balance after repeating U; completed guidance is readable. Static station labels still describe the desk's general role.

## Milestone 55 / round 01 — independent worker roster

- Adversarial starting point: only Mara exists and persistence serializes workers[0]. Adding a second actor alone would silently drop its cargo/job state on reload and let global routine fields cross-control workers.
- Plan: stable worker IDs; per-worker routine state; select Mara/Ivo in the existing N panel; preserve the original worker save field and explicitly version additional roster records. Validate every record before mutation and initialize only newly introduced workers when loading legacy files.
- Baseline and implementation/regression work underway. Test actual independent jobs, cargo conservation, routine isolation, malformed secondary state and legacy migration, including browser restart. No worker/visual score increase is assumed. Remaining budget 19/20.


M55 round 02: first independent-worker run 22/22 (71.878 s), including two real resource jobs, one shared-warehouse sale and routine completion ownership. Strengthened cases add null record/container rejection and a nonzero legacy Mara fixture, bringing the planned minimum to 24. The expanded Web restart probe initially failed GDScript parsing because dynamic Ivo/cargo values used inferred types; explicitly typed WorkerActor/Dictionary and rerunning. This was isolated to the optional save verifier, not a gameplay failure. Existing worker/routine/integration regressions are in progress. Remaining budget 18/20.


M55 round 03: strengthened native roster 24/24 (71.9 s). Eight malformed secondary-record variants reject before either worker/stock mutates; legacy fixture preserves Mara's 7 completed jobs and 2 ore while initializing only Ivo. Real jobs deliver 5 olives and 5 timber once; Ivo then sells Mara's harvest for 20 crowns. Actual routine completion leaves Mara cycles=1 /Ivo cycles=0. Rendered UI 15/15 at 354 calls /120 FPS; panel fits and names the selected worker. Finishing stopped routines now say Finishing current job. Save/Web probe fixes and remaining regressions are still running. Remaining budget 17/20.


M55 adversarial round 04: existing worker checks reached 25/25 but the runner correctly rejected two cleanup errors after a temporary worker was freed. Routine-state pruning passed that stale object into a typed workers.has call. Guarded instance validity before typed-array lookup and added a direct retirement regression (roster minimum now 25). Failure log retained as m55-retirement-failure.log. Earlier successful assertion counts do not constitute acceptance of that errored run. Remaining budget 16/20.


M55 additional acceptance: strengthened world suite 15/15 (68.8 s), physically departing the core before both distant workers transport separate 5-timber batches through 1 Hz simulation; returning restores both visible actors with empty cargo and 10 warehouse timber. Rendered roster 24/24 (73.009 s), with selected Ivo's Finishing current job panel verified; Web earlier roster 24/24 and clean console. Retirement correction is still in its final native/Web run.

## Milestone 56 / round 01 — fixed-source expanded-world and worker regression

- Freeze the M49–M55 additions together with the accepted earlier systems, including resource identity/migration, regional harvesting, inland water, delivery feedback and independent worker state. Run all 44 default suites with 647 minimum assertions, and verify every managed source hash afterwards.
- This checkpoint is running; no full-source acceptance is claimed until all reports and hashes pass. M40 already covered the twelve-minute continuous architecture flight; M56 retains the shorter multi-region/world/forest-airmail checks. Remaining budget 19/20. Rubric remains 7.85.


M55 latest acceptance: corrected retirement suite 25/25 native (72.1 s) and Web 25/25, clean current-run console. Existing worker suite now passes 25/25 (159.1 s) without the former cleanup errors. Browser save 23/23 and fresh-page resume 6/6 explicitly restore Ivo's 2 timber independently from Mara's in-transit parcel and the forest's 17 timber. Native routine/stop/integration/panel regressions and final Web UI remain underway.

## Milestone 57 / rounds 01–02 — vehicle heading collision

- Adversarial baseline 5/8: one 1/60-second turn rotates the deployed wing into a 3.5 cm post in both directions (yaw ±0.01583 rad), despite an initially clear pose. Ground aircraft yaw also advances into the post. Existing wing attitude checks cover local bank/pitch, but not the parent body's yaw.
- BikeController.try_turn now checks every enabled collider at the proposed world yaw before committing it. Both ground and airborne steering call it; existing translation collision and attached-cart checks remain active. The check is skipped when yaw is unchanged.
- Fixed-step placement fixtures isolate yaw; physical flight/towing/ground and delivery regressions must still pass. Baseline source and report retained. Native/Web checks in progress; flight/cart remain 7. Remaining budget 18/20.


M55 Web UI 15/15 at 354 submissions /109 FPS and strengthened world 15/15, clean consoles. Existing native routine 16/16 (188.5 s) and stopped-routine accounting 4/4 (52.0 s) pass with the second worker present. Integration/panel regression is still finishing.

M57 round 03: the first eight heading checks now pass; flight 22/22, bike 26/26, towing 15/15, wing pose 8/8, ground pose 11/11 and highland 8/8 pass. Extended the adversarial case to the trailer: baseline 10/11 exposes a 0.06182-radian corner rotation into a world post. Cart yaw previously checked layer 8 (bike) only; changed to 9 (bike plus world). Final targeted and Web checks underway. The test count now includes three trailer checks, minimum 11. Remaining budget 17/20.


M55 final native targeted acceptance: worker 25/25, routine 16/16, routine_stop 4/4, integration 16/16 (102.5 s), panel_combat 15/15 (8.7 s), with earlier save/UI/roster/world and browser restart results. Both-worker feature accepted, pending the independent M56 full-source checkpoint. Worker/architecture/persistence scores stay 8.

M57 round 04: a stronger compound-slope test found a regression in the first guard: right steering advanced only -0.02648 rad versus +0.49833 left while grounded (14/15 overall). An upright box needs a small vertical support adjustment when its footprint rotates uphill. VehicleClearance now computes that change from the actual floor normal and enabled box extents, bounds it to 8 cm, and rechecks every collider at the raised pose. It never ignores terrain and never adjusts an airborne bike's height. Final obstacle/slope/trailer regressions are underway; the intermediate guard is not accepted. Remaining budget 16/20.


M57 round 05: final steering suite 16/16 native (9.3 s), rendered (prior shorter turn fixture) and Web 16/16 with clean console. Strengthened loaded slope case drives long enough to require both bike and trailer to turn right, rather than accepting either trailer heading. Native cart 25/25, towing 15/15 and ground contact 11/11 also pass with support adjustment; earlier physical Longfield/Greenreach deliveries pass 12/12 each (106.5 /179.1 s). Final browser Longfield delivery is running. Yaw checks operate at fixed steps, and ground adjustment is limited to current box colliders; this is not continuous rotational rigid-body physics. Flight/cart remain 7.

## Milestone 58 / round 01 — Red Mesa ore adit

- Feature baseline: Red Mesa has scenery and an encounter, but no registered ore source. Add a short walkable gallery at (4829,1223), with actual side/back/roof collision, timber supports and a small work light. Its terrain chunk owns and retires the structure; the underlying terrain is the walking floor.
- Add independent red_mesa_ore stock (80 ore) inside at (4829,1225). Stock revision 3 migrates revision-2 saves by initializing only this new source, preserving existing depletion and worker records. Reuse gathering, inventory, market and ammunition APIs.
- Validate entry movement, wall obstruction, capacity, independent depletion, legacy/current saves, chunk retirement/return and ore-to-ammunition commerce. Endpoint fixtures and guard isolation must be stated explicitly; regional encounter regression remains separate. Native/rendered/Web checks pending. Remaining budget 19/20. World/economy stay 8 and visual 7.


M57 final Web physical delivery acceptance: Longfield airmail 12/12 (100.086 s), clean console. Together with final obstacle/slope 16/16 and native cart/towing/ground regressions, heading collision is accepted. The compound-slope right turn is restored to -0.49833 rad while all post cases reject yaw; no aircraft/cart score increase is claimed from this correctness fix.

M58 round 02: optional quarry verifier initially rejected two inferred types (gallery Node and weakref Variant). Explicitly typed both; gameplay imported without errors, but no resource behavior acceptance was claimed from that failed verifier. Running corrected endpoint, legacy-stock, existing encounter and UI checks. Remaining budget 18/20.


M58 round 03 native: quarry 18/18 (10.4 s), rendered 18/18 (12.456 s), forest stock 14/14, source identity 9/9 and save 22/22. The player walks through the actual opening to within 2.65 m of ore; the roof is solid and the rear wall rejects gathering inside the normal distance radius. Both stock migrations preserve 11 village ore; revision 2 also preserves 17 forest timber. Endpoint guards are isolated after arrival. Initial render shows a rectangular facade; added broken rock edges around the same structural shell for another visual review. Remaining budget 17/20.


M56 final fixed-source acceptance: 647/647 across all 44 default suites in 1,417.617 s. All 285 managed source hashes unchanged; m56-regression-summary.json accepted=true with retained source, manifest and validation logs. This snapshot includes M49–M55 and predates M57–M58; it does not claim those later changes were in the frozen gauntlet. Rubric remains 7.85.

M58 round 04–05 critique: the improved rock facade projected beyond the rectangular collision shell. Added a two-sided ray test, which failed (18/19 baseline). Built convex collision from each large rock's actual scaled/rotated mesh vertices into an unscaled shared static body. This keeps the visible protrusions solid and chunk-owned. Rechecking entry, retirement, encounter navigation and Web. Remaining budget 15/20.


M58 round 06: facade collision now passes, but the old roof ray expected a flat upward normal on the exterior. It now strikes the deliberately faceted rock cap instead. Changed this check to cast upward from inside the gallery and require the solid ceiling's downward face; this tests actual overhead containment without assuming the exterior is flat. No collision was removed to satisfy the test. Previous result retained. Remaining budget 14/20.


## Milestone 59 / rounds 01–02 — collision during wing motion

- Adversarial baseline 6/12: both partially unfolded wings lack collision for all 27 sampled intermediate frames; unfolding and folding each place visible wingtip samples through an overhead obstruction for 9 frames. The full horizontal pose clears this obstacle, so the existing start/end checks miss the swing path and allow completion/saving.
- Added two transition-only box colliders that follow each visible panel's current scaled span and rotation. Proposed progress and visual attitude check those shapes before committing; a blocked arc waits and exposes guidance in the vehicle HUD. Existing automatic folding is retained when the final horizontal space becomes blocked.
- Full aircraft mode keeps its established wing collider; bike mode disables all wing collision. Grounded movement/heading checks use the currently enabled shapes. Native/rendered/Web and existing transformation/flight regressions pending. Remaining budget 18/20. Flight score remains 7 until broader acceptance.


M58 final targeted native acceptance: corrected quarry 19/19 (10.4 s), region 18/18 and real regional encounter 16/16, alongside prior forest/source/save/logistics/UI regressions. Web quarry 19/19 (11.835 s), save 23/23 and fresh-page resume 7/7, clean consoles; the restarted page explicitly retains 23 quarry ore, 17 forest timber, Ivo's 2 timber and Mara's parcel. Gallery art remains a shallow blockout chamber. Browser UI budget check is finalizing.

M59 round 02 initial acceptance: transition 12/12 native (7.8 s) and rendered (9.333 s); unfolding waits at progress 0.409 with zero missing wing collision or overlapping samples. Existing flight 22/22, wing pose 8/8, heading clearance 16/16, seat safety 12/12, save 22/22 and highland 8/8 pass. Strengthened the transition test to reverse the actual bike out from under the obstruction, and to verify folding collider coverage; minimum now 13. Browser and physical-delivery regression pending. Remaining budget 17/20.


M58 final browser UI acceptance: 15/15 (354 submissions /107 FPS), clean console. Combined with quarry 19/19 and fresh-page depletion 7/7, the milestone is accepted. Convex facade collision and portal movement are verified; it remains a small authored blockout gallery.

M59 strengthened native/rendered acceptance: 13/13 (8.8 s /10.381 s); actual reverse input moves the grounded bike 8.44 m out of cover and completes deployment, with both wing colliders intact. Folding has zero overlapping or missing samples. Captures show the blocked state and usable control guidance. Existing flight-delivery regression 12/12 (99.6 s); UI 14/14. Latest Web export built; browser transition/full-flight checks next. Remaining budget 16/20.


## Milestone 60 / rounds 01–02 — rear aircraft collision

- New adversarial fixture checks the tail fin, horizontal stabilizer, propeller and connecting shaft, rear deployment clearance, partial coverage and reversing toward a wall. These parts extend behind the motorcycle chassis and were outside its original collision volume.
- AircraftTailCollision supplies four bounded boxes, including a conservative propeller sweep, and participates in full/partial pose validation and physical movement. The tail expands from its mount height so partially scaled geometry stays above the ground. Full-size appearance remains the same.
- Existing wing/transition/heading/seat/landing and actual flight-delivery checks must remain valid. Baseline report/source retained; final native/Web validation pending. Remaining budget 18/20. Flight remains 7 pending broader acceptance.


M60 baseline 3/10: no collision at any of the four rear samples; rear obstruction still permits deployment; reverse travel reaches 1.724 m with 23 overlapping samples. Corrected first native run 10/10 (4.4 s) stops after 0.034 m with zero overlap. Existing wing transition 13/13, flight 22/22 and wing-pose 8/8 pass. Expanded rear tests now cover actual bank/climb plus blocked and cleared fin attitude, minimum 15; further flight/landing regressions are underway. Remaining budget 17/20.


M60 round 03 fixture critique: the heading test manually coupled a cart to an airborne-mode aircraft, bypassing HitchSystem; new rear collision correctly obstructed that invalid starting overlap. Put this trailer-only fixture in folded BIKE mode. The isolated fin-pose fixture also left WorldManager free to re-enable bike physics while manually posing it; disabled that scheduling for the isolated phase and added pose/coverage/processing details. Actual bank/climb collision already passes. Both failed fixture logs retained; corrected native/rendered and flight regressions next. Remaining budget 16/20.


M59 final Web acceptance: transition 13/13, Longfield airmail 12/12 (100.100 s), and UI 15/15, all with clean consoles. The physical reverse-to-clear instruction is verified and no wing overlap samples remain in the blocked unfolding/folding fixture. Milestone accepted; full tail protection is the subsequent M60 work.

M60 corrected targeted acceptance: tail 15/15 native (7.7 s) and rendered (8.560 s). Cleared fin pose is exactly 0.3000 rad with collision coverage while its isolated physics is disabled; actual bank/climb cases also pass. Corrected heading fixture 16/16, touchdown 8/8, seat safety 12/12 and highland 8/8 pass. Physical deliveries and browser checks are still running. Remaining budget 15/20.


M60 physical regression and browser recovery: native Longfield 12/12 (99.6 s) and Greenreach 12/12 (171.3 s) pass. Initial Web navigation failed twice before RSB_READY with WebAssembly memory allocation errors, including after navigating through a blank page. A fresh tab runs tail_clearance 15/15 (8.293 s), clean console; original error logs retained. This does not establish unlimited repeated-page endurance. Final Web delivery/UI checks pending.

## Milestone 61 / rounds 01–02 — locate individual workers

- Feature baseline 0/1: the map has no worker tracking API. FieldMap now resolves Mara/Ivo by stable ID, draws colored diamond markers, and tracks their actual positions. GameHUD adds separate Follow buttons so overlapping actors remain selectable. Retiring a tracked actor clears the marker and field notes safely. Worker state labels use readable phrases.
- Native 13/13 (8.8 s), rendered 13/13 (9.594 s): real Ivo transport movement 13.19 m, same actor/job after restoration, independent buttons, overlap selection, unknown-ID rejection, remote scope, retired actor cleanup, fixed/clear controls and viewport fit. Existing equipment 12/12, panel combat 15/15 and UI 14/14 pass.
- Visual critique exposed the pause menu behind the map after save restoration. Added a separate adversarial assertion before fixing that state synchronization. Evidence captures and baseline retained. Waypoint selection remains session-only; no claim of cross-page tracking persistence. Native/Web acceptance pending. Remaining budget 18/20; UI and worker scores stay 8.


M60 final browser acceptance: rear assembly 15/15, physical Longfield delivery 12/12 (100.109 s), UI 15/15 (354 submissions /120 FPS), clean consoles in the fresh tab. Native long forest delivery also passed. Milestone accepted with the recorded repeated-navigation memory limitation; flight remains 7.

M61 round 03: new map/menu assertion reproduces 13/14 baseline. Main now suppresses the pause menu while the map is visible, including during restoration. Native and rendered worker tracking 14/14 (8.8 /9.793 s), equipment 12/12, panel combat 15/15, save 22/22, UI 14/14 and two-worker logistics 25/25 (72.1 s) pass. Corrected world-map capture shows one panel. Web export complete; browser acceptance running. Remaining budget 17/20.

## Milestone 62 / round 01 — brook and cargo bridge

- Add a bounded authored brook northwest of Port Solis, centered around (-600,-500), with a solid crossing for walking and loaded motorcycle/cart travel. Stream the bridge with its owner chunk; share the same water bounds between rendering and safety. CPU terrain and horizon receive identical carving parameters.
- Critique target: a decorative water strip alone would not prove a usable crossing. Verify actual on-foot and loaded driving across, dry deck/water separation, water recovery with cargo retained, vegetation exclusion, and chunk retirement/rebuild. Regional approach uses endpoint fixtures; no claim of a connected river network or full hydrology. Baseline source retained. Implementation and native/Web checks pending. Remaining budget 19/20. World remains 8, visuals 7.


M61 final Web acceptance: worker map 14/14 (9.617 s), equipment map 12/12, UI 15/15 (354 submissions /120 FPS), clean consoles. All acceptance cases include the menu-restoration fix. Milestone accepted; tracking remains session-only, and the world map is still a schematic.

M62 round 02: production imports, but the optional verifier failed to parse two inferred values from dynamic object access (coupled bool and foliage transform Vector3). Explicitly type them. No gameplay acceptance claimed from the failed launch; full output retained. Remaining budget 18/20.


M62 round 03: initial native crossing 14/14 (47.8 s). Actual walking covers 112.38 m; the loaded bike/cart cross with 20 ore, maximum drawbar gap 3.866 m and 230 dry deck samples (minimum body height 9.931 m). Channel floor is real collision at y=0.986, deep water recovers the player and preserves 5 timber; bridge retirement/rebuild passes. Strengthening the adversarial test to stop/save on the span, retire its chunk, and restore the hitched vehicles before completing the crossing. Rendered first pass is running; no Web acceptance yet. Remaining budget 17/20.


M62 round 04 native: strengthened crossing 17/17 (52.822 s). Stopping on the span allows a valid save; moving to town retires the bridge; restoration rebuilds it before loaded physics resumes. Final drive retains all 20 ore and 3.866 m maximum drawbar gap. Rendered earlier 14-case run passes (49.851 s); capture shows a straight authored channel with functional but plain geometry. Existing water/lake/horizon/streaming/UI regression is running. Curve/shoreline art remains a visual critique, not a correctness claim. Remaining budget 16/20.


M62 regression critique: lake 14/14 passes, but coastal water 10/12 fails before its flight case. Diagnostics show deployment rejected immediately after the fixture rotates the bike 90 degrees; after its visual ground pose settles, the same position has full clearance and no rear shape intersects terrain. The test skipped checking deployment and continued driving in BIKE mode. Retained both diagnostic logs and the failed report. Allow the artificial orientation change to settle before requesting deployment, and add an explicit grounded-aircraft assertion (water minimum 13). This changes fixture setup only; actual takeoff/flight/water approach inputs remain the acceptance path. Broader regression and revised water test pending. Remaining budget 15/20.


M62 round 05 water correction: coastal water 13/13 (25.1 s), including explicit deployment and actual airborne/water-landing recovery. No production flight/collision changes were needed. Background horizon 7/7, streaming 15/15 (67.6 s) and UI 14/14 also pass.

M62 round 06: changed the straight channel to gentle sinusoidal bends using shared CPU/GPU parameters, widened the bounded water surface to 90×496 m, and added wet-terrain coverage sampling. Crossing 18/18 (52.822 s): same cold-chunk restore and real loaded drive, 295 dry deck samples, maximum drawbar gap 3.885 m. Horizon 7/7 and UI 14/14 pass; Web export complete. Final native rendered capture and Web brook/coastal-water/UI acceptance underway. Before-curve geometry/test/capture retained. Remaining budget 14/20. Visual score remains 7.


M62 final crossing acceptance: native rendered 18/18 (55.237 s) and Web 18/18 (54.105 s), clean Web console. The curved-channel capture includes loaded vehicles stopped on the span; the same run unloads and restores that span, then drives off with goods intact. Native lake/water/streaming/horizon checks already pass. Final corrected coastal Web flight and UI benchmark pending; no visual score increase is claimed for this blockout addition.

## Milestone 63 / round 01 — fixed-source full regression

Freeze the source through M62, including the strengthened coastal-water fixture, and run all 50 default suites plus the continuous long-flight test. Minimum 749 assertions across 51 suites. Keep the source/manifest immutable and verify hashes after completion. This checkpoint is independent of later edits in the working project. Targeted M62 Web water/UI checks are finishing concurrently. Results pending; no checkpoint acceptance until the complete hash-verified report exists. Remaining budget 19/20.


M63 fixed source created: 303 managed files, 51 suites, 749 minimum assertions including long flight. Running; hash acceptance pending.

## Milestone 64 / round 01 — cliff-top grove silhouettes

- Visual critique: the large solid green caps on coastal spires resemble slabs rather than vegetation. Thin those existing caps into low ground cover and add static clustered trees, using a separate deterministic RNG. Preserve the old rock RNG consumption so later collision landmarks and vegetation layout do not shift.
- New CliffGrove geometry participates in existing StaticBatcher grouping; it creates no actors or process ticks. This is a reversible visual change, so reuse traversal/UI checks and rendered comparisons instead of adding assertions that mirror the geometry. Prior source/capture retained; native/rendered/Web evidence pending. Remaining budget 19/20. Visual rubric stays 7 pending review.


M62 final Web acceptance: brook 18/18 (54.105 s), corrected coastal water 13/13 (25.775 s), UI 15/15 (355 submissions /120 FPS), clean consoles. Milestone accepted with its curved authored channel, loaded bridge and terrain-before-physics restoration. Water rules remain recovery-based; no swimming or hydrology simulation.

M64 round 01 visuals: native traversal 21/21 and UI 14/14; rendered UI 15/15, 357 submissions, with clear before/after grove captures. Visual review then exposed apparent inside-out rock faces. A new physical surface fixture confirms 0/4: all 42 side normals face inward, top/downward and wall/inward rays miss, and the arch underside has no closing face. Preserve the baseline source/report; reverse triangle winding on sides/top and close the bottom. This expands the milestone from vegetation art to actual cliff surface correctness; require ray collision plus traversal/combat/vehicle/coastal regressions and Web checks. M63's immutable source predates this newly identified defect/fix. Remaining budget 18/20. No score increase yet.


M64 round 02 initial acceptance: exterior-normal/top/wall/underside fixture 4/4, native traversal 21/21, combat 34/34, bike 26/26 and flight 22/22. Rendered UI 15/15 at 357 submissions; before/after images show the cliff faces lit from outside rather than their backs. Closing the underside also makes arch collision coherent. Coastal water and browser acceptance are pending. M63 remains an immutable pre-fix regression snapshot and does not validate this correction. Remaining budget 17/20.


M64 targeted native acceptance completed: coastal water 13/13 and UI 14/14 join surface/traversal/combat/bike/flight passes. Web export built; surface and gameplay/browser acceptance underway.

## Milestone 65 / round 01 — limestone face definition

The corrected outward faces expose a visual weakness: nearly uniform pale rock loses facet definition in daylight. Add restrained per-face color variation and explicit sRGB vertex colors through one shared standard material. Preserve vertex positions, triangle order, RNG consumption and collision. Existing StaticBatcher can combine those colored rocks into fewer material groups. This is a reversible material change; use rendered comparison and existing surface/UI/batching checks, without inventing additional visual assertions. Before-source/capture retained. Native/rendered/Web results pending; remaining budget 19/20 and visual score stays 7.


M64 final Web acceptance: exterior rock fixture 4/4, coastal flight/water 13/13, UI 15/15 (357 submissions /121 FPS), clean consoles. Cliff surface correctness and static groves are accepted. The surfaces are still simple procedural blockout meshes; this does not make the reference art target complete.

M65 initial native acceptance: surface fixture 4/4, batching 8/8, UI 14/14; rendered UI 15/15 (353 submissions /120 FPS). Shared vertex-color material reduces four submissions while preserving the closed geometry. Captures show more distinguishable facets; Web acceptance is running. Remaining budget 18/20; visuals remain 7.

## Milestone 66 / round 01 — flight course guidance

A camera compass alone does not tell a pilot how to turn toward a delivery or selected map point while looking around. Add an aircraft heading/vertical-speed readout and a shortest-turn course cue, prioritizing an explicit waypoint over an active delivery destination. Preserve the low-airspeed warning and existing controls. Verify cardinal directions, north wraparound, camera independence, target precedence/clearing, nearby wording, pause/map layout, and real flight movement. No autopilot or flight-physics changes are intended. Baseline source retained; native/Web checks pending. Remaining budget 19/20.


M65 final Web acceptance: UI 15/15 (353 submissions /120 FPS) and surface fixture 4/4, clean consoles. Shared material/face coloration accepted; geometry/collision remains the M64 correction. The cliff forms are still coarse blockout art.

M66 round 02: baseline missing course support 0/1, first implemented run 16/18. Both failed wraparound assertions incorrectly required a LEFT/RIGHT label for a two-degree correction, which lies inside the intended three-degree ON COURSE tolerance. Preserve signed numeric wraparound checks, assert the tolerance label there, and add two 20-degree north-crossing cases that must produce actual LEFT/RIGHT cues. Remaining 16 cases already pass, including real map selection and 46.42 m of aircraft movement. Detailed numeric/label evidence added; no production direction logic changed to satisfy this fixture correction. Remaining budget 18/20.


M66 round 03 native acceptance: guidance 20/20 (4.3 s), rendered 20/20 (5.398 s), flight 22/22, equipment tracking 12/12 and UI 14/14. Numeric wrap cases are exactly +2/-2 degrees with ON COURSE labels; larger corrections yield RIGHT/LEFT 20 degrees. Rendered flight shows camera compass 88 degrees while aircraft heading is 109, with a consistent 241-degree target course and right-turn cue. The isolated guidance fixture starts airborne after a real mount; actual delivery takeoff/landing regression is running separately. No navigation or flight-physics behavior is inferred solely from that fixture. Remaining budget 17/20.


M66 physical delivery regression: Longfield airmail 12/12 (99.6 s), including actual acceptance, flight, landing, approach and one-time payment. Web export built; guidance and flight/UI browser acceptance underway.

## Milestone 67 / round 01 — incoming hit feedback

An incoming hit currently changes HP without a dedicated visual/audio cue. Add a brief, bounded edge tint and an original quiet impact sound through the existing voice pool. The overlay must ignore input, keep the center clear, and clear on pause or recovery. Invulnerable/friendly/rejected damage must not trigger feedback. Verify a real committed hostile strike, fade timing, immunity, pause, recovery, live UI interaction and mounted damage. Preserve mechanics and old sound assets. Before-source/assets retained; native/Web evidence pending. Remaining budget 19/20.


M66 Web guidance 20/20 and actual Longfield delivery 12/12 (100.052 s) pass. Final UI report is 14/15 at 30 FPS: the short N pulse assertion fails while all other cases pass, with a clean console. This acceptance step is reopened; its original report is retained. Guidance never steers or completes a delivery.

M67 round 02: baseline missing feedback surface 0/1; native incoming-damage 13/13 (6.8 s), feedback 9/9, combat 34/34, panel combat 15/15 and UI 14/14. Rendered incoming-damage 14/14 (7.691 s), including an actual native audio voice start. Captures show the brief edge cue after a real hostile strike and mounted 65/100 health, with the center and controls unobscured. All eight pre-existing WAV hashes match exactly; the new hurt clip joins the existing eight-voice pool. Native playback state and visual timing are verified, not subjective listening quality. Web export built/being checked; browser acceptance pending. Remaining budget 18/20.


M67/UI cross-check: the slower M66 Web UI run exposed the verifier observing an input latch after physics frames without waiting for the idle frame that consumes it. Reproduce at a 20 FPS cap before correcting fixture timing. Existing real input latches remain unchanged during diagnosis. Original 14/15 browser report and before-verifier source retained; do not treat the clean console or passing draw-call budget as full UI acceptance.


M67/UI frame-rate reproduction: native UI at a 20 FPS cap fails 11/14, including a synthetic held-key poll that begins/ends between idle frames and both immediate pulse assertions. Replace UI open/close setup with actual InputEventKey events, and wait for the idle frame that consumes queued UI actions before asserting. Keep the pulse itself back-to-back pressed/released, preserving the actual short-pulse challenge. Production WorkerManager/LogisticsWorld input handling is unchanged. Capped and normal native/Web validation pending. Remaining budget 17/20.


M67/UI corrected native acceptance: UI 14/14 at the deliberate 20 FPS cap (4.562 s), plus normal UI 14/14, worker map 14/14 and flight navigation 20/20. Actual short press/release events now pass after their consuming idle frame; production input code is unchanged. Updated Web export complete. Browser incoming-damage/UI acceptance is being recorded separately; the failed M66 UI result remains retained.


M63 final fixed-source acceptance: 749/749 across 51 suites, 303 source hashes unchanged, 2,234.625 seconds of suite runtime. Continuous flight covers 23,954 m in 719.67 s, peak 25 terrain chunks, 1,895 created /1,870 retired, maximum chunk build 6.49 ms. This accepts the frozen source through M62 only; it predates the M64 cliff collision correction and all later changes.

M66/M67 final browser acceptance: incoming feedback 13/13 and revised UI 15/15 (353 submissions, 30 FPS), clean consoles. This closes the reopened UI check on the combined M67 build. The intentional 20 FPS native reproduction and original Web failure remain retained. Flight course and incoming feedback are accepted with their documented limits; conservative rubric stays 7.85 overall (visuals/flight/cart 7, other categories 8).

## Milestone 68 / round 01 — world-anchored water rendering

- Critique: coastal ripples use fragment VERTEX (view coordinates), visibly dragging a checkerboard pattern as the camera moves. At one fixed underwater world point and a frozen animation phase, two camera poses produce an RGB difference of 0.11439; rendered baseline fails this invariant. The first geometry assertion also fails because it compared 32-bit Vector3 height to a 64-bit scalar exactly; use approximate scalar equality, not a production level change.
- Share the existing WaterSurface/WaterBody implementation between coast, lake and brook, with world-coordinate directional ripples and reduced color contrast. A controllable animation-time uniform lets the verifier freeze only time while retaining the production coordinate expression. Safety geometry, terrain and water bounds remain untouched.
- Files: CoastalRegion, WaterSurface, shared water shader, water_camera verifier and suite catalog. No scene changes. Original sources/captures/report retained in m68-before. Rendered/native/Web checks pending. Existing geometry/safety regressions will cover the unified coast and lake; visual review checks the broader result. Remaining budget 19/20; visuals remain 7.


M68 round 02: native water-camera 2/2 headless, 4/4 rendered, coastal water 13/13, lake 14/14 and UI 14/14. Fixed-point RGB difference is 0.00131 native and 0.00392 Web, versus 0.11439 baseline. Advancing only animation phase yields 0.06189 /0.06050 difference, so the invariant has not been satisfied by a flat, frozen material. Web rendering 4/4 with clean console; coastal water/UI browser regressions pending. Captures show softer directional variation. Remaining budget 18/20.

## Milestone 69 / round 01 — detached cargo recovery

- Adversarial review finds CargoCart lacks the domain/fall recovery present on the player and motorcycle. Initial isolated fixture 0/2: detached cargo keeps falling and stays beyond the world boundary. Water and distance suspension are disabled only for this fixture to isolate the missing path; no claim this reproduces an ordinary terrain hole.
- Refine the fall probe to y=-65, well beneath the world's lowest seabed, before implementing. A -9 probe overlaps legitimate underwater terrain, so it is not the intended recovery threshold. Retain its original report, then run the corrected baseline. Recovery must preserve cargo, clear residual velocity/orientation, keep any tow relationship coherent, and suspend the home cart when the player is distant. Reuse the same cart recovery endpoint for water.
- Baseline sources saved; CargoCart, WaterSafety and WorldManager are the intended production files, plus Main notification wiring and the verifier. No scene changes. Native/Web acceptance pending. Cargo remains 7; remaining budget 19/20.


M68 final Web acceptance: world-anchored animation 4/4, coastal water 13/13, UI 15/15, clean consoles. Pinned village view 351 submissions /30 FPS. Shared water no longer casts a shadow; terrain, safety levels and bounds are unchanged. Milestone accepted; directional bands and opaque water remain blockout visuals, not a final shoreline/reflection treatment.

M69 round 02: corrected below-seabed/domain baseline 0/2 retained. CargoCart now records its workshop home, checks -64 m and all world bounds, and exposes a recover endpoint/signal. Coupled recovery delegates to BikeController; WorldManager updates simulation tiers immediately. WaterSafety reuses the same endpoint. Native targeted 16/16 (4.597 s), existing cart 25/25; wider recovery/water/save checks are running. The fixture deliberately injects invalid positions; it proves recovery behavior, not that ordinary terrain contains a hole. Goods and hitch relationships survive. Remaining budget 18/20. Cargo rubric remains 7 because its towing solver is still arcade kinematics.


M69 native acceptance: detached cargo 16/16 headless (4.597 s) and rendered (5.808 s), cart 25/25, existing distant recovery 8/8, coastal water 13/13 and save 22/22. Rendered home capture includes the preserved 80 kg ore load and the recovery notification. Web export complete; browser recovery and UI checks pending. Remaining budget 17/20.

## Milestone 70 / round 01 — current-source regression checkpoint

Freeze the combined source through M69 and run all default suites plus continuous flight. This supersedes the scope gap in M63 by including the cliff surface correction, course guidance, incoming feedback, water shader and detached cargo recovery. Keep the new source manifest immutable while further work continues in the live project. Native completion and hash verification are required before acceptance; targeted Web M69 runs remain separate. Remaining budget 19/20; no score change from merely starting a checkpoint.


M70 source frozen: 319 managed files, 56 suites, minimum 804 assertions including long flight. Results and unchanged-hash confirmation pending. All subsequent live-project edits are outside this checkpoint.

## Milestone 71 / round 01 — continuous coastal ground color

- Visual critique: the core's random per-quad grass colors create conspicuous four-metre squares, and differ from the continuous streamed surface. Apply the existing shared streamed terrain shader to core tiles, adding a smoothly bounded coastal sand tint in the shared near/far color function.
- Preserve vertices, triangles, collision and old RNG consumption; original vertex colors remain as fallback data but no longer drive the material. No new shader passes, geometry or simulation nodes. Files: CoastalRegion and terrain_surface shader include. No scene changes.
- This is a reversible material refinement. Use existing native traversal, horizon and UI checks plus rendered before/after and Web UI/horizon acceptance; avoid a new test that merely mirrors color choices. Baseline source/captures retained. Remaining budget 19/20; visual rubric remains 7 until review and still requires much richer art.


M69 final browser acceptance: cargo recovery 16/16 and UI 15/15 (351 submissions /30 FPS), clean consoles. Milestone accepted with the injected-invalid-position scope clearly recorded. Existing loaded cart physics and water/save behavior pass their native regressions.

M71 native acceptance: traversal 21/21, horizon 7/7, UI 14/14, rendered UI 15/15 (351 submissions /120 FPS). Before/after village captures show the four-metre random color grid removed; terrain shapes and static scene placement are retained. Web export/acceptance running. The surface is still procedural, and roads remain simple flat ribbons; visual score stays 7. Remaining budget 18/20.


## Milestone 72 / round 01 — reachable logistics prompts

- Visual review shows many distant resource/desk action labels overlapping the town view. Review also finds nearest selection ignores reachability, even though using the selected source later checks walls; a closer obstructed desk can starve a reachable alternative.
- Reproduce both before editing: start away from stations, then place one nearer blocked source and one farther reachable source within the 4.5 m action radius; use an actual U key event. Proposed behavior shows only the reachable selected action and preserves physical signs/map names for navigation. Resource quantities and actions remain unchanged.
- Baseline source/capture retained. Files intended: LogisticsWorld plus initial ResourceSource/Storage label visibility and verifier/catalog. No scene changes. Native/Web baseline pending; remaining budget 19/20 and UI remains 8.


M71 Web performance acceptance reopened: UI 15/15, but horizon 7/8. Its rendering assertion requires at least 50 FPS; the observed view uses only 129 submissions but runs at 30 FPS, matching recent village runs. Clean console does not make this a pass. Retain the failed report and measure an empty browser animation page before attributing the cap to shader cost or revising any acceptance criteria. No performance threshold has been changed. Remaining budget 17/20.

M72 baseline 1/4: seven distant action labels, closer blocked source selected, real U action fails. LogisticsWorld now filters selection through the existing can_reach contract, shows only the selected prompt, clears it on pause/range exit and refreshes immediately before use. Native 11/11, logistics 23/23, cargo access 11/11, economy 21/21 and UI 14/14 pass; rendered 11/11 includes nearby courier acceptance. Web export built. Remaining budget 18/20; browser checks pending.


M71 performance diagnosis: an engine-free requestAnimationFrame probe delivers 121.92 FPS over 5.0032 seconds (610 frames, median 8.2 ms), visible/focused at CSS 395×863. Thus a blanket 30 FPS browser presentation ceiling is not supported. Tab inspection then finds the original M60 tail-clearance game still open in tab 4 alongside the newer verifier in tab 5; the old binding was misidentified as already blank in the working notes. Navigate that task-owned old game to about:blank and rerun the unchanged 50 FPS horizon requirement on the combined M72 build. Keep the failed 7/8 report. No threshold relaxation or performance claim yet.

M72 initial Web acceptance: reachable prompts 11/11, clean console. Actual U gathering and courier acceptance pass. Final UI benchmark follows the isolated rendering diagnosis; remaining budget 17/20.


## Milestone 73 / round 01 — solid village roofs

- Collision review finds the authored building body is solid but its visible PrismMesh roof has no collision. Reproduce with the actual building generator lifted into an isolated fixture: downward ridge approach, side entry above the walls, underside at the overhang, and an actual player fall onto the roof.
- Proposed correction is collision matching the existing roof mesh, with no geometry or building placement changes. Add movement/camera checks and existing traversal/vehicle regressions because new roof collision can affect navigation and flight. Before-source retained; baseline/native/Web results pending. Files intended: CoastalRegion and roof verifier/catalog; no scene changes. Remaining budget 19/20; no score change yet.


M71 isolated Web resolution: the same horizon view now passes 8/8 at 129 submissions /120 FPS after stopping the old task-owned Web game. Empty-page measurement and before/after reports are retained; the 50 FPS requirement remains intact. This accepts the terrain material on the combined M72 build, with UI benchmarking finishing separately. Do not generalize this single-machine result to broad hardware support or multi-game-instance performance.

M73 baseline 0/4: the ridge ray hits only the wall top at y=205 instead of the visible ridge at y=207.7; side/overhang rays miss, and the player falls through the roof to y=204.985. Enable trimesh collision on the existing PrismMesh. Strengthen acceptance with actual ridge walking, a compressed camera near the slope, and collision retained through static batching. No roof vertices or rendering materials changed. Native/Web results pending; remaining budget 18/20.


M71/M72 final isolated Web acceptance: horizon 8/8 at 129 submissions /120 FPS, UI 15/15 at 343 submissions /120 FPS, reachable prompts 11/11, all clean consoles. The duplicate older game explained the previous performance result on this machine; its original failing report remains available. Continuous ground material and reachable logistics prompts are accepted on this combined source. UI text still uses basic per-station wording, and distant resource navigation relies on the map/physical scenery. No rubric inflation; visual 7, UI 8.

M73 initial native acceptance: roof fixture 7/7 (3.016 s), traversal 21/21 and bike 26/26. Actual walking covers 2.37 m at a minimum roof height of 207.686; the camera compresses to 4.117 m with no collision overlap. Remaining flight/camera/UI regression and rendered/Web acceptance are running. Remaining budget 17/20.


## Milestone 74 / round 01 — motorcycle steering presentation

- Review finds the front fork's visible yaw has the opposite sign to the grounded right turn: BikeController subtracts positive steering from chassis yaw while BikeVisual adds it to the fork. Wheel spin and lean use separate axes and need no change.
- This is a reversible presentation correction. Extend only the existing bike verifier's diagnostic detail/capture, keeping its 26 assertions unchanged, and capture actual right-turn input before editing the visual sign. Reuse native/Web driving and UI verification; no new suite mirroring a one-line animation rule. Replace that verifier's blocking post-draw wait with the established forced capture path.
- Before-source retained. Files: BikeVisual, existing bike verifier; no scene or physics changes. Baseline/rendered/native/Web evidence pending; remaining budget 19/20. Bike stays 8 and visual readability 7.


M73 complete targeted native acceptance: roof 7/7 headless /rendered (4.199 s), traversal 21/21, bike 26/26, flight 22/22, shoulder clearance 8/8 and UI 14/14. Web build exported; browser roof/UI checks are running. Roof collision is now included in normal core collection and batching, with original geometry unchanged.

M74 baseline confirms actual right-turn chassis yaw -0.97 while the visible front assembly points +0.32 radians. All 26 existing driving checks pass despite this visual error; preserve the report and turn capture. Change only the fork animation sign. Wheel spin, lean, steering physics and collision remain as verified. Native/rendered/Web validation pending, remaining budget 18/20.


M73 final Web acceptance: village roofs 7/7 and UI 15/15 (343 submissions /120 FPS), clean consoles. Existing roof geometry now blocks approaches and supports the player/camera coherently. Milestone accepted for authored village/farm buildings; regional shelter/tower roofs use a separate generator and are being reviewed next.

M74 native acceptance: existing bike 26/26 and UI 14/14; rendered bike 26/26 (18.53 s). Actual right-turn chassis yaw remains -0.97 and the front assembly now points -0.32 radians. Before/after captures retained. Hand placement remains approximate without steering IK; the correction does not establish final rider animation quality. Web export complete, browser acceptance pending. Remaining budget 17/20.

## Milestone 75 / round 01 — streamed landmark roof collision

- Follow the village roof defect into the separate regional generator: the three shelter roofs and Snowwatch's overhanging tower cap also lack collision. Verify actual streamed instances in all four regions, not just isolated copies.
- Proposed correction adds collision to those existing meshes, preserving scenery positions and rendering. Require actual player roof support plus chunk retirement/rebuild and a saved rooftop session restored before physics resumes. Baseline source retained. Files: RegionScenery, regional_roof verifier/catalog. No scene changes. Baseline/native/Web checks pending; remaining budget 19/20 and scores unchanged.


M75 baseline 0/8 on actual streamed landmarks. Shelter ridge rays miss and players fall to ground; Snowwatch's visible cap top is 0.6 m above the physical tower body. Add existing-mesh collision to the shelters and the tower cap. Strengthen the verifier to 13 checks with rooftop save validation, owner-chunk retirement, actual restore/rebuild before resumed physics and bounded residency. Native/Web acceptance pending; remaining budget 18/20.


M74 Web acceptance reopened: driving 25/26. Steering presentation passes with chassis -0.97 /fork -0.32 radians, but the final real terrain-seam drive stops at z=86.70, speed 0 instead of crossing z=93 above 12 m/s. Native crosses z=96.66 at 15.83. Preserve the failed Web report and instrument slide contacts at the stall before modifying physics. Capture collider paths, normals, points and overlap depth using Godot's KinematicCollision3D API (https://docs.godotengine.org/en/stable/classes/class_kinematiccollision3d.html). No production handling change yet; remaining budget 16/20.

M75 initial native acceptance: actual streamed landmark roofs and cold-chunk rooftop restoration 13/13 (8.9 s). Physical air deliveries and world/UI regressions continue separately. Remaining budget 17/20; browser roof acceptance pending.


M74 collision diagnosis reproduces 25/26 in Web. At z=88 the same Terrain_0_1 body reports both a nearly upward floor normal (0.0373,0.9993,0) and a horizontal seam normal (0,0,-1), with roughly 1 mm overlap. This is an internal triangle-edge contact, not an authored wall or the fork animation. Trial: increase only BikeController's collision-recovery margin from 1 mm to 2 cm, using CharacterBody3D's documented floor-contact recovery mechanism (https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html#class-characterbody3d-property-safe-margin). Keep all collision shapes and wall/flight guards. Existing real-wall and terrain-seam checks will be rerun on both platforms before acceptance. Remaining budget 15/20.

M75 native acceptance completed before the margin trial: regional roofs 13/13 headless (8.9 s) /rendered (9.739 s), actual Longfield delivery 12/12 (99.6 s), Greenreach delivery 12/12 (171.3 s), streaming 15/15 (67.6 s) and UI 14/14. Roof ownership, cold restore and deliveries pass. Web roof check is next; the separately discovered bike seam failure keeps combined-build acceptance open.


M74 margin trial passes Web driving 26/26: the formerly blocked route reaches z=96.13 at 16.00 m/s with no captured stalled contacts. Native bike 26/26 also passes. Keep the original seam failures and trace; the fix adjusts collision recovery, not collision masks or shape sizes. Broader native flight/cart/towing/wing/water/bridge regression is finishing, and an additional multi-direction terrain-versus-real-wall challenge is being added before final acceptance. Remaining budget 14/20.

## Milestone 76 / round 01 — varied seam travel and real-wall control

- Strengthen the discovered terrain-contact regression: physically drive north/south/east/west along nearby grid lines, tow 80 kg of ore over the original seam, and place a real wall at that same grid boundary. Require continued late-route progress and no stalled frames, cargo/drawbar integrity, and preserved wall blocking without climbing.
- This is an adversarial verification milestone for M74's collision-margin correction, with no additional production handling changes. Use actual mount/hitch/drive interfaces; position fixtures only at each route's start. New terrain_seam verifier/catalog. Native/Web results pending; remaining budget 19/20. No score increase from added assertions.


M74 expanded native regression after the 2 cm margin: flight 22/22, cart 25/25, towing 15/15, steering clearance 16/16, rear assembly 15/15, wing transition 13/13, water 13/13, loaded brook bridge 18/18 (53.2 s) and UI 14/14. Ordinary wall blocking and the wing/tail guards still pass. The four-direction Web challenge is the remaining acceptance step.

M76 native 18/18 (31.23 s). Unladen routes cover approximately 25.1 m each, finishing at 20 m/s with zero stalled frames; loaded travel covers 27.441 m at 10.421 m/s with all 20 ore. A real wall at the original seam stops the bike at z=86.531 without climbing. Web export complete, browser challenge running. Remaining budget 18/20.


M70 final frozen-source acceptance: 804/804 across 56 suites, all 319 managed source hashes unchanged. The 23,954 m continuous flight takes 719.679 s, with peak 25 chunks, 1,895 created /1,870 retired, and maximum build 3.00 ms. This is a native checkpoint through M69, before the later ground material, prompts, roofs, steering and contact-margin changes; it does not certify those later edits or erase the retained Web seam failure.

M74/M75/M76 combined browser progression: corrected driving 26/26, loaded brook crossing 18/18, streamed roofs/cold rooftop restore 13/13, varied terrain seams plus real-wall control 18/18, clean consoles. No stalled frames occur on the Web seam routes and the constructed wall remains solid. Final current UI benchmark is being recorded. Conservative rubric remains 7.85; the vehicle systems remain arcade kinematics.

## Milestone 77 / round 01 — articulated traveler knees

- Visual critique: the traveler and workers swing one-piece legs, and the riding pose extends both legs rigidly forward. Add knee joints to the shared PlayerVisual while preserving its hip/arm interfaces, overall standing dimensions, collision and weapon attachments. Give BikeVisual an explicit shared riding pose.
- This is a presentation change: reuse existing traversal/combat/bike/worker/UI verification and native before/after walk/sprint/riding captures, without new assertions that mirror bone placement. The traversal capture helper splits only its existing 60 ticks at midpoint; it adds no extra movement ticks or gameplay checks.
- Before-source/steering capture retained. Files intended: PlayerVisual, BikeVisual and existing traversal capture helper. No scene or controller changes. Baseline capture/native/Web results pending. Remaining budget 19/20, visuals remain 7 and player/worker scores 8.


M77 baseline rendered traversal 21/21 (60.596 s), with before walk/sprint captures. Add independently batched knee/lower-leg joints, alternating swing-leg flexion, a capped sprint cadence, a local sole-height presentation adjustment, and tucked dodge/airborne knees. The riding pose widens the hips around the tank and bends knees toward the foot pegs. Existing hips and arms keep their public interfaces; weapon anchors and all physics remain unchanged. This is not terrain IK or a final animation set. Native/rendered/Web checks pending; remaining budget 18/20.


M74/M75/M76 final current UI acceptance: Web UI 15/15 at 343 submissions /60 FPS while a native capture was also running. The separate isolated horizon/UI runs previously reached 120 FPS; keep workload context with each measurement. Driving 26/26, loaded brook 18/18, regional roofs 13/13 and varied seams/real wall 18/18 already pass in Web. These milestones are accepted with their retained failed attempts and the bounded 2 cm bike recovery margin.

M77 initial native acceptance: traversal 21/21, combat 34/34, bike 26/26; rendered traversal 21/21 (60.528 s). Walk 4.28 m, sprint 7.37 m, jump 1.40 m and dodge 5.81 m exactly match the recorded baseline. The rendered traversal sample adds fourteen submissions (347 to 361); final pinned UI and worker/Web checks remain pending. Rear-view captures obscure knee articulation, so add side-view capture output and a clearly marked capture-only stop after the existing walk/sprint segment. Capture-only output is not a full verifier acceptance. Remaining budget 17/20.

M77 corrected capture: the immediate new-camera render produced an invalid underside-of-world view; preserve it and its log in m77-failed-capture. Wait two physics frames before the side capture and subtract them from the remaining hold, preserving 60 total movement ticks. The short photo run verifies only its first three movement checks and explicitly reports capture-only. Side screenshots now show bent knees and a grounded sole; the new riding photo shows the legs around the tank. Native worker contention 25/25 and UI 14/14 also pass. Feet still slide on uneven ground and hands do not track the bars; no visual-score increase. Web shared-worker/UI acceptance remains pending; remaining budget 16/20.

M77 final Web acceptance: shared worker scenario 25/25, clean console. Pinned UI report recorded separately; the extra leg joints remain a small presentation cost rather than a physics change. All native traversal/combat/bike/worker checks pass, with unchanged movement distances and inspected walk/sprint/riding captures. Milestone accepted at unchanged conservative rubric 7.85, with procedural foot/hand limitations retained.

M77 pinned Web UI 15/15, 354 submissions /60 FPS, with no other game instances running. Worker 25/25; both consoles clean. This cost is below the existing budget but the earlier 120 FPS sample is not reproduced in this run.

## Milestone 78 / round 01 — frozen native regression through M77

Create immutable m78 source/manifest and run all default suites plus continuous-distance flight. This checkpoint covers the later terrain, prompts, roofs, margin and articulated rig; subsequent live work is excluded. Pending results, no premature acceptance. Remaining budget 19/20.

## Milestone 79 / round 01 — explicit regional recovery checkpoints

- Critique: long-distance landmarks show discoveries but leave on-foot recovery at the village survey. Add an explicit E survey board near each regional landmark, independently from the three-stamp village route. Arrival alone must not replace a checkpoint.
- Challenge the baseline at all four real regions, then verify remote range/cover, paused/mounted interactions, recovery after chunk retirement, inventory retention and save/load. Preserve the existing save checkpoint vector and three survey flags; active regional board state derives from that checkpoint rather than inventing unvalidated save fields.
- Recovery must prepare the destination terrain before resumed movement. No teleport travel menu or vehicle-recovery change. Baseline pending; remaining budget 19/20, unchanged rubric 7.85.

M79 baseline 0/4 retained, then production regional boards pass 4/4. Expanded native challenge passes 28/28 (21.093 s): all four explicit assignments, arrival non-assignment, cold-chunk retirement/recovery with cargo; range, cover, pause, jump, death and mounted rejection; actual E dismount does not assign a checkpoint; saved regional checkpoint survives load and a second cold recovery; village flags remain 0/3 and peak chunks stay bounded. Recovery builds only the central destination chunk synchronously. Reuse save version 1 checkpoint vector, no migration or new save fields. Native regression/rendered/Web checks pending; remaining budget 17/20.

M79 rendered 28/28 (21.86 s), inspected Longfield board and active checkpoint prompt. Native regression: traversal 21/21, bike 26/26, recovery 8/8, water 13/13, save 22/22, regional roofs 13/13, regional surveys 28/28 and UI 14/14. Export complete; Web regional challenge pending. The separate M78 checkpoint predates these boards.

## Milestone 80 / round 01 — restore the sky gradient

- Visual critique: both village and open-country captures show a nearly flat blue-gray sky despite an authored procedural gradient. Environment leaves fog_sky_affect at its default 1.0, which can fully obscure the sky (Godot Environment reference: https://docs.godotengine.org/en/stable/classes/class_environment.html#class-environment-property-fog-sky-affect).
- Reduce only sky fog influence to 0.25, preserving terrain fog density, lights, geometry, collision and streaming bounds. Inspect fixed village and regional before/after captures and reuse existing UI/backdrop rendering checks. No new assertions for a single presentation parameter. Remain honest about the large gap between blockout geometry and the supplied reference art.
- Fresh baseline UI/capture and source saved in m80-before. The no-shadow image copied alongside it was older evidence and is explicitly named not-a-baseline. Change/render/Web acceptance pending; remaining budget 19/20; visual score stays 7.

M79 Web accepted 28/28 with a clean console. Existing native regressions and inspected rendered checkpoint capture pass. Arrival still only records discovery; E explicitly changes the checkpoint. Cold recovery, loaded recovery and save restoration work without expanding the original village route or adding a save revision. Remaining budget 16/20, rubric unchanged 7.85.

M80 rendered UI 15/15 at 354 calls /118 FPS (Web checkpoint scenario was also running); the village screenshot retains its geometry and exposes a subtle sky gradient. Regional capture rerun passes the existing 28/28 and shows the blue-to-warm horizon instead of the previous flat sky. Separate final image filenames retained. Web horizon/UI checks pending; remaining budget 18/20. This small lighting correction does not close the substantial art-quality gap to the references.

## Milestone 81 / round 01 — checkpoint map guidance

- Critique: the player can set a regional recovery point but cannot identify or select that saved point on the map. Add a distinct checkpoint ring and an explicit Checkpoint button to the existing tracking row, without another vertical panel row.
- Track the checkpoint value, not the player's moving position. Update guidance after an actual new survey and save restoration; selecting equipment, a worker, a fixed point or Clear must release checkpoint tracking. Keep selection session-only, matching existing map guidance.
- Challenge button selection, pause/ammo safety, real regional and local survey transitions, restore, mode replacement and control layout. Existing worker/equipment/UI regressions cover the shared map. Baseline pending; remaining budget 19/20, unchanged rubric.

M80 accepted: Web backdrop 8/8, 135 calls /60 FPS; UI 15/15, 354 calls /60 FPS, both clean consoles with no other rendered game active. Native UI and inspected regional/village comparisons passed. No geometry, collision or gameplay changes. Visual score remains 7.

M81 baseline 0/1 retained. Native expanded challenge 12/12 (9.57 s), using actual map button clicks, regional/village E surveys and SaveSystem.restore. Selection follows checkpoint values rather than player movement, preserves pause and ammo, updates map scope and releases on every other selection mode. Existing map regressions and rendered/Web layout acceptance pending; remaining budget 17/20.

M81 native map regression: checkpoint guidance 12/12, equipment 12/12, workers 14/14 and UI 14/14. Rendered checkpoint 12/12 with inspected local/world screenshots: the extra button fits the existing row and the checkpoint ring remains visible beside Longfield. Web check pending; remaining budget 16/20.

## Milestone 82 / round 01 — village roof and facade detail

- Art critique: houses retain large unbroken roof planes and minimal door/window joinery. Add a modest world-coordinate terracotta tile material and deterministic eave/door/shutter details to the existing authored buildings, preserving their silhouette, roof collision, positions and random-number consumption.
- Reuse the static batching path and shared materials. Compare the pinned village view and existing roof-surface capture; verify render budget and physical roof behavior with existing suites. No new tests that merely count decorative boxes or shader uniforms.
- Source and prior village image retained in m82-before. Native/render/Web evidence pending; remaining budget 19/20. The reference-level environment remains unfinished and visual score stays 7.

M81 accepted: Web checkpoint map 12/12, clean console; native existing equipment/worker/UI suites and rendered layout passed. The button follows actual saved checkpoint values and remains session-only, like other map tracking. No route or inventory changes. Remaining budget 16/20, rubric unchanged.

M82 first rendered attempt rejected 13/15: a GDScript inference error in StaticBatcher.static_material prevented dependent scripts from compiling. Batching fell to zero and the damaged scene submitted 2,045 calls; later bike errors are cascading failures, not independent vehicle defects. Preserve report, image and log under m82-failed-round1. Set an explicit bool type and import before repeating the rendered check. Roof shaders opt in to static merging only with an explicit world-coordinate-safe metadata flag; ordinary shaders remain excluded. Remaining budget 18/20; no acceptance or score increase.

M82 corrected rendered UI 15/15: 829 merged source meshes, unchanged 354 submissions /119 FPS, clean compilation. Inspection finds tile stripes on vertical gables, where world XZ coordinates collapse; mask tile detail by world normal so only pitched roof surfaces carry tiles. Preserve the first corrected screenshot/report and rerun the existing roof/camera and batching/vehicle checks. Remaining budget 17/20.

M82 native regression passes batching 8/8, roof surface 7/7, bike 26/26, traversal 21/21 and UI 14/14. Rendered roof 7/7 inspected at close range: pitched tiles read clearly and the player remains supported by the original roof shape. Web roof check passes 7/7 with a clean console; final Web UI budget pending. Remaining budget 16/20.

## Milestone 83 / round 01 — signed trailer wheel motion

- Code critique: CargoCart passes total unsigned 3D displacement to its wheels. That makes reversing roll the wheels forward and a vertical fall spin them despite no horizontal travel.
- Build a real mount/hitch/forward/brake/reverse challenge on a flat physical platform, accumulating actual wheel angle across wraps; separately drop detached cargo vertically. Preserve the failing baseline before changing presentation input. Keep towing constraints, inventories, colliders and travel statistics unchanged.
- Planned fix is grounded signed forward displacement for wheel animation. Native/Web baseline and regression pending; remaining budget 19/20, unchanged rubric.

M82 accepted: Web tiled roof 7/7 and UI 15/15, clean consoles, unchanged 354 calls /60 FPS. Existing native batching, roof, bike and traversal regressions pass after the compile correction. The close roof image confirms tile layout; failed unbatched evidence remains preserved. Visual score remains 7.

M83 baseline confirms 1/3: forward 9.680 m /-22.000 radians, reverse +7.437 m but -16.903 radians, and a vertical 5.999 m landing spins -13.635 radians. Pass only grounded signed forward displacement to CartVisual; retain the original 3D travel statistic and all physics. Expand verification with the physical rolling-distance relation, a west-facing cart, parked wheels and cargo/ownership retention. Native/Web acceptance pending; remaining budget 18/20.

M83 first correction 6/7. Reverse spin becomes +16.903 radians and vertical-drop spin becomes zero. The west-facing route advances 9.589 m west with 0.591 m lateral settling; its failed condition assumed a perfectly straight relocated hitch. Refine that diagnostic to require predominantly westward travel, correct spin direction and the physical rolling-distance relation, allowing the small observed drawbar adjustment. Keep the failed report. Add a real 15-degree uphill route before acceptance: projecting only onto an upright cart's horizontal forward vector may under-rotate on slopes. No towing-physics change. Remaining budget 17/20.

M83 slope baseline confirms 7/8: horizontal projection turns -20.033 radians for a slope route requiring -20.740. Project signed displacement onto the forward direction along the real floor plane, with ground contact and a horizontal-motion threshold to reject vertical settling. Final focused native challenge passes 8/8 (19.815 s); uphill spin exactly matches -20.740, reverse +16.903, vertical/parked zero. Cart/ground/towing regression and Web export are next. Remaining budget 16/20; no handling or collision change.

M83 native regression passes signed wheels 8/8, cart 25/25, compound-ground contact 11/11, towing 15/15 and UI 14/14. Web export complete and focused wheel challenge running. The change remains presentation-only.

## Milestone 84 / round 01 — covered expedition cart

- Reference/art critique: the cart has a rolled blanket but lacks the expedition canopy shown in the vehicle reference. Collision also covers only the lower bed, below a fully stacked cargo load. Add a fixed arched canvas cover, support poles and ribs, with a convex collision envelope generated from the same cross-section. Empty and full carts share that visible cover.
- Keep the original lower chassis box, inventory capacity, mass tuning and drawbar. Integrate the upper convex shape into translation/turn clearance and keep its pose matched to ground-aligned presentation. Extend geometric floor-support evaluation for convex points rather than disabling clearance checks.
- Baseline checks sample three cover heights and drive loaded cargo into an upper side beam. Expanded acceptance will challenge blocked/unblocked motion, curved rather than box-shaped roof contact, upper yaw obstacles, compound slopes, cargo and rendering budget. Source baseline retained; remaining budget 19/20, rubric unchanged.

M83 accepted: Web wheel motion 8/8, clean console; native cart/compound-ground/towing/UI regressions pass. Reverse, rotated-heading, slope, vertical landing and parked cases all retain their physical motion and cargo. Remaining budget 16/20; cargo physics score stays 7.

M84 baseline 0/4: rays hit only the 1.3 m bed and full cargo passes the upper side beam. Initial cover implementation passes 4/4; roof center 2.38 m and side heights match the curved mesh within 2 mm. The beam stops the cart at z=101.331, bike speed zero and hitch gap 4.400 m. Add shared curved canvas/convex points, support rods, pose-clearance synchronization and convex support projection. Expanded turn/slope/pose/save challenge pending; remaining budget 18/20.

M78 full frozen-source acceptance: 853/853 across 60 native suites, all 327 managed files hash-verified unchanged. Total suite time 2,298.398 s. This checkpoint covers the source through M77, including terrain/shading continuity, prompt and roof fixes, the bike seam margin and articulated knees. It explicitly predates regional survey boards, checkpoint map guidance, sky/house detail, signed cargo wheels and the new canopy.

M84 expanded native challenge passes 14/14 (18.163 s): three curved roof contacts; actual loaded mount/hitch; upper beam stopping/resumption; compound slope alignment and turns; paused pose; upper yaw blocking and release; blocked/unblocked ground-pose tilt; loaded save restoration. Compound-ground bike/cart yaws are -1.149/-0.380, gap 3.323 m. Rendered review and broad regression/Web acceptance remain pending; remaining budget 17/20.

M84 rendered 14/14 (19.047 s); inspected the loaded covered cart at its workshop home. The capture also exposed a verifier input latch: its compound turn left forward held after braking. Release all controls before braking and require can_save() in the existing save/restore assertion, so that case represents a saveable stopped session. Production movement is unchanged. Preserve the first render log/image context; updated focused verification and full regression follow. Remaining budget 16/20.

M84 corrected save fixture remains 14/14 (18.158 s), now with controls released and can_save() required before the snapshot. Full source regression is being frozen next to cover the canopy's shared clearance changes and all recent milestones without mixing future edits into the evidence.

## Milestone 85 / round 01 — frozen native regression through M84

Freeze the current source and run all 63 default suites (909 minimum checks), including regional checkpoints, map guidance, signed wheels and the new cover. The separate M78 continuous-distance run already passed 23,953.6 m in 719.662 s, peak 25 chunks, 1,895 created /1,870 retired and max build 4.18 ms; this checkpoint still runs its ordinary streaming and flight suites but does not repeat that unchanged long route. All source hashes and required reports must pass before acceptance. Remaining budget 19/20; pending results, no score change.

M84 Web focused canopy challenge 14/14, clean console. Native pinned UI 15/15, 356 calls /105 FPS. The visible cart cover adds only two submissions to the previous village sample. The frozen M85 all-suite run and Web loaded-bridge/integration checks continue; canopy broad acceptance remains open.

## Milestone 86 / round 01 — seated rider clearance

- Collision critique: the motorcycle's lower chassis collision ends at 1.17 m, while a diagnostic of the actual posed rider's visible meshes reaches 2.405 m. The rider currently contributes no mounted collision. Challenge mounting beneath a rider-height ceiling and physically driving toward an overhead beam.
- Plan a convex rider envelope from actual posed visible mesh vertices, active only while mounted. Gate mounting on free rider space; include the shape in translation, yaw and visual-attitude clearance, without changing on-foot collision or character art. Reuse the convex support capability introduced for the cart.
- Preserve the diagnostic, baseline source and failed behavior. Native baseline pending; remaining budget 19/20, unchanged rubric. M85 remains an immutable checkpoint through M84, excluding this work.

M86 baseline 0/2: the rider mounts through a low ceiling and drives beneath the upper beam to z=73.338 at 21.833 m/s. Build a cleaned convex envelope from actual posed visible mesh faces; Mesh.create_convex_shape(clean=true) removes duplicate/interior vertices (https://docs.godotengine.org/en/stable/classes/class_mesh.html#class-mesh-method-create-convex-shape). Initial native correction passes 2/2, stopping at z=100.609 with zero speed. Mount, dismount and save ownership enable/disable the shape; visual attitude checks run before wing synchronization, then synchronize the rider to the final visual pose. Expanded lifecycle/yaw/attitude checks pending; remaining budget 18/20.

M84 Web loaded brook crossing 18/18 and full integration 16/16 pass with clean consoles. Final Web UI 15/15 is recorded separately. Frozen M85 continues the broader native regression on the exact canopy source, excluding the later rider work.

M86 expanded native 10/12. Mount/dismount, physical beam stopping, mounted/on-foot restore, pause and clear pose changes pass; the convex envelope has 59 cleaned vertices. The two upper-obstacle fixtures used the wrong Z sign for the rider's forward lean and sat behind the relevant body parts. Preserve that report and fixture. Move the posts to the measured forward pose and require the proposed turn/bank to intersect them before checking guard rejection, with separate removal controls. No production collision change for this fixture correction. Remaining budget 17/20.

M86 corrected focused native 12/12 (8.94 s). The turn fixture confirms before_clear=true and proposal_clear=false before yaw is rejected; removing it allows steering. The bank fixture confirms the proposal intersects, retains the safe pose, and resumes after removal. Clear/mounted/on-foot saves and pause retain correct ownership. Rendered rider-beam capture and existing vehicle/flight/clearance/cover regressions follow; remaining budget 16/20.

M86 rendered rider challenge passes 12/12 (9.895 s), with rider-clearance-m86.jpg inspected. Broad native first run passed rider/bike/flight/seat/steering/wing pose, then wing transition failed 12/13. The old final assertion wrongly required every collider after the chassis to be disabled, including the active rider. Tail reset had the same stale assumption (14/15). Preserved both source/assertion failures in m86-before; select all seven actual aircraft colliders through their owning interfaces and separately require the mounted rider to remain active. No production change. Corrected native wing transition 13/13, tail 15/15, touchdown 8/8, ground 11/11, canopy 14/14, recovery 8/8, save 22/22 and UI 14/14 pass; Web export succeeds. The canopy beam still correctly isolates cart contact without moving its fixture. Web rider/vehicle challenges pending. Remaining budget 14/20; rubric unchanged at 7.85.

M85 accepted: immutable source through M84 passes 909/909 checks in 63 suites, all 341 source hashes unchanged, 1,647.732 total suite seconds. See m85-regression-summary.json and m85-validation. This closes M84's broad native acceptance; no score increase. M85 excludes M86 rider and M87 ambience.

M86 accepted: Web rider 12/12, flight 22/22, covered cart 14/14 and UI 15/15, all clean consoles; village 356 calls /59 FPS. Native focused/rendered and shared vehicle/flight/recovery/save checks pass. The rider remains a conservative convex envelope of the fixed pose, not per-limb collision or dynamic hand IK. Rubric remains 7.85, flight/cart/visual readability 7 and all other categories 8. Remaining budget 14/20.

## Milestone 87 / round 01 — bounded exploration wind

Critique: outdoor exploration is silent between footsteps, engine and combat cues. Add one subdued preloaded circular wind voice, gradual gain changes from shelter and altitude, and no per-region audio allocation. Original filtered noise is generated by tools/generate_wind.py (12 s, 529,244 bytes); existing effects remain unchanged. Files: scripts/audio/wind_ambience.gd, game_audio.gd, assets/sfx/wind.wav, tests/ambience_verifier.gd/catalog. Baseline 0/2 confirms absent voice/playback; initial harness attempts failed registration then inferred-variable compilation and are retained separately. First implemented check 1/2 queried before an idle-frame audio update, with an exit leak from immediate quit; explicitly wait for idle processing and silence audio before report. Expanded lifecycle/shelter/loop/voice-budget verification follows. Remaining budget 18/20; acceptance pending, scores unchanged.

M87 expanded headless challenge passes 11/11 (7.897 s): active loop, bounded 529 KB clip, physical roof attenuation, exposed restoration, high-altitude ceiling, actual loop wrap (0.549 s), pause, smooth resume, repeated long-distance position changes (10 audio children; 13 context queries), and disable/reset. The shelter target is 0.03162 vs exposed 0.12589; ground exposure 0.06314. Correct the two existing audio budget checks to retain eight effects plus engine and explicitly account for the one new wind voice. No changes to old effects or voice allocation. Rendered/native regression and Web playback verification pending; remaining budget 17/20. Automated playback state is not a claim of subjective listening quality.

M87 rendered native 11/11 (8.776 s), including advancing loop playback. Native ambience/feedback/incoming-damage/flight/UI regression passes and Web export builds. Initial Web result is 10/11 with a clean console: playing=true but seek clock remains 11.800 before user activation. Retain this autoplay-suspended result; repeat with actual canvas input rather than weakening the elapsed-playback check. No production change for the browser activation requirement; normal play starts with the Begin button. Remaining budget 16/20; Web acceptance still pending.

M87 activated Web retry still reports 10/11 (seek clock 11.803), so user activation alone does not explain the result; the earlier autoplay diagnosis was premature. Godot's upstream issue #119355 documents delayed Web sample playback-position reporting after starting/replaying, despite audible playback (https://github.com/godotengine/godot/issues/119355). Preserve the short-seek fixture and both reports. Allow 120 physics frames after seek instead of 45, retaining the actual wrapped-position requirement and all other checks. This probes the documented reporting lag without changing the game's audio backend or inventing a passing clock. Remaining budget 15/20.

M87 delayed Web sample probe advances to 12.768 but remains 10/11: this is not a suspended clock. Inspection of the actual exported index.js shows sample position equals cumulative worklet samples plus initial offset, while its ended callback restarts a new source using that offset. Preserve the exact exported code excerpt and fixture in m87-before. For continuous wind, explicitly select AudioServer.PLAYBACK_TYPE_STREAM so Godot's mixer owns the seamless WAV loop and native/Web loop-position semantics agree. This affects only one wind voice; existing effects retain default playback. Reverify native and Web, including village performance. Remaining budget 14/20; no acceptance claim yet.

M87 stream-backed native passes 12/12 with direct AudioEffectCapture evidence: 81,920 frames, RMS 0.018244, peak 0.073533 across the loop. Web stream retry still shows 11.806, despite the early click, so backend selection alone is not proof of browser activation. Add an explicit Web-only verifier button after the canvas and audio driver have loaded, await its real pressed event, then run the test. This avoids treating a click during the loading screen as successful activation. The native branch remains automatic. Preserve all failed Web reports; no production sound or timing is faked. Remaining budget 12/20.

M87 activation screenshot reveals the current embedded browser panel is only 395 pixels wide with a letterboxed game; previous x=800 clicks were outside the canvas. The explicit loaded button is visible at approximately (196,422), and actual input now targets that observed location. This explains why the earlier click attempts were not evidence of activation. Keep the visible gate so future audio runs do not depend on guessed panel size.

M87 actual activated Web challenge passes 12/12 (9.767 s), clean console. Stream loop phase wraps to 1.820 s; mixer capture contains 96,768 frames, RMS 0.018174 /peak 0.073276. This is real digital audio output, not merely a playing flag. Native focused capture 12/12 and earlier feedback/incoming-damage/flight/UI regressions pass. Final native rendered capture and Web performance are being recorded. Retain sample-backend failures and activation misdiagnoses; the dedicated stream loop is deliberate, with ten total audio voices. No subjective listening-quality claim. Remaining budget 12/20; scores unchanged.

M87 accepted: final rendered native 12/12 (9.999 s), 96,256 captured mixer frames /RMS 0.018043; Web gated 12/12, clean console. Final Web UI 15/15, 356 calls /60 FPS. GameAudio keeps eight effects, one engine and one stream-backed wind loop. README/architecture record the Web audio activation gate; source generation does not overwrite existing effects. Rubric remains 7.85. No claim of subjective mix quality.

## Milestone 88 / round 01 — player audio preferences

Critique: the new ambience and existing effects lack in-game volume/mute controls. Add a compact start/pause-menu row with master-volume slider, readout and mute toggle. AudioPreferences stores these independently from journey saves using a validated, size-bounded ConfigFile and atomic replacement; a 0.3-second UI debounce coalesces slider changes. Preserve baseline source and failed 0/1 menu assertion in m88-before. New files audio_preferences.gd and audio_settings_panel.gd; Main supplies the preferences reference to GameHUD. Verify actual menu input, pause/weapon safety, mute/zero gain, debounce, reload and invalid preference rejection without touching the player's settings file. Remaining budget 18/20; pending native/Web acceptance, unchanged score.

M88 expanded native 11/12 and rendered 11/12 exposed a real layout defect: controls extended to y=709 while the panel ended at y=706, with the lower row visibly clipped by the scroll area. Preserve clipped-controls.jpg and round3 assertion evidence. Move the long keyboard reference below the primary actions and sound row so Continue/Load/Audio are visible together; center the slider/readout vertically. Keep the full visibility assertion. Input, keyboard increments, master mute/zero gain, atomic persistence, fresh reload and malformed/out-of-range/NaN rejection already pass. Remaining budget 16/20.

M88 corrected rendered menu passes 12/12 (4.248 s). Sound row now sits at y=490..542 within the panel ending at 706; inspected ui-native-audio-settings-m88.jpg with centered slider and unclipped actions. Broad native audio settings 12/12, ambience 12/12, UI 14/14, panel combat 15/15, journey save 22/22 and feedback 9/9 pass; Web export builds. Web actual control and independent cross-page settings probe follow. Remaining budget 15/20; no source-save schema changes and no user preference file modified by tests.

## Milestone 89 / round 01 — full regression through audio preferences

Freeze the source through M88 and run every default native suite, preserving source hashes and reports. This covers the rider collision, stream-backed ambience, and preference/menu integration together with the full gameplay/world/worker catalog. Keep M88 Web acceptance separate until actual controls and the fresh-page preference probe finish. The unchanged long traversal already passed at M78; this run uses all ordinary streaming/flight suites without repeating the 12-minute distance case. Remaining budget 19/20; pending, unchanged rubric.

M88 accepted: Web sound controls 13/13, fresh-page audio preference restore 3/3, and final UI 15/15, clean consoles. Settings restore to 35% and muted through a separate probe path; no journey or player-preference file changes. Native focused/rendered 12/12 and menu/combat/save/audio regression pass. Final Web performance is recorded in m88-web-ui-report.json. Rubric remains 7.85; remaining budget 15/20.

M89 froze 360 source files, 66 default suites, 945 minimum checks. The full native run is active; its future acceptance requires all results and unchanged hashes.

## Milestone 90 / round 01 — regional broadleaf silhouettes

Visual critique: streamed broadleaf trees have a single spherical crown on a straight pole, making the forest look repetitive at walking distance. Improve the shared tree mesh with a forked trunk and clustered, varied canopy shapes. Preserve placement RNG, biome counts, clearings, collision policy, chunk ownership, the shared mesh cache, and one MultiMesh submission per foliage kind. First capture the existing forest from a fixed camera, then compare the updated source and measure draw calls/frame rate. Reuse region/streaming/forest delivery checks rather than adding assertions that merely count artistic parts. Remaining budget 19/20; visual score stays 7 until reviewed. M89 remains immutable and excludes this work.

M90 fixed-camera comparison inspected: single crowns become clustered crowns with forked stems, while forest draw calls remain 162 and the resident window 25. Shared model vertices rise from 456 to 2,064; this is a real geometry cost, so Web frame-rate and streaming checks are required before acceptance. RegionScenery delegates only broadleaf geometry to RegionalTreeMesh; no population/RNG/count/clearing/collision code changed, and pines retain their original geometry. Evidence: forest-form-m90-before.jpg and forest-form-m90-after.jpg, render-only logs explicitly excluded from verifier totals. Native region/forest-resource/backdrop/world checks and export follow. Remaining budget 18/20; visual score remains 7.

M90 native region 18/18, forest resource 14/14, backdrop 7/7 and world 15/15 pass. The world probe includes real flight, distant worker logistics and quadrant collision; 25 chunks, 215 created/190 retired, max build 3.61 ms. Add one render-only forest budget sample to the existing regional verifier, because stable submission count alone does not cover the denser tree mesh. Its native headless minimum remains 18; rendered/Web total becomes 19. Replace its old frame_post_draw capture wait with two physics frames plus force_draw to avoid background capture hangs. Rendered regional review and the updated Web export follow. Remaining budget 17/20.

M90 rendered region 19/19: forest 188 calls /120 FPS, max chunk build 3.30 ms. Web region 19/19, clean console, same forest 188 calls /60 FPS. Updated broadleaf silhouettes retain deterministic scenery retirement/recreation and resource/save behavior. Final Web backdrop check remains in progress; geometry remains blockout and the forest still lacks authored environmental density. No score increase.

## Milestone 91 / round 01 — forward worker task pose

Animation critique: WorkerActor applies a negative X work swing to a downward-pointing arm, lifting the hand behind the worker. An actual Farm job confirms 0/30 sampled work frames reach toward the resource, minimum projected reach -0.482 m. Preserve baseline source/verifier/report in m91-before. Correct the swing direction and gently face the job's source during visible work, with a validity guard for removed resources. Keep the generic JobDefinition source interface and existing FSM, movement, stock and delivery behavior. Verify task pose, pause, facing correction, a removed source reference, and completed stock movement. Remaining budget 19/20; no acceptance claim, unchanged rubric.

M90 accepted: Web region 19/19 (forest 188 calls /60 FPS), backdrop 8/8 (136 calls /60 FPS), clean consoles. Native region/resource/world/backdrop and rendered region checks pass. The larger shared tree mesh adds no submissions, body simulation or RNG changes. Forest silhouettes improve, while sparse authored detail remains visible debt; visual score stays 7.

M91 corrected initial task probe passes 30/30 forward reaches, least 0.203 m (baseline 0/30, -0.482 m). Expanded native 7/7 (23.535 s): actual acquired Farm job, forward work cycle, paused pose/clock, correcting a deliberately reversed facing (0.390 m forward reach), safely tolerating a freed source after acquisition, exact five-olive harvest/delivery and neutral idle arm. The change is an abstract forward working gesture, not hand-to-resource IK. Rendered review, multi-worker/save regression and Web verification follow. Remaining budget 17/20, unchanged rubric.

M91 final rendered 7/7 (24.349 s), inspected worker-reach-m91.jpg from the working-arm side during the forward phase. Keep the earlier far-arm capture separately. Broad native worker reach 7/7, two-worker integration 25/25 and save 22/22 pass; Web export succeeds. Focused Web pose/lifecycle/actual-delivery checks are now running. Remaining budget 16/20; no stock, FSM or work-duration changes.

M91 accepted: Web worker reach 7/7, clean console, matching native/rendered and multi-worker/save regression. Forward pose, pause, source validity and actual five-item delivery are proven. Remaining budget 16/20; rubric unchanged.

## Milestone 92 / round 01 — player weapon vehicle obstruction

Code review finds player rifle rays use masks 5/1 and player melee/lock sight uses world-only mask 1, omitting the vehicle bit 8. Probe actual parked aircraft geometry with both blocked and clear rifle shots before changing production code. Initial fixture is inconclusive (3/4): the clear-shot control also misses. The Camera3D remains under SpringArm3D, which can reposition it despite disabling the orbit script. Preserve the invalid fixture/report in m92-before; detach the test camera from its spring arm for controlled aiming, then restore it after the test. Scope is player weapon/lock obstruction; retain ordinary interaction LOS semantics. Remaining budget 19/20; no gameplay fix or acceptance claim yet.

M92 valid baseline after detaching the fixture camera is 3/4: blocked shot damages the enemy to 42 HP, and removing cover also damages it to 42. Preserve this valid baseline separately from the faulty camera fixture and its typed-variable compilation failure. PlayerCombat now uses world+vehicle cover (9) and world+vehicle+hostile shot queries (13); its melee/lock sight uses the same cover mask. DamageSystem.clear_line accepts an optional mask while retaining default 1 for existing interaction, worker and enemy callers. Corrected native 13/13 (5.062 s): physical tail cover, ammo use, clear-shot control, clear-camera/blocked-muzzle geometry, exact tracer impact, lock prevention/release, actual in-range chassis cover and clear melee control. Enemy navigation/sight and body collision still have separate vehicle-layer semantics and are a follow-up audit item. Rendered and broad combat/seat/integration regression plus Web verification follow. Remaining budget 16/20; unchanged rubric.

M89 accepted: all 945/945 checks across 66 default suites pass, all 360 frozen source hashes unchanged, 1,668.939 total suite seconds. This checkpoint covers through M88, including rider/audio/menu changes, and excludes M90 trees, M91 worker reach and M92 player vehicle cover. See m89-regression-summary.json and m89-validation; unchanged quality scores.

M92 rendered challenge 13/13 (5.935 s). The initial capture retained a stale Hit label from its earlier clear-shot control because the dummy brain is disabled; reset the dummy's label state before the blocked-muzzle capture and preserve the first image separately. Final rendering and combat/lock/bike/seat/integration regression use the corrected fixture. Production ray masks are unchanged from the passing focused run. Remaining budget 15/20.

M92 final native regression passes player vehicle cover 13/13, combat 34/34, lock framing 12/12, bike 26/26, seat safety 12/12 and integrated gameplay 16/16 (103.0 s). Web export complete; focused Web obstruction checks follow. No player interaction, mounting or integration regression observed.

## Milestone 93 / round 01 — hostile strikes and occupied rider visibility

The independent baseline probe confirms the enemy-side inconsistency: 2/4, with actual motorcycle occlusion present but _sees() true and a committed strike reducing player health to 87 through the chassis. Removing the bike also correctly permits 13 damage. Preserve the diagnostic and sources in m93-before. Use the same combat cover mask for hostile sight/strike validation, while explicitly treating the mounted rider's collision shape as the target rather than invulnerable cover. Bind a transient aim anchor/receiver through HealthComponent and VehicleSeat ownership; leave save payloads and ordinary interaction queries unchanged. Verify cover, removal, real mounted damage, dismount, pause and ownership restoration. Physical NPC movement/navigation around vehicles remains a separate follow-up. Remaining budget 19/20; unchanged rubric.

M93 corrected independent cover probe passes 4/4: blocked hostile sight false, blocked strike leaves 100 HP, removed cover permits 87 HP. The diagnostic initially reused its baseline JSON output path; restore that original JSON exactly from the unchanged baseline log, retain the corrected result as m93-round2-report.json, and move subsequent probe output to its own path. Add a Marker3D at the seated upper chest: PlayerVisual.torso's origin is at the waist, so using its origin would put the mounted aim point behind the chassis. This marker adds no rendered geometry and follows the existing rider pose. Expanded ownership/strike verification is next.

M93 expanded native focused verification passes 16/16 (7.0 s): real chassis cover, blocked/clear committed strikes, actual mounting, first-hit rider shape, exposed mounted damage (87 HP), world cover and removal, dismount cleanup, mounted journey restoration, pause and aircraft tail cover. No whole-bike ray exclusion is used. User requests wrapping up and pausing until the next usage reset; do not start M94. Run the bounded native combat/seat/save/integration regression, export and write a restart handoff. M92 focused Web 13/13 is saved with clean console; its final Web integration tab disappeared with the browser session before retrieval, so that specific result remains unverified. No M92/M93 final cross-platform acceptance claim yet.

M93 user-requested pause: final native regression 125/125 across hostile_cover 16, vehicle_cover 13, combat 34, seat_safety 12, rider_clearance 12, save 22 and integration 16; all fresh reports and error-checked logs pass. Web export succeeds. Preserve reports/logs in m93-wrap-validation, freeze the source as m93-pause-source with SHA-256 manifest, and record docs/RESUME_HANDOFF.md. This is a pause snapshot, not a full accepted checkpoint. M93 rendered/Web acceptance and the lost M92 Web integration result remain pending. No new milestone, automation or continuation started. Await the user’s next request.
