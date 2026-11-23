# Game and interface notes (history)

Per-game design and revision notes, moved out of the README. Some predate later changes (the Character Flight music was removed, Unity import is gone); the README describes the current behaviour.

## Teal & Cobalt interface
The interface uses Deep Navy #111827, Slate #1F2937, Teal #0D9488,
Sky #38BDF8, Coral #F97316 and Off-White #F3F4F6. Bright sky focus rings
remain visible for keyboard and MARS-button navigation. Darker teal action
buttons retain readable off-white labels; coral is reserved for attention.
Atkinson Hyperlegible Next is bundled locally, including its SIL Open Font
License in assets/fonts/OFL.txt. Source: https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegiblenext
Headings use a heavier variable-font weight. Menus use a restrained animated
navy backdrop, short eased entrances, and teal progress fills.
Character direction uses a brief interpolated turn and remembers its facing
when stationary. Ship banking and opponent motion use frame-rate-independent
easing. Fish/shark turns respect Fish Rescue's reduced-motion preference.
These presentation changes do not filter the robot's recorded position or
change hit testing, scoring, trial duration or adaptation.

## Reef Runner (formerly Tuk Tuk)
The AP game now uses a swimming clownfish, underwater scenery, reef gates,
bubble trails and animated tail/banking. This is a presentation replacement:
TT remains the stored game ID, with the same 60-second duration, target generation,
72px gap tolerance, speed adaptation, controls and CSV fields. Fish Rescue remains
a separate MLAP game. Reference-image coins/tap-to-flap rules are not introduced.

### Reef Runner motion revision
The reef openings now have broad textured lips at the original +/-72px scoring
boundary, rather than stretched full-height pointed sprites. Continuous mirrored
background scrolling, water refraction, moving caustic highlights, kelp sway,
bubble trails, strong tail/fin deformation and eased banking share the gameplay
clock. Pausing or losing device tracking freezes their animation.
Verification: tests/reef_motion_test.gd compares live rendered frames for visible
water and orange-fish changes, verifies a frozen paused frame, and checks resume.
Gameplay and integration checks still cover scoring, duration, adaptation and CSV.

### Reef journey revision
Reef Runner now places the player at x=380 of the 1600px field. The gate still
arrives at the player after the same prescribed reach duration and uses the same
vertical scoring threshold. Passed gates remain cosmetic, drift left at their
original speed, and are removed beyond x=-180; they never score twice.
The panorama pans without mirroring, transitions to kelp ruins at 16–23 active
seconds, and becomes dusk at 39–47 seconds. Background fish schools, a turtle
visit, pulsing jellyfish and foreground seagrass are decorative, with no new
input demands. The fish uses tail deformation, body motion and an independent
paddling fin. All use the paused gameplay clock.

## Chhota Bheem: Laddoo Flight
Choose AP / Forward-back, then Chhota Bheem. This is an additional game; Reef
Runner remains available. Its CB identifier keeps results and adaptation separate
while using the same 60-second trial, AP controls, target arrival interval,
vertical gap tolerance and CSV schema. A glowing laddoo marks each passage; a
successful passage records one hit, not an extra collectible score. Misses,
pause/resume and off-camera obstacle cleanup follow the same shared mechanics.
Artwork and animated flight are inspired by the supplied sunset village video;
this is not a frame-for-frame reproduction of its generated animation.

## Character Flight cast and music
Under AP / Forward-back choose Character Flight, pick Bheem, Chutki, Raju,
Mr Bean, Rajini or Vijay, then Start flight. Cards preview their own original
synthesized music. Music on/off and volume are remembered. These are original
short themes, not film or television recordings.
Each character has distinct hover/banking, local hair/cloth/foot/tie movement,
a success animation and a gentle miss reaction. Rajini and Vijay accent success
with their raised hand; Rajini also has an occasional glasses glint. All motion
uses the active gameplay clock and freezes with pause or tracking loss. Music
pauses/resumes and stops on trial completion.
Character choice is cosmetic: scoring, the CB game identifier, shared CB speed
adaptation and CSV columns remain unchanged. The event log records the chosen
character alongside the raw trial filename. Replay uses the selected character.
Tests: characters_test.gd checks all six assets, poses, music loops, pause/resume
and stop; characters_preview.gd records the six-character demonstration.

