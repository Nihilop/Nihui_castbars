# Nihui CB - Cast Bars

**Version:** 1.2
**Author:** nihil (based on rnxmUI)

Customizable cast bars for Player, Target, and Focus with advanced positioning, masks, and visual effects.

## Features

### Supported Units
- **Player Cast Bar:** Your spell casts and channels
- **Target Cast Bar:** Enemy/friendly target cast tracking
- **Focus Cast Bar:** Focus target cast monitoring

### Visual Elements
- **Spell Icon:** Display the spell being cast
- **Spell Name:** Show the name of the spell/ability
- **Cast Timer:** Countdown or progress timer
- **Cast Bar Fill:** Smooth progress bar animation
- **Custom Masks:** Apply shaped masks for unique appearance

### Customization Options

#### Per-Unit Configuration
Each cast bar (Player, Target, Focus) has independent settings:

- **Enable/Disable:** Show or hide specific cast bars
- **Size:** Custom width and height
- **Position:** Full control with point, relativeTo, relativePoint, and X/Y offsets
- **Mask Texture:** Apply custom shaped masks
- **Movable Mode:** Drag-and-drop positioning in-game

#### Visual Toggles
- **Show Icon:** Enable/disable spell icon display
- **Show Text:** Enable/disable spell name text
- **Show Timer:** Enable/disable cast time countdown

### Debug Mode
- **Development Tools:** Built-in debug mode for testing
- **Position Helpers:** Visual guides for frame placement
- **Console Logging:** Detailed event tracking

### Interrupt Detection
- **Visual Feedback:** Clear indication when a cast is interrupted
- **Lockout Display:** Show spell school lockout duration

## Installation

1. Extract the `Nihui_cb` folder to:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
2. Restart World of Warcraft or type `/reload`

## Configuration

Open the settings panel:
```
/nihuicb
```

### Quick Setup

1. Type `/nihuicb` to open the configuration GUI
2. Select the unit (Player, Target, or Focus)
3. Enable movable mode to drag the cast bar to your desired position
4. Adjust size, visibility options, and mask texture
5. Disable movable mode to lock the position

### Positioning Cast Bars

**Method 1: Drag-and-Drop (Recommended)**
1. Enable "Movable" option for the unit
2. Click and drag the cast bar to desired position
3. Disable "Movable" to lock it in place

**Method 2: Manual Coordinates**
1. Set anchor point (e.g., "BOTTOM", "CENTER")
2. Set relative frame ("UIParent" or other frame name)
3. Set relative point (where on the relative frame to anchor)
4. Adjust X/Y offsets for fine-tuning

### Default Positions

**Player Cast Bar:**
- Point: `BOTTOM`
- Relative: `UIParent`
- X Offset: 0
- Y Offset: 150 (above bottom of screen)

**Target Cast Bar:**
- Point: `CENTER`
- Relative: `UIParent`
- X Offset: 0
- Y Offset: -50 (slightly below center)

**Focus Cast Bar:**
- Point: `CENTER`
- Relative: `UIParent`
- X Offset: 250
- Y Offset: -50 (to the right of target)

### Custom Masks

Apply custom shaped masks to your cast bars:
```lua
mask = "Interface\\AddOns\\Nihui_cb\\textures\\UIUnitFramePlayerHealthMask2x.tga"
```

Masks create unique shapes like rounded corners, angled edges, or decorative borders.

### Reset to Defaults

Return to default configuration:
```
/nihuicb reset
```

## Compatibility

- **Game Version:** Retail (The War Within - 11.0.2+)
- **Works With:** All unit frame addons
- **Conflicts:** May conflict with other cast bar addons (Quartz, GnomishCastbars)

## Performance

- Efficient event handling (registers only when needed)
- Smooth animations with minimal CPU usage
- Lightweight memory footprint

## Saved Variables

Settings stored per character:
```
WTF\Account\<ACCOUNT>\<SERVER>\<CHARACTER>\SavedVariables\NihuiCastBarsDB.lua
```

## Troubleshooting

**Q: Cast bars not showing**
A: Make sure the cast bar is enabled in `/nihuicb` and check that you're casting a spell

**Q: Cast bar is in wrong position**
A: Enable movable mode and drag it, or check the X/Y offset values

**Q: Mask texture not applying**
A: Verify the mask file path is correct and exists in the textures folder

**Q: Timer not showing**
A: Enable "Show Timer" option in the configuration for that unit

**Q: Focus cast bar not visible**
A: Make sure you have a focus target set (`/focus`)

**Q: Cast bar too small/large**
A: Adjust width and height values in the configuration

## Debug Mode

Enable debug mode for development and troubleshooting:
```lua
debug = true
```

Debug mode provides:
- Console logging of cast events
- Frame position information
- Event firing details

## Commands

- `/nihuicb` - Open configuration GUI
- `/nihuicb reset` - Reset to default settings
- `/reload` - Reload UI after major changes

## Tips

1. **Positioning:** Place player cast bar near your unit frames for easy viewing
2. **Size:** Make target/focus cast bars smaller than player cast bar for hierarchy
3. **Masks:** Use consistent masks across all cast bars for visual cohesion
4. **Icons:** Show icons for enemy cast bars to quickly identify dangerous spells
5. **Timer:** Enable timer on target/focus to track interrupt windows

## Credits

**Author:** nihil
**Based on:** rnxmUI cast bar system

Part of the **Nihui UI Suite**

---

*Track every cast with precision*
