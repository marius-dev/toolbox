#!/usr/bin/env python3
"""
macOS DMG Background Generator

Generates a professional DMG background image with drag-and-drop visual cues.
Creates an 800x450 PNG with gradient background, curved arrow, and instructional text.

Usage:
    python3 generate-dmg-background.py [options]

Options:
    --text TEXT           Custom text to display (default: "Drag to install")
    --output PATH         Output file path (default: scripts/installers/dmg-background.png)
    --help               Show this help message
"""

import sys
import subprocess
import os
import math
from pathlib import Path

# Check and auto-install Pillow if needed
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Pillow not found. Installing...")
    try:
        # Try installing with --user flag first (safer)
        subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", "Pillow>=10.0.0"])
    except subprocess.CalledProcessError:
        # If that fails, try with --break-system-packages (for externally-managed environments)
        subprocess.check_call([sys.executable, "-m", "pip", "install", "--break-system-packages", "Pillow>=10.0.0"])
    from PIL import Image, ImageDraw, ImageFont


class DMGBackgroundConfig:
    """Configuration for DMG background image generation"""

    # Image dimensions (matching DMG window size in build-macos-dmg.sh)
    WIDTH = 800
    HEIGHT = 450

    # Icon positions (from build-macos-dmg.sh --icon and --app-drop-link)
    APP_ICON_POS = (200, 190)
    APP_ICON_SIZE = 100
    APPS_FOLDER_POS = (600, 185)

    # Visual design - Simple transparent background
    BACKGROUND_COLOR = (255, 255, 255, 0)  # Fully transparent (RGBA)

    # Arrow styling - disabled
    ARROW_COLOR = None  # No arrow
    ARROW_WIDTH = 3
    ARROW_HEAD_SIZE = 12

    # Text styling
    TEXT_CONTENT = "Drag to install"
    TEXT_COLOR = (110, 110, 115, 255)  # Medium gray (RGBA)
    TEXT_SIZE = 20
    TEXT_POSITION_Y = 240  # Positioned below arrow arc

    # Output
    OUTPUT_PATH = "scripts/installers/dmg-background.png"