## Day, evening and night variety
Every 60-second trial now moves from day through evening into night, with gradual lighting transitions around 20 and 40 seconds of active play. Pausing freezes the cycle. Fish Rescue retains its explicit day/night accessibility override; automatic lighting follows the trial clock.

Reef Runner and Character Flight rotate three gate appearances: original scenery, branching coral/foliage, and textured stone ruins. Resolved gates retain their appearance, scroll behind the character and are removed beyond the left camera edge. Other games rotate appropriate target looks (asteroids, gems, ball markings, stain colours, fish colours and bubble ornaments); Fireworks cycles through its four existing effects without consecutive repeats. Target locations, opening tolerance, reach timing, difficulty adaptation, 60-second duration and saved-data columns remain unchanged.

Validation: `tests/variety_test.gd` renders all ten games at day/evening/night; `tests/gameplay_test.gd` also checks gate appearance retention, variation and off-camera cleanup.

### Match Catch visual refresh
Match Catch now has a layered garden with drifting clouds, gently moving foliage and floating lights, following the shared day/evening/night cycle. Glossy balls and the woven basket share colour-independent symbols (diamond, ring, waves, star). The colour cue sits below the playing field. Balls render at their true collision centres; the basket leans smoothly with movement and compresses as a caught ball drops inside. Catch effects retain the captured colour even when the next basket colour changes. Gameplay and saved data remain unchanged. `tests/match_motion_test.gd` checks rendered scenery, leaning, catch response and pause freezing.

### Space Shooter destruction and audio
Asteroid hits now produce a short local impact core, two expanding shockwave rings, fourteen rotating fragments and twenty-two fading ember trails. Rock and ice variants use matching effect colours. Effects expire after about a second, freeze on pause, and do not alter collision, scoring, speed adaptation or saved data. Three original synthesized explosion sounds replace the generic win sound for Space Shooter, with a quieter separate laser pulse. Pause, hardware hold, sound-off and trial end affect both sound players. `tests/space_effects_test.gd` verifies particle cleanup, single scoring, variant audio and audio lifecycle; the gameplay suite also passes.

## Variety, characters and exit

- **Exit** (bottom right of the first screen) saves any running trial, releases the robot and closes the application.
- Every trial of a game changes its lighting (day, evening or night) and its scenery variant, so the same game never looks the same twice in a row; nine consecutive trials cover every pairing. Fish Rescue, Bubble Sparkle and Fireworks also rotate their own backdrops and themes.
- Character Flight picks a random pilot for every trial (never the same one twice in a row). Each pilot chases their own collectible: Bheem a laddoo, Chutki a lotus, Raju a mango, Mr Bean a teddy, Rajini golden shades and Vijay a football.
- Targets appear immediately after the previous one is achieved in every game.

## Target timing and real-world distance (as in Unity)

The patient's measured range is mapped linearly onto the whole playing field (as Unity's `unityXToRobotZ` / `unityYToRobotY` do), so every target requires real movement across the assessed range. Reach duration is `range / reach speed` (ML: width; AP: height; MLAP: mean of both, others.cs `GetReachDuration`), and each game turns that into its own target clock, checked by `tests/unity_timing_test.gd`:

