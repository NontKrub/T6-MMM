# MMM branding assets

The supplied MMM brand sheet is now the approved visual source for this
implementation. The transparent PNGs in this directory are raster crops of
that sheet, preserving the supplied ribbon geometry and light/dark variants.

- `mmm_mark.png` / `mmm_mark_dark.png`: ribbon-only mark.
- `mmm_wordmark.png` / `mmm_wordmark_dark.png`: mark plus wordmark, without the
  localized tagline.
- `app_icon_source.png` / `app_icon_source_dark.png`: square light/dark
  app-icon sources using the supplied monogram.

Native launcher slots use the light source by default and the dark source for
the platform's dark appearance (`luminosity` on iOS and `mipmap-night-*` on
Android).

Replace these raster files with the original transparent/vector exports when
they become available; keep the same filenames so the Flutter and native
surfaces do not need another code change. Do not trace or redraw the mark.
