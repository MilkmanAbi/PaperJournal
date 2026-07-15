# Amber-Paper
### A rough PaperDesign adaptation for AmberJournal.

Version 0.1 — Student project spec · extends `PaperDesign.md`

---

## 0. What this document is

This is not a full second design system — it's a **short, practical extension** of `PaperDesign.md`, the way `Sora-Paper.md` extends it for a browser. Everything in the base spec (the 8px grid, two-radius rule, motion durations, the color *method*) still applies. This doc only covers what's specific to AmberJournal: the amber palette, the wave-art moments, the cosmos error state, and the handful of booking-app components (calendar, time slots, confirmation).

You're a student shipping a course project, not a design team shipping v1 of a product — so treat this as a checklist and a palette, not a rulebook to memorize. When in doubt, default back to whatever `PaperDesign.md` says.

### 0.1 The one-line pitch

A booking app that feels like closing your journal after a long rest — warm, unhurried, low-stakes. Amber light, quiet paper, nothing shouting at you to hurry up and pick a time slot.

---

## 1. Color

### 1.1 Neutrals — warm amber undertone

One undertone (~35–38° hue, warm amber-cream), four steps, same method as the base spec §6.2.

**Light mode**

| Token | Hex | Role |
|---|---|---|
| `surface-canvas` | `#F3F0EB` | full-bleed background |
| `surface-raised` | `#FBFBFA` | cards, panels |
| `surface-sunken` | `#E9E2D7` | inputs, wells |
| `ink-primary` | `#302317` | headings, primary text |
| `ink-secondary` | `#7A6651` | body text, labels |
| `ink-tertiary` | `#A99E92` | placeholders, dividers, disabled |

**Dark mode** (used for the cosmos/error moment, and optionally as a full theme later)

| Token | Hex | Role |
|---|---|---|
| `surface-canvas` | `#1B1611` | full-bleed background |
| `surface-raised` | `#27211B` | cards, panels |
| `surface-sunken` | `#130F0B` | inputs, wells |
| `ink-primary` | `#F1ECE3` | headings, primary text |
| `ink-secondary` | `#C5BBA9` | body text, labels |
| `ink-tertiary` | `#897E6B` | placeholders, dividers, disabled |

### 1.2 Accent — amber

| Token | Hex | Role |
|---|---|---|
| `accent-primary` (light) | `#BF9458` | buttons, links, active states |
| `accent-primary` (dark) | `#CEA66D` | same, bumped for dark-bg contrast |
| `ink-on-accent` | `#FBFBFA` (light) / `#1B1611` (dark) | text/icons sitting on filled amber |

One accent, one job: "this is the thing to press." Don't let a second saturated color compete with it on any single screen (base spec §6.4).

### 1.3 Companions — duller than the accent, for tags/status/calendar categories

Same saturation/lightness ceiling as the accent (~28% sat, ~55% light), hue rotated. Useful for booking categories, slot status, and confirmation/error semantics:

| Name | Hex | Suggested use |
|---|---|---|
| dusty-blue | `#6C8CAC` | ties directly to the Lile wave art — good for "info" or a category tag |
| sage | `#6CAC81` | confirmed / success (a booking went through) |
| dusty-plum | `#966CAC` | a second category tag if you need one |
| terracotta | `#AC7F6C` | pending / awaiting confirmation |
| brick | `#AC746C` | cancelled / error — muted, not stoplight-red |

Don't reach for a 6th companion. If you need more categories than this, group them instead of inventing more hues.

---

## 2. Shape

Stick to base PaperDesign, don't do Sora's 8px softening — a booking app calls for the calmer, boxier read, not a "handled all day" browser feel.