| Game | Target clock |
| --- | --- |
| Space Shooter | Asteroid falls from y 5.19 to −3 in one reach duration; a miss is counted when it arrives. It spawns anywhere across the full width. |
| Match Catch | Balls fall from y 5 to −5 in one reach duration (they meet the basket at y −3.85 after about 0.885 of it); a miss is counted at the bottom. Balls spawn across the full width. |
| Ping Pong | Ball speed is 14 units per reach duration, so a leg between the paddles (13 units) takes 13/14 of it; returns use Unity's shallow launch angles. |
| Reef Runner, Character Flight | The gate spawns 16 units ahead and moves 14.82 units per reach duration, arriving after 16/14.82 (1.08) reach durations. Gates spawn across almost the whole vertical range (−2.5…5.5 of −3…6). |
| Diamond Catcher | 0.5 s appearance delay, then one reach duration, frozen while inside the target for the one-second hold. |
| Table Wiping | No time limit; the stain keeps Unity's size and proportions (about 575 × 258 px of the 1600 × 900 field) and the cloth is a real-world area (m²) scaled by the range. |

Fish Rescue, Bubble Sparkle and Fireworks were not in Unity's game list; they use the same reach duration with the allowances described above.

## In-game controls

- **Exit** (in the game bar next to Pause) saves the trial and returns to the movement screen. Holding the MARS button does the same.
- **Ctrl+G** opens the game-speed panel, as in Unity. Its − / + buttons (or the left/right arrow keys) change the reach speed in 0.005 m/s steps between 0.025 and 0.25 m/s; the panel shows the speed, the resulting target duration, and Unity's green-to-red speed bar. The change applies to the target in play and every later one, and is recorded in the trial's annotation column.
- Character Flight has three distinct worlds that rotate trial by trial: the village sunset, a mirrored cool morning with floating lanterns, and a monsoon day with rain. Each also rotates through day, evening and night.

## Guided reference videos

Every reference clip is re-encoded onto the same 640 x 480 (4:3) frame, so they all display at one size; square and portrait clips are centred on a blurred copy of themselves, never stretched or cropped. The ML, AP and MLAP clips (Choose movement, and the range assessment) carry an animated guide: a glowing line showing the path the hand should follow, a ring marker travelling along it in step with the clip, and a REC viewfinder frame with a playback bar. Each movement also has a one-line "how to move" description. The guide paths are defined in `core/video_guide.gd` (normalised to the video frame, traced from the wrist cuff in the Unity footage), so they can be refined without touching the videos. The setup clips (activating, attaching, strap removal) show the frame without a path.

## Glass UI and physical speed controls (current behaviour)
Ctrl+G opens the shared speed panel in every game: 0.025–0.250 m/s, in Unity's 0.005 m/s steps. Reach time is adjusted physical ROM / reach speed (ML horizontal, AP vertical, MLAP average of both). Manual changes preserve target progress, are annotated/logged, and use existing CSV columns. Device mode loads measured adjusted ROM; practice mode uses simulated ROM. Fish Rescue adds its configured dwell interval and Fireworks retains its minimum target window.

The forest artwork supplied by the user now backs the shared translucent UI with Atkinson Hyperlegible Next. Both fish games have a full-screen playfield and compact score/time/pause controls; Finish & save is available in Ctrl+G and via the MARS hold gesture. Ctrl+G also toggles the decorative shooting-star mouse trail. Lighting is fixed per game (day/evening/night), replacing the earlier within-trial lighting cycle; background motion continues. Fish Rescue's explicit lighting override is retained.

Validation: `tests/glass_speed_test.gd` covers all ten games, physical timing, speed limits/steps, fixed lighting, full-screen fish layouts and Ctrl+G. Integration and gameplay suites pass. Hardware calibration accuracy still requires device testing.

## Raspberry Pi, Linux and Bluetooth (rfcomm)

The robot connection is not limited to Windows COM ports. Godot cannot open serial devices itself, so MARS HOMER starts a small helper: `platform/serial_bridge.ps1` on Windows and `platform/serial_bridge.py` everywhere else (Python 3, standard library only). Both talk to the application over the same local, token-authenticated socket.

Port formats, typed into the **Serial port** field (the **Find** button in the setup screen lists what the system offers):

