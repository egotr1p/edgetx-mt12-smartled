# Radiomaster MT12 RGB LED Control Script

This Lua script is designed to control the **RGB LEDs** on the **Radiomaster MT12** transmitter using logical segment mapping and global variables. 
It provides customizable visual feedback for battery status, signal quality, drive modes, and more.
More functions can be added if needed.

---

## 🔌 Segment Layout

The LED strip is divided into **logical segments**:

| Segment    | LEDs | Example Usage                 | Controlled by |
|------------|------|-------------------------------|---------------|
| **Top**    | 1    | RSSI, signal quality          | `GV1`         |
| **Grip**   | 2    | Battery status (warning/crit) | `GV2`         |
| **Bottom** | 4    | Drive modes, model ID, etc.   | `GV3`         |

---

## ⚙️ Setup in EdgeTX

1. **Install the Script:**
   - Place the script in your radio SD card:  
     `/SCRIPTS/RGBLED/smartLED.lua`

2. **Enable SmartLED Output:**
   - Add a **Gobal Function**:
     ```
     | ON | RGB leds | SmartLED | ON | ON
     ```
   - This turns on SmartLED support at boot.

3. **Control Segments with GVs: added in special functions**
   - `GV1` = Top
   - `GV2` = Grip (with effect support)
   - `GV3` = Bottom

4. **Use Logical Switches to control the special functions.**
   - Set conditions based on telemetry (voltage, RSSI, switches)
   - Map these to set `GVx` values dynamically

---

## 🔋 Battery Status Effects (Grip Segment / GV2)

| GV2 | Status      | Effect     | Color     |
|-----|-------------|------------|-----------|
| 0   | Off         | None       | Off       |
| 1   | Good        | Static     | Green     |
| 2   | Storage     | Static     | Yellow    |
| 3   | Moderate    | Static     | Orange    |
| 4   | Warning     | Breathing  | Red       |
| 5   | Critical    | Flashing   | Red       |

---

## 🎨 Custom Colors

Edit the `COLORS` table in the script to add or change available colors. Each entry is a `{r, g, b}` object.
Do not remove or edit the 6 first colors, since these are used for Grip battery control

To use a color:
- Reference it by index in the corresponding `GV` (0-based).

---

## ⚙️ Adjustable Effects

Inside the script:

-- === Adjustable animation settings ===
local BREATH_CYCLE_MS = 2000      -- Breathing cycle duration (ms)
local FLASH_INTERVAL_MS = 150     -- Flashing interval (ms)

local INTENSITY_MIN = 30          -- Breathing min intensity (0–100)
local INTENSITY_MAX = 100         -- Breathing max intensity (0–100)
# edgetx-mt12-smartled
