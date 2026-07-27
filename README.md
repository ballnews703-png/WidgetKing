# WidgetKing 👑

Design your own iPhone Home Screen widgets in seconds — no code, no fuss.

There are **two ways to use WidgetKing**:

| | Requirements | Cost |
| --- | --- | --- |
| **🌐 Web designer + Scriptable** (recommended if you don't have a Mac) | Any browser + the free [Scriptable](https://apps.apple.com/app/scriptable/id1405459188) app | **$0** |
| **📱 Native SwiftUI app** | A Mac with Xcode 15+ | $0 to build; free Apple ID installs expire after 7 days ($99/yr developer account removes that) |

## 🌐 No Mac? Use the web designer (100% free, no AI needed)

Everything runs locally — no server, no accounts, no API keys, nothing uploaded.

1. Open `web/index.html` in any browser (double-click it — it works offline).
   You can do this on a Windows PC, a borrowed laptop, or host it anywhere.
2. Design widgets: use the **Magic box** (type an idea in plain English — a
   built-in parser handles it, no AI required), the regular editor, or the
   **Freestyle drag-and-drop canvas**. Designs save in your browser.
3. Tap **Copy Scriptable Script** (or Download it and send it to your phone
   however you like — Notes, email, messages).
4. On your iPhone: install the free **Scriptable** app, create a new script,
   paste, and name it `WidgetKing`.
5. Add a **Scriptable widget** to your Home Screen, long-press it → Edit
   Widget → choose the `WidgetKing` script, and set **Parameter** to a
   design's name. Add more widgets with different parameters — designs are
   fully interchangeable.

That gets you real Home Screen widgets with no Mac, no developer account, and
no ongoing costs. (One honest limitation: iOS refreshes Scriptable widgets on
its own schedule — every few minutes — so clock widgets aren't to-the-second
the way the native app's are.) A reference copy of the renderer lives at
`scriptable/WidgetKing.js`.

## 📱 The native app

Built with SwiftUI + WidgetKit for iOS 17 and later (great on iPhone 17 Pro).

## What it does

- **✨ Magic tab — type an idea, get a widget.** Describe what you want in
  plain English ("countdown to my birthday on October 12, sunset colors") and
  it's auto-built. With a Claude API key set in Settings, Claude designs the
  widget; without one, a fast on-device parser handles it, so the feature
  always works.
- **🖐️ Freestyle drag-and-drop canvas.** Pick the Freestyle type and drop
  clocks, dates, text, emoji, and symbols anywhere on the widget — drag to
  position, tap to resize/recolor. What you build is exactly what renders on
  the Home Screen.
- **Create widgets in the app** — pick a widget type, then customize it with a
  live preview that matches exactly what will appear on your Home Screen:
  - 🕐 **Clock** — time plus the date
  - 📅 **Date** — big day-of-month with weekday and month
  - ⏳ **Countdown** — days until (or since) any event
  - 💬 **Quote** — a quote with an optional author
  - 📝 **Note** — any short text, front and center
  - 🎨 **Freestyle** — the drag-and-drop canvas
- **12 gradient themes**, 4 font styles (Classic / Rounded / Serif / Mono), and
  a free-form text color picker.
- **Small, Medium, and Large** widget sizes, previewable in the editor.
- **Interchangeable everywhere.** Make as many designs as you like; on the
  Home Screen, long-press the widget → **Edit Widget** to swap which design it
  shows. Long-press a design in My Widgets to **share it as a .widgetking
  file**, and import designs from friends via the import button.

## Project layout

| Path | What it is |
| --- | --- |
| `WidgetKing/` | The iOS app (design list + editor) |
| `WidgetKingWidgets/` | The WidgetKit extension that renders widgets |
| `Shared/` | Model, storage, and rendering code compiled into both targets |

Designs are stored as JSON in an App Group (`group.com.widgetking.shared`) so
the app and the widget extension share them. The widget uses an
`AppIntentConfiguration`, so each placed widget can be pointed at a different
saved design.

The Magic tab's AI mode calls the Anthropic Messages API directly from the
device (`claude-opus-5`, with structured outputs so the reply is guaranteed
valid JSON). The API key is optional, entered in Settings, and stored only on
the device.

## Getting it running

You'll need a Mac with **Xcode 15 or newer**.

1. Open `WidgetKing.xcodeproj`.
2. Select the **WidgetKing** target → *Signing & Capabilities* → choose your
   **Team**. Do the same for the **WidgetKingWidgetsExtension** target.
3. If Xcode complains about the bundle identifier or App Group being taken,
   change them to your own (e.g. `com.yourname.widgetking` and
   `group.com.yourname.widgetking`). If you change the App Group, update it in
   **three** places: both `.entitlements` files and `AppGroup.id` in
   `Shared/DesignStore.swift`.
4. Pick your iPhone (or a simulator) as the run destination and hit **Run**.

## Using it on your phone

1. Open WidgetKing and tap **+** to create a design. Save it.
2. Touch and hold your Home Screen → **Edit** → **Add Widget**.
3. Search for **WidgetKing**, pick a size, and add it.
4. Touch and hold the widget → **Edit Widget** → choose which design to show.

Any edits you make in the app update your Home Screen widgets automatically.