| Where | Port | Notes |
| --- | --- | --- |
| Windows | `COM3` | PowerShell bridge, as before |
| Raspberry Pi / Linux | `/dev/rfcomm0` | Bluetooth serial made with `sudo rfcomm bind 0 <robot address>` |
| Raspberry Pi / Linux | `/dev/ttyUSB0`, `/dev/ttyACM0`, `/dev/serial0` | USB or UART serial adapters |
| Raspberry Pi / Linux | `bt:AA:BB:CC:DD:EE:FF` (optional `:channel`, default 1) | Connects over Bluetooth RFCOMM directly: no `rfcomm bind`, no root |
| Anywhere | `tcp:host:port` | A serial-over-network server |

Typical Raspberry Pi setup:

1. Pair and trust the robot once: `bluetoothctl` then `pair <address>`, `trust <address>`.
2. Either enter `bt:<address>`, or run `sudo rfcomm bind 0 <address> 1` and use `/dev/rfcomm0`.
3. Add your user to the serial group (`sudo usermod -aG dialout $USER`, then log in again) so `/dev/rfcomm0` and USB ports can be opened.
4. Install Python 3 (`sudo apt install python3`) and start the app with `platform/run_pi.sh /path/to/godot`.

The serial settings are the same everywhere: 115200 baud, 8N1, DTR on, no flow control. The Pi path is covered by `tests/bridge_python_test.gd` (a fake robot behind `tcp:`); the Linux-only parts, serial devices and Bluetooth sockets, have not been exercised on real hardware. The Windows portable build is unchanged; on a Pi run the project from source with a Godot 4.6 arm64 binary, or export your own Linux build.

### Raspberry Pi Linux serial correction
The Pi package now includes the Python 3 serial bridge and Linux port selection (USB serial, RFCOMM and direct paired Bluetooth serial). The exported PCK includes the helper; no pyserial dependency is required. Windows retains its PowerShell bridge. Connection timeout messages are platform-specific. Bluetooth addresses require six octets and optional RFCOMM channel 1–30. Serial writes have a bounded timeout.

On the user's Pi 5, `serial_pty_test.py` passed all 256 byte values in both directions through a Linux pseudo-terminal, and the exported app's `bridge_python_test.gd` passed its authenticated fake-robot round trip with zero failures. These tests did not connect to or actuate physical hardware. Corrected installation: `/home/nd/MARS_HOMER_Linux`; launch `./start.sh` from that folder on the Pi desktop. Earlier practice-only restrictions in this document are superseded for connection support, but physical-device validation remains outstanding.

### Fireworks packaged-texture fix
Firework and lantern SVGs now load through Godot's imported Texture2D resources instead of reading source SVG text at runtime. This supports exported PCK remapping. Cracker targets are larger and Fireworks uses a dark sky for contrast. All seven sprite resources were verified inside the exported build on the Raspberry Pi with zero failures (`fireworks_assets_test.gd`).

### Training plane and metre/data audit
Movement selection now has a visible Training plane button. It opens an angle control (-100° to 0°, -90° horizontal). Practice saves directly; device mode requires an explicit Move action, then Save after the robot reports reaching the angle. Opening the screen never sends movement commands. Plane changes are blocked during trials and reload range/weight assessments within Unity's ±5° tolerance.
Assessment range labels now show metres with three decimals; the saved coordinates already used metres and are unchanged. `plane_data_test.gd` verifies plane persistence and filtering, 0.400 × 0.200 m assessment values, left/right target mapping, and saved plane/counts/physical duration for all ten games. Table Wiping preserves Unity's ReachSpeed=0 and scrub-area GameParameter convention. Integration (24 session columns, 36 raw columns), system (assessment/weight/telemetry persistence), and Unity timing tests pass. Physical calibration accuracy and actual robot plane movement still require supervised device verification.

