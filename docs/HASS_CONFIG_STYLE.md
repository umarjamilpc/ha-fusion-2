# hass-config–style dashboard (matt8707)

This project can mirror the look and layout ideas from **[matt8707/hass-config](https://github.com/matt8707/hass-config)** (Lovelace + button-card + tablet theme).

## 1. Theme tokens

- Copy or merge **`static/themes/hass-tablet-fusion.yaml`** into your HA themes folder, then pick **hass-tablet-fusion** in **Appearance → Theme** (or merge its keys into your theme).
- In **Appearance → Card style**, choose **Tablet (hass-config)** for solid gray cards and section titles closer to that UI.

## 2. Sidebar “context hero”

Large clock, date, greeting, optional **weather** line, and a **natural-language summary** of which entities are on.

Add a sidebar item via **Edit → Sidebar → Add → Context hero**, or in `dashboard.yaml`:

```yaml
sidebar:
  - type: context_hero
    id: 1
    hour12: true
    weather_entity: weather.home
    summary_entities:
      - light.living_room
      - switch.tv
      - fan.bedroom
```

List entities you care about; the summary only mentions those that are currently “on” (uses the same on-states as the rest of the app).

## 3. Footer dock

Bottom bar with shortcuts (URLs, view switch, optional badge entity), similar to the hass-config footer.

```yaml
footer:
  items:
    - label: NAS
      icon: mdi:nas
      url: https://192.168.1.10:5000
    - label: History
      icon: mdi:history
      view: History   # matches view name (partial OK)
    - label: Updates
      icon: mdi:update
      badge_entity: sensor.hacs_update_count
```

- **`url`**: opened in a new tab.
- **`view`**: switches to the first view whose name contains the string (case-insensitive).
- **`badge_entity`**: shows a small red badge when state is non-zero / not `off` (handy for pending updates).

## 4. Assets

The reference repo’s **`www/`** images are optional; this repo ships **`hass-tablet-fusion.yaml`** as a self-contained theme preset. You may copy **`background.png`** or other assets from hass-config’s `www/` for your own wallpaper (MIT license — keep attribution as in the original repo).