- `radius-sm` = **4px** — cards, inputs, buttons, the booking-confirmation card.
- `radius-pill` = fully rounded — search bar, date-picker pill toggle, time-slot chips (these genuinely benefit from pill shape since they're small, tappable, horizontal).
- No third radius. No giant rounded hero cards.

---

## 3. Typography

Follow the base spec's "contrasting but cohesive pairing" recommendation (§7.1) — it fits the journal mood well.

- **Headline serif**: something warm and a little literary — *Lora*, *Fraunces* (light weight), or *Source Serif 4*. Used for `type-display` through `type-h3` only (page titles, section headers, the confirmation screen's "You're booked" moment).
- **Body/UI sans**: *Inter* or *Public Sans*, Regular 400 + Semibold 600. Used for everything else — buttons, form labels, list rows, calendar grid, nav.
- Don't add a third voice unless you genuinely need monospace for something like a booking reference code — if you do, system mono is fine, used only for that.

Hold the base spec's scale exactly (14px base, 1.2 ratio, `type-h1` = 24px ceiling). Don't let the serif's warmth tempt you into a 40px hero — restraint is still the rule, just with a warmer typeface riding on it.

---

## 4. Where the wave art and cosmos art actually go

This is the part worth being disciplined about — per base spec principle 8, personality gets spent on a *few* moments, not smeared across every screen.

### 4.1 Lile-00 / Lile-03 (the wave gradients)

Use these as **full-bleed backdrops on exactly two or three screens**: the splash/launch screen, the login/sign-up screen, and optionally the onboarding carousel. Nowhere else.

- These are **content-side, not chrome** in the PaperDesign sense (base spec §4.1) — they're a backdrop, not a surface you place UI tokens on top of carelessly. Any button/text sitting on top of the wave art still needs to read clearly, so:
  - Use a translucent `surface-raised` panel (light, ~90% opacity) behind the login form itself, rather than placing form fields directly on the gradient.
  - Keep button/link colors as your normal `accent-primary` amber — the cool blue/purple of the waves and the warm amber accent contrast nicely and won't fight, since they're doing different jobs (backdrop vs. actionable element).
- Don't tile or reuse the wave art behind ordinary list/booking screens — that's exactly the "decorative gradient" anti-pattern the base spec warns against (§9, §15). It's a splash/login moment, not a wallpaper for the whole app.

### 4.2 Lonely-Cosmos (the error/empty-state illustration)

This is your **one deliberate dark moment** in an otherwise light, amber app — same idea as the base spec's illustration carve-out (§9.1): illustration is allowed to introduce a second hue (here, dark navy) specifically for empty/error states, without it leaking into the rest of the system.

- Use it for: no-network errors, 404/undefined-route screens, "no bookings yet" empty states, form-submission failures.
- When it appears, the **whole screen** switches to the dark-mode tokens from §1.1 for that moment (navy canvas, cream ink) rather than dropping a dark illustration onto a light background — it should read as a deliberate pause, not a visual glitch.
- Keep the accompanying copy short and calm, per the base spec's voice rules (§14): state the problem, maybe one dry line of personality. *"Nothing here yet. The stars are still deciding."* is more on-brand than *"Error 404: Not Found."*
- This illustration does not get reused as a loading spinner or a decorative header — it's reserved for the specific moment of "something's empty or broken," so it keeps its weight.

---

## 5. Booking-specific components

A few components a generic PaperDesign doc won't cover, since they're specific to this app type.

### 5.1 Calendar / date picker
- Grid-aligned per the base 8px unit — each date cell is a square, `radius-sm`, not a circle (save circles for the *selected* state only).
- Selected date: `accent-primary` fill, `ink-on-accent` text, still `radius-sm` — don't switch to a circle just because most calendar UIs do; a filled square that matches the rest of the app's shape language reads more intentional.
- Dates with existing bookings get a small `dusty-blue` dot beneath the number — categorization, not a competing accent (same logic as Sora's workspace-color exemption, base spec §6.3 vs Sora §5.3).

### 5.2 Time-slot chips
- Pill-radius, per §2 — these are functionally bars, small and horizontal.
- Available: `surface-sunken` fill, `ink-primary` text, hairline `ink-tertiary` border.
- Selected: `accent-primary` fill, `ink-on-accent` text.
- Unavailable: `surface-sunken` fill at reduced opacity, `ink-tertiary` text, no border — don't strike it through, just mute it.

### 5.3 Booking confirmation card
- `surface-raised`, `radius-sm`, `elevation-1` — a normal PaperDesign card, no special treatment.
- This is a good spot for the one moment of serif headline warmth ("You're all set") plus a `sage` companion-colored status pill ("Confirmed") — but only one accent-weight element on the card; don't let the sage pill and the amber button both compete for attention.

### 5.4 Empty / error state
- See §4.2 — full Lonely-Cosmos treatment, dark tokens, short calm copy, one action button in `accent-primary` amber (even against the dark backdrop) so there's always a clear way back to safety.

---

## 6. Anti-patterns specific to Amber-Paper

- ❌ Wave-art backdrop behind ordinary screens (booking list, settings, calendar) — it's a splash/login moment only (§4.1).
- ❌ Cosmos illustration used decoratively (as a loading spinner, a header image) instead of reserved for actual empty/error states (§4.2).
- ❌ A second saturated accent competing with amber on the same screen — companions (§1.3) exist so you don't need one.
- ❌ Circular calendar cells "because that's what calendars usually look like" — stay square/`radius-sm` per the shape language.
- ❌ Struck-through text for unavailable time slots — mute the fill/text instead (§5.2).
- ❌ Panicking about getting this pixel-perfect. It's a course project — get the palette and the two radius rules right and consistent, and it'll already look more considered than most default Flutter Material apps.

---

## 7. Quick reference

```
UNDERTONE      warm amber/cream, ~35-38°
ACCENT         #BF9458 (light) / #CEA66D (dark) — one per screen
COMPANIONS     dusty-blue #6C8CAC · sage #6CAC81 · dusty-plum #966CAC
               · terracotta #AC7F6C · brick #AC746C
RADIUS         4px boxes · pill bars/chips — no third size
TYPE           serif headline (Lora/Fraunces) + sans UI (Inter/Public Sans)
               14px base, 1.2 ratio, 24px h1 ceiling
WAVE ART       splash + login only, panel behind form content, never tiled elsewhere
COSMOS ART     empty/error states only, switches whole screen to dark tokens
CALENDAR       square cells, radius-sm, amber fill when selected, blue dot = has booking
TIME SLOTS     pill chips, amber fill = selected, muted fill = unavailable
```

---

*Amber-Paper is a rough guide, not gospel — the point is consistency across the handful of screens you actually build, not exhaustive coverage. Update this file as you go if a rule turns out not to fit.*