### Shared game HUD
All ten games now use the reference-inspired glowing timer, score, per-game total-star counter, Pause/Play and Exit controls. In-game instruction banners and duplicate supplied-game headers are hidden. Total stars sums saved currentStar awards for this patient and game, never cumulative totals; current trial awards appear after saving and on the next entry. Exit retains the existing save-and-return behaviour; Ctrl+G still controls speed. HUD star accounting and all-game integration checks pass.

## Login, Ping Pong easy mode and target rings

- **Login:** a normal launch starts at a login screen where you enter the patient ID, or tap one of the patients already on this computer. A new ID creates a new patient, who must set up their plan (the Patient & plan form) and save it before the login completes. The patient field on the home screen is then locked to that patient; **Log out** returns to the login screen. Scripted test runs (`--script`) skip the login.
- **Ping Pong easy mode:** as in Unity's trajectory toggle, easy mode draws a dashed guide of where the incoming ball will reach the paddle line, including wall bounces, with a landing marker; the paddle is also larger and returns gentler. Toggle it inside the game with the chip under the game bar or the E key. The choice is remembered.
- **Target rings:** Diamond Catcher and Fish Rescue show one ring per target. While you are away from it, it shows the time left (it drains and turns amber near the end). While you rest on the target the same ring switches to a gold hold-progress arc.

- **Technical sections hidden:** normally only the patient plan is shown under Patient, setup & records, and Open saved data is hidden. **Ctrl+Shift+X** toggles Device & setup, Assessments, Diagnostics, Summary, Uploads & services and Open saved data.

- **Device diagnostics before login:** the login page has a "Device diagnostics" link. It connects to the robot (port field, Find, Connect, Sensor/Diagnostics stream) and shows what it reports, following Unity's diagnostics screen: firmware, device time, packet number, frame rate, status, error flags, calibration, command status, limb, control mode, robot and IMU angles, end-point position, force, target/desired/control and the controller terms. Nothing on that screen moves the robot.
- **Training side** in the patient plan is a Left / Right drop-down.

- **Connection capsule:** a small capsule at the very top-right of every screen, above everything else (including the game bar), shows a dot and the live data rate, for example "● 100 Hz". The dot is green while MARS streams, amber when connected without data, grey when not connected.
- **Prescription ring (bottom right of every game):** how much of today's prescribed training for the current movement is done, e.g. "Trial 3 / 10" with a ring filling to 25% and "2.5 / 10 min". Each trial is a 60-second round, so a 10-minute prescription is 10 trials; the ring fills smoothly while a trial runs. It is hidden for users without a prescription.

- **Target time ring:** Diamond Catcher and Fish Rescue share one glowing time ring that starts green, turns yellow and then orange-red (pulsing near the end) as the target time runs out, and becomes a gold hold arc while you rest on the target. The prescription counter at the bottom right is a small card.

- **Ending a session on a device:** after you remove your hand, pressing Lower the arm (or the MARS button) simply drops the Bluetooth connection at once, as Unity does. Nothing else is sent: no target angle and no control command.

