local LED_STRIP_LENGTH = 7
local math = math

-- === Color palette GV1/GV3===
local COLORS = {
    --  RED      GREEN    BLUE      LUAINDEX GV#  COLOR
    { r = 0,   g = 0,   b = 0   },  --  1    0   OFF
    { r = 0,   g = 255, b = 0   },  --  2    1   GREEN
    { r = 255, g = 255, b = 0   },  --  3    2   YELLOW
    { r = 255, g = 100, b = 0   },  --  4    3   ORANGE
    { r = 255, g = 0,   b = 0   },  --  5    4   RED 
    { r = 189, g = 0,   b = 66  },  --  6    5   HOTPINK
    { r = 255, g = 0,   b = 255 },  --  7    6   MAGENTA
    { r = 153, g = 255, b = 255 },  --  8    7   ICEBLUE
    { r = 0,   g = 255, b = 255 },  --  9    8   CYAN
    { r = 0,   g = 128, b = 128 },  -- 10    9   TEAL
    { r = 0,   g = 0,   b = 255 },  -- 11   10   BLUE
    { r = 128, g = 0,   b = 255 },  -- 12   11   PURPLE
    { r = 128, g = 255, b = 0   },  -- 13   12   LIME
    { r = 255, g = 215, b = 0   },  -- 14   13   GOLD
    { r = 255, g = 255, b = 255 },  -- 15   14   WHITE
    { r = 128, g = 128, b = 128 },  -- 16   15   GRAY   
}

local COLORNR = #COLORS

--  Li-Ion Voltage Severity Chart
--  GV2	Voltage Range	Status	            Effect 	    Color
--  0	          off	Disabled            OFF	        OFF
--  1	< 8.4 - > 7.5 	Good / Discharging	Static	    GREEN
--  2	< 7.6 - > 7.2	Storage voltage	    Static	    YELLOW
--  3	< 7.3 - > 7.1	Moderate / Used	    Static	    ORANGE
--  4	< 7.2 - > 6.6 	Warning	            Breathing	RED
--  5	< 6.7	        Critical	        Flashing    RED

-- === Adjustable animation settings ===
local BREATH_CYCLE_MS   = 2000  -- Duration of one full breath (in ms)
local FLASH_INTERVAL_MS = 150   -- Flash interval (in ms)
local INTENSITY_MIN     = 10  -- Minimum intensity
local INTENSITY_MAX     = 100  -- Maximum intensity

-- === Segment sizes ===
local Top_Size    = 1
local Grip_Size   = 2
local Base_L_Size = 2
local Base_R_Size = 2

-- === Segment start indices ===
local Top_Start    = 0
local Grip_Start   = Top_Start + Top_Size
local Base_L_Start = Grip_Start + Grip_Size
local Base_R_Start = Base_L_Start + Base_L_Size

-- === Effect state ===
local flashTimer   = 0
local flashState   = false

-- === Magic Maths ===
local BREATH_INTENSITY_MIN = INTENSITY_MIN / 100
local BREATH_INTENSITY_MAX = INTENSITY_MAX / 100

-- === Helpers ===
local function scaleColor(color, factor)
    return {
        r = math.floor(color.r * factor),
        g = math.floor(color.g * factor),
        b = math.floor(color.b * factor)
    }
end

local function setSegmentColor(startIdx, size, color)
    for i = 0, size - 1 do
        local ledIndex = startIdx + i
        if ledIndex < LED_STRIP_LENGTH then
            setRGBLedColor(ledIndex, color.r, color.g, color.b)
        end
    end
end

-- === Ensure valid Global Variable and within Palette ===
local function getColorFromGV(gv)
    if type(gv) == "number" and gv >= 0 and gv < COLORNR then
        return COLORS[gv + 1]
    else
        return COLORS[1] -- OFF
    end
end

local function init()
end

local function run()
    local now = getTime()

    -- === Get GVs ===
    local gv_top    = model.getGlobalVariable(0, 0)  -- GV1 → Top
    local gv_grip   = model.getGlobalVariable(1, 0)  -- GV2 → Grip (with effects)
    local gv_bottom = model.getGlobalVariable(2, 0)  -- GV3 → Bottom

    -- === Top Segment ===
    local topColor    = getColorFromGV(gv_top)
    --local topColor = COLORS[math.min(gv_top + 1, COLORNR)] or COLORS[1]

    -- === Bottom Segment ===
    local bottomColor = getColorFromGV(gv_bottom)
    --local bottomColor = COLORS[math.min(gv_bottom + 1, COLORNR)] or COLORS[1]

    -- === Grip Segment (Severity logic) ===
    local gripColor = COLORS[1]  -- Default to OFF

    if gv_grip >= 0 and gv_grip <= 5 then
        if gv_grip == 4 then
        -- Breathing RED
            local msNow = now * 10  -- convert to ms
            local phase = ((msNow % BREATH_CYCLE_MS) / BREATH_CYCLE_MS) * 2 * math.pi
            local sinVal = (math.sin(phase) * 0.5 + 0.5)  -- normalize to 0.0–1.0
            local intensity = BREATH_INTENSITY_MIN + (BREATH_INTENSITY_MAX - BREATH_INTENSITY_MIN) * sinVal
            gripColor = scaleColor(COLORS[5], intensity)
        elseif gv_grip == 5 then
            -- Blink RED
            local flashDelay = FLASH_INTERVAL_MS / 10
            if now - flashTimer > flashDelay then
                flashTimer = now
                flashState = not flashState
            end
            gripColor = flashState and COLORS[5] or COLORS[1]
        else
            gripColor = COLORS[gv_grip + 1] or COLORS[1]
        end
    end

    -- === Apply colors ===
    setSegmentColor(Top_Start, Top_Size, topColor)
    setSegmentColor(Grip_Start, Grip_Size, gripColor)
    setSegmentColor(Base_L_Start, Base_L_Size, bottomColor)
    setSegmentColor(Base_R_Start, Base_R_Size, bottomColor)

    applyRGBLedColors()
end

local function background()
end

return { run = run, background = background, init = init }