class DMGBackgroundGenerator:
    """Generates professional DMG background images"""

    def __init__(self, config: DMGBackgroundConfig):
        self.config = config
        self.image = None
        self.draw = None

    def hex_to_rgb(self, hex_color: str) -> tuple:
        """Convert hex color to RGB tuple"""
        hex_color = hex_color.lstrip('#')
        return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

    def create_gradient_background(self):
        """Create transparent background"""
        # Create transparent RGBA image
        self.image = Image.new('RGBA', (self.config.WIDTH, self.config.HEIGHT), self.config.BACKGROUND_COLOR)
        self.draw = ImageDraw.Draw(self.image)

    def calculate_bezier_point(self, t: float, p0: tuple, p1: tuple, p2: tuple, p3: tuple) -> tuple:
        """Calculate point on cubic Bezier curve at parameter t (0 to 1)"""
        # Cubic Bezier formula: B(t) = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
        one_minus_t = 1 - t

        x = (one_minus_t**3 * p0[0] +
             3 * one_minus_t**2 * t * p1[0] +
             3 * one_minus_t * t**2 * p2[0] +
             t**3 * p3[0])

        y = (one_minus_t**3 * p0[1] +
             3 * one_minus_t**2 * t * p1[1] +
             3 * one_minus_t * t**2 * p2[1] +
             t**3 * p3[1])

        return (x, y)

    def draw_curved_arrow(self):
        """Draw smooth curved arrow from app icon to Applications folder"""
        # Start and end points (centered on icon positions)
        start_x = self.config.APP_ICON_POS[0] + self.config.APP_ICON_SIZE // 2
        start_y = self.config.APP_ICON_POS[1] + self.config.APP_ICON_SIZE // 2
        end_x = self.config.APPS_FOLDER_POS[0]
        end_y = self.config.APPS_FOLDER_POS[1] + self.config.APP_ICON_SIZE // 2

        start = (start_x, start_y)
        end = (end_x, end_y)

        # Calculate control points for gentle upward arc
        mid_x = (start[0] + end[0]) / 2
        arc_height = 50  # How much the curve arcs upward
        control_y = min(start[1], end[1]) - arc_height

        # Control points for cubic Bezier curve
        control1 = (start[0] + (mid_x - start[0]) * 0.5, control_y)
        control2 = (end[0] - (end[0] - mid_x) * 0.5, control_y)

        # Generate smooth curve points
        steps = 100
        curve_points = []
        for i in range(steps + 1):
            t = i / steps
            point = self.calculate_bezier_point(t, start, control1, control2, end)
            curve_points.append(point)

        # Draw the curve
        self.draw.line(curve_points, fill=self.config.ARROW_COLOR, width=self.config.ARROW_WIDTH, joint='curve')

        # Draw arrow head at the end
        self.draw_arrow_head(curve_points[-2], end)

    def draw_arrow_head(self, prev_point: tuple, end_point: tuple):
        """Draw arrow head pointing from prev_point to end_point"""
        # Calculate angle of arrow
        dx = end_point[0] - prev_point[0]
        dy = end_point[1] - prev_point[1]
        angle = math.atan2(dy, dx)

        # Arrow head parameters
        head_size = self.config.ARROW_HEAD_SIZE
        head_angle = math.pi / 6  # 30 degrees

        # Calculate arrow head points
        left_x = end_point[0] - head_size * math.cos(angle - head_angle)
        left_y = end_point[1] - head_size * math.sin(angle - head_angle)

        right_x = end_point[0] - head_size * math.cos(angle + head_angle)
        right_y = end_point[1] - head_size * math.sin(angle + head_angle)

        # Draw filled triangle for arrow head
        arrow_head = [
            end_point,
            (left_x, left_y),
            (right_x, right_y)
        ]
        self.draw.polygon(arrow_head, fill=self.config.ARROW_COLOR)

    def get_font(self, size: int):
        """Get best available system font with fallback"""
        # Try macOS system fonts in order of preference
        font_paths = [
            "/System/Library/Fonts/SFNS.ttf",                    # SF Pro (macOS 11+)
            "/System/Library/Fonts/SFNSDisplay.ttf",              # SF Display
            "/System/Library/Fonts/Helvetica.ttc",                # Helvetica
            "/System/Library/Fonts/HelveticaNeue.ttc",            # Helvetica Neue
            "/Library/Fonts/Arial.ttf",                           # Arial
        ]

        for font_path in font_paths:
            try:
                if os.path.exists(font_path):
                    return ImageFont.truetype(font_path, size)
            except Exception:
                continue

        # Fallback to default font
        try:
            return ImageFont.load_default()
        except Exception:
            return None

    def draw_text(self, text: str = None):
        """Draw instructional text"""
        if text is None:
            text = self.config.TEXT_CONTENT

        # Get font
        font = self.get_font(self.config.TEXT_SIZE)

        # Calculate text position (centered horizontally)
        # Use textbbox for accurate text dimensions
        bbox = self.draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_x = (self.config.WIDTH - text_width) // 2
        text_y = self.config.TEXT_POSITION_Y

        # Draw text with antialiasing
        self.draw.text(
            (text_x, text_y),
            text,
            font=font,
            fill=self.config.TEXT_COLOR
        )

    def draw_icon_hints(self):
        """Draw subtle circular highlights at icon positions (optional)"""
        # Subtle circle at app icon position
        icon_center_x = self.config.APP_ICON_POS[0] + self.config.APP_ICON_SIZE // 2
        icon_center_y = self.config.APP_ICON_POS[1] + self.config.APP_ICON_SIZE // 2
        radius = self.config.APP_ICON_SIZE // 2 + 5

        # Very subtle highlight (almost invisible, just adds depth)
        highlight_color = (0, 0, 0, 10)  # Nearly transparent

        self.draw.ellipse(
            [
                icon_center_x - radius,
                icon_center_y - radius,
                icon_center_x + radius,
                icon_center_y + radius
            ],
            outline=highlight_color,
            width=1
        )

    def generate(self, output_path: str = None) -> str:
        """Generate the complete DMG background image"""
        if output_path is None:
            output_path = self.config.OUTPUT_PATH

        # Ensure output directory exists
        output_dir = Path(output_path).parent
        output_dir.mkdir(parents=True, exist_ok=True)

        print(f"Generating DMG background image...")
        print(f"  Dimensions: {self.config.WIDTH}x{self.config.HEIGHT}")
        print(f"  App icon position: {self.config.APP_ICON_POS}")
        print(f"  Applications position: {self.config.APPS_FOLDER_POS}")

        # Layer 1: Transparent background
        self.create_gradient_background()

        # Layer 2: Icon hints (optional, very subtle)
        # self.draw_icon_hints()  # Commented out by default

        # Layer 3: Curved arrow (skip if disabled)
        if self.config.ARROW_COLOR is not None:
            self.draw_curved_arrow()

        # Layer 4: Text
        self.draw_text()

        # Save with optimization
        self.image.save(output_path, 'PNG', optimize=True)

        file_size = Path(output_path).stat().st_size / 1024  # KB
        print(f"  Output: {output_path} ({file_size:.1f} KB)")
        print("✓ DMG background generated successfully")

        return output_path


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description='Generate professional DMG background image for macOS installers',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 generate-dmg-background.py
  python3 generate-dmg-background.py --text "Drop to Applications"
  python3 generate-dmg-background.py --output custom-background.png
        """
    )

    parser.add_argument(
        '--text',
        type=str,
        help='Custom text to display (default: "Drag to install")'
    )

    parser.add_argument(
        '--output',
        type=str,
        help='Output file path (default: scripts/installers/dmg-background.png)'
    )

    args = parser.parse_args()

    # Create configuration
    config = DMGBackgroundConfig()

    # Apply custom text if provided
    if args.text:
        config.TEXT_CONTENT = args.text

    # Apply custom output path if provided
    if args.output:
        config.OUTPUT_PATH = args.output

    # Generate background
    try:
        generator = DMGBackgroundGenerator(config)
        generator.generate()
        return 0
    except Exception as e:
        print(f"Error generating DMG background: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