- **Diagnostics controls and logging** (from Unity's diagnostics scene): choose the limb (No limb / Right / Left), **Calibrate** (needs a limb and IMU angles within ±50°; shows "Calibrated" afterwards), **Position control** on/off (available once calibrated) and a target slider from -120° to 0° with **Set target**. **Log data to file** records every packet to `MARS_Data_<timestamp>.csv` in one common `diagnostics` folder (user data), whichever patient is logged in. Buttons: Open folder, Open latest, Copy path, Copy data (file contents to the clipboard) and Save a copy.

- **Welcome dashboard:** the right-hand card shows today's progress as a large ring (minutes done of the prescription), a bar for each movement (a tick when complete), the day streak, minutes this week and stars today, and the last seven days as bars with the daily target marked (days that reach it turn green).

- **Welcome patient card:** an avatar with initials, the patient ID and whether they are logged in, today's time as a highlighted call-out with the prescription, small tiles for plan progress, training arm, plan end date and today's date, and a Mouse simulation / MARS device switch at the bottom. The ID box only appears when the patient can be changed (not when logged in).

- **Changing the training plane (Choose movement → Training plane):** on a device the robot is always commanded to the new angle first, even for a small change, and **Save plane** only appears once it has arrived (within 3°). Saving reloads the assessments that match the new plane (within 5°).
- **Plane saved indication:** saving the training plane shows a green tick that pops in with "Saved: -70°", a green "✓ Training plane saved" message with the number of matching assessments, and the same confirmation again as a notice when you return to Choose movement.
- **Range assessment cursor:** the cursor and recorded points are kept inside the frame; if the arm goes past the reachable area the marker stays on the edge and turns amber.
- **Range view auto-fit:** the assessment plot starts as Unity's workspace and smoothly widens if the arm reaches past it (on either side), so the whole measured range always fits on the screen; it resets on Start and Redo. Saved values are unchanged.
- **Assessment units:** the assessment screen shows positions and ranges in centimetres (for example "ML 40.0 cm • AP 20.0 cm"); saved files stay in metres.

- **Typeface, music and sound.** Atkinson Hyperlegible is the single typeface everywhere, including text drawn inside games (`gui/theme/custom_font`). Titan One (`assets/fonts/TitanOne-Regular.ttf`, OFL) is used only for game feedback such as "Caught!", "Missed", "Rescued!" and the Bubble Sparkle reward text. One looping background track (`assets/music/bgm.mp3`, autoload `Music`) is the only music in the software: it plays through every screen and game (Character Flight no longer has its own character music) at a clear level, slightly lower during games; Ctrl+M switches it off and on. `core/sfx.gd` synthesizes a different capture and miss sound for each game, with random pitch variants for captures; misses are deliberately soft.

- **Device & setup tab** now holds only the serial port and "Save port and test connection" (the port is stored in `user://application.cfg`); the Assessments and Summary tabs were removed (assessments run from Choose Movement, history from Summary on Welcome). When a patient starts training, setup connects automatically to the saved port. The login page has a clearly outlined **Diagnostics** button.

- **Data parity with Unity.** `tests/data_parity_test.gd` runs a simulated session and checks the saved files against Unity's own header definitions (read from `Assets/scripts` when present): `sessions.csv`, `trainingplane.csv`, `errorLog.csv`, `configdata.csv`, `raw-sessNN-trialNNN-GAME-MOVEMENT.csv`, assessment raw files, pre-header lines (`:Location`, `:Device`, `:User`), column counts and date formats. The "import a Unity user" button was removed from Patient & plan.

- **Plane changes reset assessments.** An assessment is valid only at the exact plane it was recorded at (`Records.PLANE_TOLERANCE` is 0.5°, just float round-off). Saving a different training plane makes every ML / AP / MLAP / arm-weight assessment invalid, training stays blocked until they are redone, and the "plane saved" notice says so. Saving the same plane again keeps them.

- **Automatic updates (Windows and Raspberry Pi).** `core/updater.gd` (autoload `Updater`) checks the latest GitHub release when the installed app starts, downloads the zip for this machine (`MARS_HOMER-windows-x86_64.zip` or `MARS_HOMER-linux-arm64.zip`), verifies its SHA-256 against the published `.sha256` file, unpacks it and hands over to `platform/apply_update.ps1` / `apply_update.sh`, which wait for the app to quit, copy the new files over the install folder (old ones kept in `.previous/`, restored if the copy fails) and restart the app. The login screen shows the progress and installs a ready update after a 20-second countdown unless "Later" is pressed; nothing installs during a trial. Source checkouts and the editor never update. Settings: `[updates] enabled / repo / token` in `application.cfg` (default repo `GokulrajE/MARS-HOMER`; a token is only needed for a private repository), plus a switch and "Check for updates now" in Patient & setup → Uploads & services.
- **Publishing a release.** Bump nothing by hand: push a tag such as `git tag v1.1.0 && git push origin v1.1.0`. `.github/workflows/release.yml` stamps the version, exports the pack, builds both zips with checksums and publishes them. The app compares the tag with `application/config/version` (currently 1.0.0).

- **Input mode switch.** "Mouse simulation / MARS device" moved from Welcome to the login page and is hidden until Ctrl+Shift+X; the last choice is remembered in `application.cfg` (`[ui] hardware`) and each mode keeps its own data folder.

- **Error panel (as in Unity's connectStatusHandler).** An error flag other than a lone NOHEARTBEAT (angle limit, jump, sensor mismatch...) or a lost link raises a full-screen "Device has issue. Call the engineers." / "MARS disconnected" panel naming the error. While it is up a tap does nothing; holding the MARS button (or Close) finishes and saves the trial and goes to the summary. It clears itself 1 s after the error is gone and is skipped on the Diagnostics screen and in simulation. See `core/error_panel.gd`.

- **Built-in NeuroDash client (replaces `C:\sender.py` and the local 127.0.0.1:5055 agent).** `core/neurodash.gd` (autoload `NeuroDash`) speaks sender.py's protocol natively, on threads: **fetch the patient list** (`--login`; the login page has a "Refresh patient list" button and fetches once at start when enabled; the list goes to `C:\NeuroDash\patients.json` where writable, else `~/NeuroDash/`; patients that are *active* and allowed on this device show as suggestions, and a new patient's training side defaults to the assigned side), **upload** `sessions.csv`, `configdata.csv` and finished assessments (`--upload`, after every trial), and the **one-laptop-per-patient lock** (claim at login, before the session opens (a patient held elsewhere cannot log in) = the agent's `/start`, a renewed claim at every trial start, heartbeat every 30 s, a renewed claim and upload after each trial = `/trial-ended`, release at log-out/finish = `/stop`; a refused patient shows "<id> is being trained on <device> (laptop …)"). It also listens for the server's UDP nudges (port 5001). Settings are in Patient & setup → Uploads & services (advanced): switch, server IP/port, device ID, laptop name. When the switch is on the old agent is not used. `tests/neurodash_test.gd` checks it all against `tests/fake_neurodash_server.py`.

- **Agent vs built-in client.** When "Use local session agent" is on, only the always-running agent (127.0.0.1:5055: `/start` at login, `/trial-ended` after each trial, `/stop` at log-out/exit) talks to the server about the patient lock and uploads; the built-in NeuroDash lock/upload client only works when the agent is off. The "Refresh patient list" button always fetches the list directly, as `sender.py --login` did.

- **Uploads, as in Unity.** After every device trial the app sends `sessions.csv`, `configdata.csv` and finished assessments to the NeuroDash server (Unity's `neurodash.OnSessionEnd()` = `sender.py --upload`), with or without the agent; the agent only tracks the patient lock (`/start`, `/trial-ended`, `/stop`). The Summary screen's **Upload data now** does two things: it sends those CSVs to the NeuroDash server right away, and it starts the installed MARS uploader (`uploadToAWSM.pyw`, Unity's DATAUPLOADING step) which uploads every file and folder of the patient. The LAN server only accepts `.csv` files (and only `sessions.csv` / `configdata.csv` are filed per patient), so raw data and the other folders go through the MARS uploader. Scripted test runs never reach the real agent, server or uploader.

- **Same laptop identity as the agent.** Uploads must carry the agent's own device and laptop names (read from its /status) or the server sees two laptops for one patient and refuses the lock ("session unavailable"). Without an agent the laptop name is the exact hostname (`hostname`, not the upper-case COMPUTERNAME). A "lost" flag no longer blocks games for good: starting a game re-checks with the server and only a real refusal blocks; a check in progress never blocks.

- **Device name.** Patient & setup > Uploads & services has a "Device name" (with quick picks MARS / NOARK / PLUTO / ATOBOT / MOBBO and "Automatic") and a laptop name: what this software tells the NeuroDash server. Empty means automatic (the running agent's names, else MARS and the hostname); a typed name wins and a warning shows when it differs from the agent's. The patient list is filtered by the same device name.

- **Server address.** Uploads & services has one "Server address" field (host or host:port, validated, saved as you type) and a **Test connection** button that opens and closes a plain TCP connection to prove the server is reachable without sending any request. Fetch / upload buttons and the login page's Refresh report the same address when it cannot be reached.

- **Full screen, any shape.** The app starts full screen (`display/window/size/mode=3`), F11 toggles a window on every screen and in every game (fish / fireworks no longer toggle on their own). The stretch aspect is "expand", so a 1920x1080 (16:9) laptop uses the whole screen with no bars: menus fill it, the 1600x900 games are scaled to fit it exactly, and the game HUD (Pause / Exit, trial ring) follows the right edge. 16:10 screens work as before.

- **Space Tour (ST, left-right movement).** The 3D "Cosmic Drift" game in `games/space-tour/` (original in `/SpaceTour`) runs as a normal trial: 60 seconds standard, ML, hits / misses / targets recorded like every game. The hand (robot ML position, or mouse / arrow keys in simulation) steers a shooting star along a winding route. One glowing light or ring at a time is the target (the next few wait ahead), spaced one reach apart: the forward speed is set so one spacing takes the current reach time (range / speed), so the speed panel (Ctrl+G) changes the pace live and the speed adapts between trials like the other games. Passing a light in line catches it (bell note, the light joins the ship, Titan One "Caught!"); passing it out of line is a "Missed". A new palette every trial; the scenery (planets, aurora, jellyfish, comets) is decorative. The volumetric fog is replaced by depth fog because the app uses the Compatibility renderer; the ambient pad was removed so the app theme stays the only music. No spoken intro clip exists for it yet (`assets/voice`). `tests/space_tour_test.gd` covers the rules.

- **Voice for every screen** (setup, calibration, attach / detach, errors, assessments, login, welcome, choose, plane, summary) in English and Tamil; see `VOICE_GUIDANCE.md`. **Fish Rescue** submarine now follows the hand closely instead of at a capped speed, so it no longer trails behind a quick movement.

- **Five combined-movement (MLAP) daily-life games** from `/MLAP_Games`, in `games/cooking` (CK, Vegetable Soup), `games/drawing` (DR, Colour the Picture), `games/ironing` (IR), `games/mopping` (MP) and `games/sorting` (SO, Tidy-up Sorting). They follow the same rules as the other games: a 60 s trial, MLAP, a target at a time (a vegetable into the pot, a soup stirred, a shape coloured, a garment ironed, a dust pile mopped, an item sorted; a wrong bin in Sorting is a miss), the app's HUD, Pause / Exit, MARS-button pause and finish, hold when MARS is not ready, saved sessions and raw files, voice introductions (EN/TA), game cards. They are patient-paced, so there is no speed control (`Rules.paced`). The hand is `core/game_pointer.gd` (`GamePointer`): the robot inside the patient's assessed range on the device, the mouse in simulation; selections are by holding still (dwell), because the MARS button is the app's pause / finish. Each runs at the screen size it was made for (`size` in `Rules.GAMES`) and sits below the HUD bar at its own proportions. Their own timers, score panels, pause buttons, quit / reload keys and the Mopping UDP listener are off; Vegetable Soup's `MarsInput` autoload now reads the app. Unused Tom & Jerry models were not copied. `tests/mlap_games_test.gd` covers them. Selections in these games need only a 0.3 s hold. Vegetable Soup's stirring ring runs well beyond the pot (`STIR_RADIUS` in `cooking_pot.gd`), so the stir uses most of the range. Mopping picks a different room every trial; under the Compatibility renderer its background, walls, slab and floors are darker, so no room glares white (`tests/render_rooms.gd`). `tests/weight_follow_test.gd` covers the MLAP → arm-weight step.
