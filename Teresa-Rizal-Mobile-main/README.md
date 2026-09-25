# Teresa, Rizal Mobile

Flutter citizen app for the **Municipality of Teresa, Rizal**: Dokyu, Tulong, Sakuna, Balita, events, a digital ID wallet, and the resident profile.

Inside screens use the soft-widget shell: five equal tabs (Home, Balita, Events, Services, Profile), a floating pill, and modular cards. Dokyu, Tulong, and Emergency open from Services. Welcome photographs are unchanged.

## Run it

The Flutter project is `Teresa-Mobile-App/`.

```sh
cd Teresa-Mobile-App
flutter pub get
flutter analyze
flutter test
flutter run -d <device>
```

The lockfile matches Flutter 3.47 / Dart 3.13. Use that SDK so `flutter pub get` does not rewrite `pubspec.lock`.

Launcher name: **Teresa, Rizal**. Longer product name: **Teresa, Rizal Mobile**.

## Screens-only stubs

There is no live backend. Sign-in, requests, notifications, and the resident profile stay on device in `shared_preferences`.

| Area | Behavior |
|---|---|
| Payments (GCash, Maya, onsite) | A choice on the existing form. No payment provider is called. |
| Push | Local demo notifications only. No Firebase project, FCM, or APNs. |
| Directions | In-app address preview. No maps SDK. |
| Social share | Facebook, Messenger, X, Viber, and WhatsApp open an in-app preview and do not post. Copy uses the clipboard. More uses the device share sheet. |
| Call | Still hands the number to the device dialer. |

No Firebase project id, API key, or backend resource id was added.

## Inside shell

Post-auth chrome follows the soft-widget tokens (Inter 400/500/600, header wash, pill nav, about 22px cards). The aperture moves in 600ms ease-out and the page wipe is 600ms ease-in. Banner slots are dashed placeholders. Access tiers are unchanged: Emergency needs a signed-in account, Dokyu and Tulong need a verified account.

## Out of scope for this PR

- Welcome art. These files are the seeded photographs, unchanged:

  - `Teresa-Mobile-App/assets/images/welcome/page_1_bg.jpg`
  - `Teresa-Mobile-App/assets/images/welcome/page_2_bg.jpg`
  - `Teresa-Mobile-App/assets/images/welcome/page_3_bg.jpg`

  Replacing them is owned separately and is not done here.

Event posters, tab banners, and the home banner that named the previous municipality are not bundled. Those slots are dashed 16:9 placeholders until Teresa, Rizal art exists. The Home brand row uses the official seal file.

## Intentional leftover

Seeded from [https://github.com/Upupapp/Esperanza-Mobile](https://github.com/Upupapp/Esperanza-Mobile). That URL is the only kept use of the seed name. Named resident scans from that repo were not copied. Blank templates are under `Teresa-Mobile-App/Reference_forms/Placeholders/`.
