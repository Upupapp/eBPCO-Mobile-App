# Launcher icon sources

The app's icon is the **Municipality of Teresa, Rizal official seal**. It is generated, never
hand-edited.

```sh
dart run flutter_launcher_icons        # from Teresa-Mobile-App/
```

Config lives in `pubspec.yaml` under `flutter_launcher_icons:`. That one command regenerates
Android (legacy + adaptive), iOS and web icons on either lane.

## The two source images

Both are composed from `assets/images/Logo/teresa-rizal-seal.png` — the municipality's own seal,
already in the repo as a runtime asset. They are **build-time sources only** and are deliberately
not declared in `pubspec.yaml`'s `assets:`, so they do not ship inside the app.

| File | Canvas | Seal size | Background |
|---|---|---|---|
| `teresa_rizal_icon.png` | 1024×1024 | 84 % | opaque white |
| `teresa_rizal_icon_foreground.png` | 1024×1024 | 84 % | transparent |

### Why white, not the app's navy

The seal is drawn for a light ground: a black outer ring around a yellow band. On `#0B1730`
navy the black ring disappears into the background. White keeps the mark exactly as the
municipality drew it.

### Why 84 % for the adaptive foreground

`flutter_launcher_icons` wraps the foreground in `android:inset="16%"`, so the drawable is
painted at 68 % of the 108 dp adaptive layer. Android's mask shows at most the central 72 dp
(66.7 %) and only *guarantees* the inner 66 dp (61 %).

At 84 % of this canvas the seal lands at roughly 57 % of the finished icon — comfortably inside
even a circular mask, with a small margin, and large enough to read at launcher size. Values
around 60 % here were tried first and rendered the seal at only ~41 %: correct, but lost in a
sea of white.

The seal being circular is what makes this easy — a circular mark and a circular mask lose
nothing to each other.

## Regenerating the sources

Only needed if the seal artwork itself changes. The composition is a crop to the seal's own
alpha bounding box (the source has ~30 px of transparent margin, which would otherwise skew
every size calculation), then a centred paste at the fraction above.

## Guardrails

- `test/launcher_icon_test.dart` fails if any density reverts to Flutter's template art, if the
  adaptive icon or the Android 12+ splash config goes missing, or if an iOS icon gains an alpha
  channel — the App Store rejects those.
- `android/app/src/main/res/values-v31/styles.xml` points the Android 12+ splash at the full
  adaptive icon. Without it the platform draws the foreground alone on the window background and
  the seal loses its white plate.
- Do **not** hand-edit anything under `mipmap-*`, `drawable-*`, `AppIcon.appiconset` or
  `web/icons` — the generator overwrites all of it.
