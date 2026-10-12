# Title-screen artwork

Supplied by Lauren Nguyen on [OUUT-1](https://untoldtales.atlassian.net/browse/OUUT-1), attachment `titlecard.zip` (10001). These JPEG files preserve the supplied exports; the composed reference is attachment `titlecard.png` (10000).

| Repository export | Original ZIP filename |
| --- | --- |
| `ui_title_logo.jpg` | `Asset 1-100.jpg` |
| `ui_start_game.jpg` | `Asset 2-100.jpg` |
| `ui_settings.jpg` | `Asset 3-100.jpg` |
| `ui_quit.jpg` | `Asset 4-100.jpg` |
| `ui_selection_ornament.jpg` | `Asset 5-100.jpg` |
| `ui_title_frame.jpg` | `Asset 7-100.jpg` |
| `bg_title_screen.jpg` | `Asset 9-100.jpg` |

The scene uses an AtlasTexture region of the background (7, 69, 1152, 648) to exclude the white export margin. The other exports have a white matte because JPEG has no alpha channel; `white_matte.gdshader` removes it at draw time. Transparent PNG exports could replace those textures later. Editable originals belong in the team's shared storage outside this repository.
