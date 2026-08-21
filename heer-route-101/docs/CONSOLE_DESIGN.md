---
name: HEER Operator Console
colors:
  surface: '#111318'
  surface-dim: '#111318'
  surface-bright: '#37393e'
  surface-container-lowest: '#0c0e12'
  surface-container-low: '#1a1c20'
  surface-container: '#1e2024'
  surface-container-high: '#282a2e'
  surface-container-highest: '#333539'
  on-surface: '#e2e2e8'
  on-surface-variant: '#b9cacb'
  inverse-surface: '#e2e2e8'
  inverse-on-surface: '#2f3035'
  outline: '#849495'
  outline-variant: '#3b494b'
  surface-tint: '#00dbe9'
  primary: '#dbfcff'
  on-primary: '#00363a'
  primary-container: '#00f0ff'
  on-primary-container: '#006970'
  inverse-primary: '#006970'
  secondary: '#ffdb9d'
  on-secondary: '#412d00'
  secondary-container: '#feb700'
  on-secondary-container: '#6b4b00'
  tertiary: '#ddffd3'
  on-tertiary: '#003907'
  tertiary-container: '#00fb40'
  on-tertiary-container: '#006e16'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#7df4ff'
  primary-fixed-dim: '#00dbe9'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f54'
  secondary-fixed: '#ffdea8'
  secondary-fixed-dim: '#ffba20'
  on-secondary-fixed: '#271900'
  on-secondary-fixed-variant: '#5e4200'
  tertiary-fixed: '#72ff70'
  tertiary-fixed-dim: '#00e639'
  on-tertiary-fixed: '#002203'
  on-tertiary-fixed-variant: '#00530e'
  background: '#111318'
  on-background: '#e2e2e8'
  surface-variant: '#333539'
typography:
  display-lg:
    fontFamily: Space Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.05em
  body-base:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
    letterSpacing: 0.01em
  data-mono:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: '1.4'
    letterSpacing: 0.03em
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: 0.1em
spacing:
  unit: 4px
  gutter: 16px
  margin: 24px
  panel-padding: 20px
---

## Brand & Style
The design system for this command center is built on a "Tactical Glass" aesthetic—a fusion of advanced glassmorphism and functional HUD (Heads-Up Display) elements. The system is designed to evoke a sense of absolute control, high-stakes security, and futuristic intelligence. 

The interface behaves like a high-performance instrument. It utilizes deep layering, background saturation, and precision-engineered reticle frames to create a workspace that feels like a physical piece of optical hardware. The emotional response is one of calm authority, intense focus, and technical superiority.

## Colors
The palette is rooted in an "Obsidian Depth" scheme. The base is a near-black charcoal, providing a high-contrast foundation for glowing technical accents.

- **Primary (Cyan/Electric):** Used for standard telemetry, active states, and data streams. It represents the "normal" operating state of the AI.
- **Secondary (Amber/Warning):** Reserved for alerts, moderate priority shifts, and interactive highlights.
- **Tertiary (Emerald/Secure):** Used exclusively for system health indicators and verified security status.
- **Surface Tones:** Layers use varying levels of opacity rather than solid colors to maintain the glass effect.

## Typography
The typographic hierarchy emphasizes rapid data scanning. **Space Grotesk** provides a technical, futuristic edge for high-level headers. **Hanken Grotesk** ensures that dense reports remain legible and professional. **JetBrains Mono** is the workhorse of the system, used for all telemetry, timestamps, and technical metadata to reinforce the sense of a live data feed. All labels should be set in uppercase with increased letter spacing to mimic military-spec instrumentation.

## Layout & Spacing
The layout follows a strict 12-column fluid grid system, but panels are treated as autonomous "HUD Modules." 

- **Grid:** Use a 4px baseline grid to ensure all elements align to a technical rhythm.
- **Margins:** A global "safe zone" margin of 24px frames the entire viewport, often accented with corner reticles.
- **Responsibility:** On smaller displays, panels collapse into a single-column vertical stack, but the "Telemetry Strips" (top/bottom bars) remain fixed to the viewport edges to maintain the HUD feel.

## Elevation & Depth
Elevation is not conveyed through traditional shadows, but through **Optical Stacking**:
- **Base Layer:** Deep charcoal (#0A0C10) with a subtle scanline overlay (1% opacity).
- **Glass Panels:** Background Blur (30px to 50px) with a semi-transparent fill (rgba(255, 255, 255, 0.03)).
- **Inner Glows:** Instead of drop shadows, active panels use a 1px inner border in the Primary color with a soft 4px outer bloom (glow).
- **Vignetting:** A soft radial gradient darkens the corners of the screen to focus the operator's eye on the central command area.

## Shapes
This design system utilizes a **Sharp (0px)** radius to maintain a high-precision, military-grade aesthetic. 

Structural integrity is reinforced through "Corner Brackets"—thin, 1px L-shaped lines that sit at the corners of panels but do not fully connect, creating a reticle effect. All progress bars and indicators should use segmented, rectangular blocks rather than continuous rounded pills.

## Components

### HUD-Style Panels
Panels must feature a subtle scanline texture and a 1px border. The top-left corner should include a metadata label (e.g., "MODULE_08 // STATUS: ACTIVE") in Monospace.

### Telemetry Strips
Horizontal data strips used for scrolling alerts or system stats. These feature no background fill, only top and bottom 1px borders, and a blinking "Live" indicator.

### Segmented Progress Bars
Progress is displayed as a series of distinct vertical blocks. Filled blocks use a Primary color glow; empty blocks use a low-opacity neutral.

### Technical Buttons
Buttons are strictly rectangular. The "Primary" variant is a solid color block with black text. The "Ghost" variant is an outline with corner accent marks that expand slightly on hover to simulate a digital "lock-on."

### Status Indicators
Small circular icons with a "breathing" animation (pulsing opacity) to indicate active AI processing or system heartbeats.

### Input Fields
Inputs are bottom-border only, using the Monospace font. Upon focus, the bottom border glows and a small reticle icon appears at the start of the field.