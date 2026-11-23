# MARS HOMER

Rehabilitation games for the MARS robot, in one Godot 4.6.2 application: patient records, assessments, sixteen games, guided device setup, uploads to the study server, and voice guidance in English and Tamil.

Open `project.godot` in Godot 4.6.2 and press F5, or run the portable build `../dist/MARS_HOMER/MARS_HOMER.exe` (keep the `.pck` file beside it). No Unity is needed. Windows uses PowerShell, and Linux / Raspberry Pi uses Python 3, only for the serial-port bridge.

## Games

All games run for a 60-second trial, save the same session and raw-data files, and pause or finish from the MARS button.

| Movement | Games |
| --- | --- |
| ML | Space Shooter, Match Catch, Fireworks, Space Tour |
| AP | Ping Pong, Reef Runner, Character Flight |
| MLAP | Diamond Catcher, Table Wiping, Fish Rescue, Bubble Sparkle, Vegetable Soup, Colour the Picture, Ironing, Mopping, Tidy-up Sorting |

The five daily-life games (Vegetable Soup, Colour the Picture, Ironing, Mopping, Tidy-up Sorting) are patient-paced: one task at a time, no speed control, selection by holding the hand still for 0.3 s. Each runs at its own screen size below the HUD bar. The hand is `core/game_pointer.gd`: the robot inside the patient's assessed range on the device, the mouse in simulation. Mopping uses a different room every trial and keeps dust on open floor; Ironing maps the range onto the garment.

## Screens

| Screen | What it does |
| --- | --- |
| Login | Patient search with suggestions, and create. In device mode there is also a Diagnostics button. |
| Welcome | Minutes left today, day of training, and a pie per previous day. |
| Set up MARS (device) | Connect, calibrate, activate, attach the arm, choose the training plane, ready. One MARS-button action per step, with the reference video. |
| Choose movement | ML / AP / MLAP cards with minutes done and prescribed, assessment ages, the games, a movement video. |
| Assessments | ML, AP and MLAP ranges and the arm weight. Saving an MLAP range goes straight on to a new arm-weight assessment. |
| Game and results | Trial, saved-results card, back to Choose movement. |
| Summary | Hits, stars and minutes per day. **Upload data now** sends the files and runs the uploader. |

## Using it

**Simulation** (default): leave MARS device mode off, enter a user ID and play with the mouse. Data goes to `user://simulation-data`, separate from real records.

**Device**: switch to MARS device in the hidden login options (Ctrl+Shift+X), enter the COM port in **Patient, setup & records** and use **Save port and test connection**; the app then connects by itself. Device trials need healthy telemetry, the right limb and training plane, calibration, position control, an attached arm, current assessments and prescribed time left. A robot error holds the game and shows "Device has issue. Call the engineers."; the trial can still be finished from the MARS button. Changing the training plane invalidates every assessment, so all must be redone.

**Display**: full screen at Full HD; **F11** toggles it. **Ctrl+G** changes the reach speed (not in patient-paced games).

## MARS button

Every screen works with the handle button alone (**F2** in simulation).

| Where | Tap | Hold (1 s; 1.5 s in a trial) |
| --- | --- | --- |
| Menus, setup, assessments | Next control | Select |
| During a trial | Pause / resume | Finish and save |

The footer shows the current meaning (on Welcome it fades after a few seconds).

## Rules

- Reach speed is limited to 0.025–0.25 m/s. Success below 80% slows the next trial and above 90% speeds it up. Durations follow the assessed range: ML horizontal, AP vertical, MLAP the mean.
- Patient-paced games (Table Wiping, Fireworks, Bubble Sparkle and the five daily-life games) save ReachSpeed and GameParameter as 0.
- An arm weight older than the latest MLAP range is not valid.
- A target still open at 60 s is annotated as unresolved.

## Data

```
<user-id>/data/configdata.csv     sessions/sessions.csv     rawdata/raw-sess01-trial001-FR-MLAP.csv
<user-id>/data/rom/MLAP-rom.csv   armweight/armweight.csv   trainingplane/trainingplane.csv
<user-id>/data/errorlog/errorLog.csv                        applog/godot-events.csv
```

Session, raw, range, arm-weight and plane files keep the original column names and order. Four `Angle1`–`Angle4` columns follow the raw columns. Unavailable device values stay empty; simulation never writes fake robot measurements.

## Server, agent and updates

- **Server:** NeuroDash is built in: the patient list (with Refresh), the lock, and the CSV uploads at the end of each trial. Set the server address, device name and laptop name in settings; **Test connection** checks the server.
- **Agent:** the local `agent.py` (127.0.0.1:5055) is detected automatically. The app calls `/start` at login, `/trial-ended` after each trial and `/stop` at the end. The agent alone does the lock.
- **Updates:** the app checks the latest GitHub release at start-up (`core/updater.gd`). To release, commit, then `git tag v1.1.0 && git push origin v1.1.0`; `.github/workflows/release.yml` builds the Windows and Raspberry Pi packages and publishes them.
- No credentials are bundled; the uploader keeps its own.

## Voice, sound and fonts

Scene prompts and trial lines are spoken in English or Tamil (`assets/voice/`; regenerate with `platform/generate_voice.py` from `assets/voice/phrases.json`). The main theme is the only music, and each game has its own capture and miss sounds. Fonts: Atkinson Hyperlegible Next, plus Titan One for in-game feedback.

## Raspberry Pi and Linux

The project uses the Compatibility renderer so it runs on a Raspberry Pi. Run `platform/run_pi.sh`; the serial port is `/dev/rfcomm0` or `bt:<address>` (the Python bridge handles rfcomm). Windows uses `platform/serial_bridge.ps1`.

## Tests and build

```
godot --headless --path Godot --script res://tests/<name>.gd
```

Main tests: `integration`, `system_test`, `flow_test`, `nav_test`, `gameplay_test`, `plane_data_test`, `data_parity_test`, `mlap_games_test`, `weight_follow_test`, `voice_guidance_test`, `indent_test`, and the bridge tests. The `render_*.gd` scripts (run without `--headless`) save screenshots to `test-output/`. Tests use fake ports and never contact the real agent, server or uploader.

GDScript in `core/` and `tests/` is indented with **tabs**; `indent_test` checks this.

```
powershell -File Godot/platform/build_windows.ps1 -GodotExecutable <path-to-Godot-console.exe>
```

This writes `dist/MARS_HOMER`. See [MIGRATION.md](MIGRATION.md) for coverage and [GAME_NOTES.md](GAME_NOTES.md) for per-game design history.
