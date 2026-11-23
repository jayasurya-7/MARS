# Voice guidance

Select **English** or **Tamil** beside **Voice guidance** on the home or movement-selection screen. **Listen** previews the selected voice; uncheck Voice guidance to mute speech. Language and enabled state are remembered on this device. Screen text is unchanged.

All ten games have spoken starting instructions. Successes receive occasional varied encouragement, and inactive patients receive a gentle movement-specific reminder. Reminders require at least eight seconds without a movement of two millimetres, plus a fourteen-second quiet interval after speech; encouragement requires ten quiet seconds. These thresholds reduce repetitive prompts. Intentional holds, aiming to shoot, waiting for a correctly aligned ball, pauses, and device holds suppress movement reminders. Speech stops when a trial is paused or exited. A completed round has a short rest prompt. Background music lowers during speech.

The 36 English/Tamil MP3 clips are bundled and play offline on Windows and Raspberry Pi; no operating-system speech voice is required. The build-time generator uses gTTS with only the generic text in `assets/voice/phrases.json`. No patient data is sent for speech generation or playback. Clips can be replaced with reviewed human recordings using the same filenames.

Validation: all clips load and have playable duration; game introduction, language routing, no overlap, hold suppression, inactivity reset, reminder spacing, encouragement, pause, and mute are covered by `tests/voice_guidance_test.gd`. The home and movement-selection layouts were rendered and inspected. Robot hardware and Pi audio output were not tested in this update.

## Spoken prompts for every screen (short sentences)

Besides the game introductions, every screen now speaks one short sentence when it opens or when its step changes (English and Tamil, 50 clips each):

- **Setup:** connect, calibrate, "angles are out of range, straighten the arm", activate, "MARS is moving", attach the hand, hand attached, set the plane, ready.
- **Detaching:** remove your hand, press the button to lower the arm, arm lowered.
- **Problems:** "Device issue. Please call the engineers." for any device error, "Arm out of range. Move it back inside." for an angle limit, "MARS disconnected. Check the connection." when the link drops. They repeat every 20 s while the error panel is up.
- **Assessments:** start, the movement to make (left-right, forward-back, all around, or the arm-weight targets), check the range and save, saved.
- **Other screens:** login, new patient plan, welcome, choose a movement / game, assessment needed, training plane, summary.

A prompt is said once per step; a step that waits on the patient (for example attaching the hand or an angle problem) is repeated every 10 s, others every 25 s. A new prompt replaces the one before. The game introductions, reminders and encouragement were shortened too. The Tamil text was written for this update and should be reviewed by a Tamil speaker before clinical use. The Diagnostics screen (engineers' tool) and the tutorial pages are silent. All clips come from `assets/voice/phrases.json` (`platform/generate_voice.py`).

