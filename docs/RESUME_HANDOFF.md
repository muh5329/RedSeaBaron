# Paused after M101 — resume only when the user asks

Latest user instruction: “finish the export then prepare the resume file for next session.” This overrides the earlier continuous-milestone instruction. Finish the current wrap-up, then stop. Do not start M102, an automation, or another agent. No agents or automations are active.

Project: `/Users/mun/Documents/Projects/Red Sea Baron`. Native Godot: `/Applications/Godot.app/Contents/MacOS/Godot` (4.7). This workspace is not a Git repository. Preserve existing source, failed rounds and frozen checkpoints.

## Current build and controls

The final Web export through M101 succeeded, with a clean export log. Files are in `builds/web/`; launch `tools/serve.sh` if needed and open http://127.0.0.1:8067/. The local server was left running. Native: open `project.godot` and press F5, or run Godot with `--path .`.

- Propeller is in front of the aircraft, ahead of the front wheel, with matching sweep/shaft collision.
- S / back takes off above 12 m/s (44 km/h) and pulls up; W / forward descends in flight.
- Space boosts in aircraft mode; Shift brakes. Ground motorcycle Space remains its brake.
- T deploys wings while driving on clear ground. Folding requires landing and slowing below 8 m/s (29 km/h). Detach the cart before deployment. Physical obstacles, including workers and hostiles, block expansion safely.
- M opens the map. A north-up minimap shows roads, equipment, checkpoint and waypoint guidance. Clicking landform/region labels selects exact destinations; equipment/worker tracking and background waypoints remain available.
- The streamed world includes physical dunes (6600,3000), valley (-800,-6500), mountain/snowcap peaks (-1800,-8600) and (1100,-10300), biome relief, dry beach destination (85,60), and the quarry cave (4829,1223). Most regional scenery remains procedural blockout.

## Accepted work and evidence

- M94–95 requested flight/terrain/minimap changes: 160/160 final native checks, 110/110 Web checks, clean consoles; rendered controls 13/13 and cartography 15/15. See `docs/evidence/m95-acceptance-summary.json` and `m95-validation`.
- M97 NPC navigation: physical vehicle obstruction, moved/deployed/removed occupancy, mounted rider approach/strike, startup relocation and stationary cache reuse. Native/rendered 15/15; Web 59/59 across navigation, water, integration and UI.
- **M98 is the latest accepted complete immutable checkpoint:** 1,024/1,024 checks across 72 default suites, all 384 hashes unchanged and independently rechecked, 1,760.808 summed suite seconds. See `m98-regression-summary.json`, `m98-validation`, and `m98-source-manifest.json`. It excludes M99–101. It does not repeat the optional 23.95 km flight; the last continuous distance evidence is M78.
- M99 exact map destinations: native six-suite matrix 84/84, rendered 17/17, Web 56/56. Labels previously created waypoints up to 1,923 m from the named feature. Two old background fixtures were moved away from the now-selectable dune marker; their failures are retained in `m99-before`.
- M100 vehicle motion against NPCs: native 303/303 across 17 suites, rendered 14/14, Web 61/61 with clean consoles. Bike/wing/cart motion now respects hostile and worker bodies; actual loaded towing has zero overlapping frames and preserves 40 ore. See `m100-acceptance-summary.json` and `m100-validation`. A cover fixture now positions its opponent behind the aircraft before deploying because its old front position correctly blocks the propeller.

## M101 wrap-up status

Repeated vehicle movement during initial navigation construction could leave an intermediate cell falsely blocked. Registered baseline: 15/16. `NavigationController` now remembers only vehicle-occupied cells actually observed during initial sampling, includes them in the first reconciliation, then discards the history. It does not resample the whole grid twice.

Final native matrix: **82/82** — vehicle_navigation 16, worker 25, multi_worker 25, integration 16. All logs are clean. Web export succeeded. Final exported Web navigation 16/16 and UI 15/15 pass (31/31), with clean consoles. UI remains 372 calls /120 FPS. The normal game URL was restored. A full Web integration replay against M101 has not yet been run; the previous M100 Web integrated loop passed 16/16.

Evidence: `m101-regression.log`, `m101-validation`, `m101-wrap-summary.json`, `m101-web-export.log`, and `m101-web-build-manifest.json`. Preserve `m101-before`, the registered failing report, and the temporary candidate's typed-array failure. Raw SceneTree diagnostics emitted two-instance shutdown warnings; only clean registered runs count as acceptance.

## Next session

1. Wait for an explicit user request to resume. Read this file and the latest `docs/GAUNTLET_PROGRESS.md` entries.
2. Finish M101's Web integration check with `?verify=integration` (about 103 seconds), save its visible `#integration-report`, and inspect console warnings/errors since the latest `RSB_READY`. Restore the normal URL afterward. Re-list browser tabs; IDs and bindings can change between sessions.
3. Then resume the adversarial review. Flight/cart feel and regional visual density remain the weakest areas. Do not claim the full 25 km world is authored or finished. A new complete frozen checkpoint may be useful after the next coherent changes; never edit or relabel M98 or failed M96.

Relevant files: `scripts/ai/navigation_controller.gd`, `tests/vehicle_navigation_verifier.gd`, `scripts/vehicles/vehicle_clearance.gd`, `bike_controller.gd`, `vehicle_transformation.gd`, `aircraft_tail_collision.gd`, `cargo_cart.gd`, `rider_collision.gd`, `tests/vehicle_actor_clearance_verifier.gd`, `scripts/ui/field_map.gd`, `scripts/ui/travel_minimap.gd`, `scripts/world/world_landforms.gd`, `tests/map_landmark_verifier.gd`, `tests/suites.json`, `README.md`, and `docs/ARCHITECTURE.md`.

Run targeted native verification with `./tools/verify.sh --suites SUITE1,SUITE2 --no-export`; omit `--no-export` to export afterward. Do not mutate managed live source during a live test/export pipeline. Frozen checkpoints may run while live source changes. Capture native rendered evidence with `-- --verify-SUITE --capture`. Use two physics frames plus `RenderingServer.force_draw()` for capture; avoid background `frame_post_draw` waits. Do not overlap rendered/Web games when benchmarking.

## Critique and scores

Average remains **7.85/10**. Flight handling, cargo/cart physics and visual readability are 7. The other 17 rubric categories are 8. Physics is kinematic/arcade, scenery is sparse, poses are approximate, and there is no hand IK. Performance evidence is from one Mac/browser setup; the latest M101 Web UI measured 372 draw calls /120 FPS. Do not raise scores merely because more regression checks pass.

Failed M96 is preserved: an obsolete Space/Ctrl water-flight fixture caused 426/428 before stopping, with all 382 source hashes unchanged. Its input fixture was corrected and the complete M98 checkpoint passes. All earlier failure evidence and the M93 pause snapshot remain intact.

The frozen `docs/evidence/m101-pause-source` snapshot and `m101-pause-source-manifest.json` preserve this handoff and current source. It is a pause snapshot, not a complete all-suite checkpoint. No new milestone or scheduled continuation was started.
