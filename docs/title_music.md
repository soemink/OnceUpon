# Title music (OUUT-7)

The title screen plays the recording attached to [OUUT-7](https://untoldtales.atlassian.net/browse/OUUT-7), `once_upon_menu_redo_3.91_ocarina_E3.mp3`, exported as `assets/audio/music/once_upon_menu_redo_3_91_ocarina_e3.ogg`.

The export uses Vorbis quality 6, preserving the full recording, stereo channels, and 44.1 kHz sample rate. No trimming, fades, normalization, or gain filters were applied. The source MP3 remains in Jira; editable originals belong in shared team storage.

Music starts when the title screen is ready, after Settings loads the saved Master volume. It repeats the entire recording from the beginning, including its existing tail, and continues uninterrupted while Settings or the temporary Start Game notice is open. Master volume controls it, including mute at zero. Leaving the title scene ends playback; a future intro should replace the title scene when gameplay starts.

The existing title-screen automated check covers startup, saved volume, mute, overlay continuity, the recording's loop boundary, and scene removal. Run the shared check described in [setup](setup.md). For an audible check, launch the game, open and close both overlays, adjust volume, and listen through the roughly one-minute repeat. Web playback and export require separate browser verification when export presets are available.
