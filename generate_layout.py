#!/usr/bin/env python3
"""
🎨 Terminal Nilam Layout Generator
Auto-generates fresh PNG layout with custom styling and colors.
Penempatan container yards tetap sama, hanya visual design yang berubah.
"""

from PIL import Image, ImageDraw, ImageFont
import math

# ============================================================================
# CONFIGURATION
# ============================================================================

# Canvas size (matches layout_mapper.dart)
CANVAS_WIDTH = 2560
CANVAS_HEIGHT = 1269

# Bounding box (from layout_mapper.dart)
LAT_MIN = -7.210500
LAT_MAX = -7.203500
LNG_MIN = 112.721500
LNG_MAX = 112.725800

# ============================================================================
# COLOR PALETTE (Modern & Professional)
# ============================================================================

COLORS = {
    'background': '#F0F4F8',      # Soft light blue-gray
    'cy1': '#4A90E2',              # Professional blue
    'cy2': '#7ED321',              # Fresh green
    'cy3': '#F5A623',              # Warm orange
    'border': '#2C3E50',            # Dark blue-gray
    'grid': '#E0E8F0',              # Light grid lines
    'text': '#2C3E50',              # Dark text
    'accent': '#FF6B6B',            # Accent red for important areas
    'water': '#E8F4F8',             # Light water blue
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def latLngToPixel(latitude, longitude):
    """Convert geographic coordinates to pixel coordinates."""
    # Normalize latitude (vertical)
    y_normalized = (LAT_MAX - latitude) / (LAT_MAX - LAT_MIN)
    pixel_y = y_normalized * CANVAS_HEIGHT
    
    # Normalize longitude (horizontal)
    x_normalized = (longitude - LNG_MIN) / (LNG_MAX - LNG_MIN)
    pixel_x = x_normalized * CANVAS_WIDTH
    
    return (pixel_x, pixel_y)

def drawRoundedRect(draw, xy, radius=20, fill=None, outline=None, width=2):
    """Draw rounded rectangle."""
    x1, y1, x2, y2 = xy
    draw.rectangle(
        [(x1+radius, y1), (x2-radius, y1), (x2, y1+radius), (x2, y2-radius),
         (x2-radius, y2), (x1+radius, y2), (x1, y2-radius), (x1, y1+radius)],
        fill=fill, outline=outline
    )
    draw.rectangle([(x1+radius, y1), (x2-radius, y2)], fill=fill)
    draw.rectangle([(x1, y1+radius), (x2, y2-radius)], fill=fill)

# ============================================================================
# CREATE IMAGE
# ============================================================================

def generate_layout():
    """Generate the new layout image."""
    
    # Create image with background
    img = Image.new('RGB', (CANVAS_WIDTH, CANVAS_HEIGHT), hex_to_rgb(COLORS['background']))
    draw = ImageDraw.Draw(img, 'RGBA')
    
    print("🎨 Starting layout generation...")
    
    # ========== 1. Draw subtle grid background ==========
    grid_spacing = 200
    grid_color = hex_to_rgb(COLORS['grid']) + (50,)  # Semi-transparent
    
    for x in range(0, CANVAS_WIDTH, grid_spacing):
        draw.line([(x, 0), (x, CANVAS_HEIGHT)], fill=grid_color, width=1)
    
    for y in range(0, CANVAS_HEIGHT, grid_spacing):
        draw.line([(0, y), (CANVAS_WIDTH, y)], fill=grid_color, width=1)
    
    print("✓ Grid drawn")
    
    # ========== 2. Define container yard regions ==========
    
    # CY1 (Blue) - Jalan Nilam Timur area
    cy1_coords = [
        (-7.204080, 112.722045),  # Top-left
        (-7.209240, 112.722045),  # Bottom-left
        (-7.209240, 112.724302),  # Bottom-right
        (-7.204080, 112.724302),  # Top-right
    ]
    
    # CY2 (Green) - Top area
    cy2_coords = [
        (-7.208150, 112.724161),  # Top-left
        (-7.209459, 112.724161),  # Bottom-left
        (-7.209459, 112.725250),  # Bottom-right
        (-7.208150, 112.725250),  # Top-right
    ]
    
    # CY3 (Orange) - Right side area
    cy3_coords = [
        (-7.207029, 112.722005),  # Top-left
        (-7.210336, 112.722005),  # Bottom-left
        (-7.210336, 112.724321),  # Bottom-right
        (-7.207029, 112.724321),  # Top-right
    ]
    
    # Convert to pixels and draw
    zones = [
        ('CY1', cy1_coords, COLORS['cy1'], 'Jalan Nilam Timur'),
        ('CY2', cy2_coords, COLORS['cy2'], 'Upper Terminal'),
        ('CY3', cy3_coords, COLORS['cy3'], 'Container Yard 3'),
    ]
    
    for zone_name, coords, color, label in zones:
        pixel_coords = [latLngToPixel(lat, lng) for lat, lng in coords]
        
        # Draw polygon for zone
        draw.polygon(pixel_coords, fill=hex_to_rgb(color) + (60,), outline=hex_to_rgb(COLORS['border']) + (180,), width=3)
        
        # Calculate center for label
        center_x = sum(px for px, py in pixel_coords) / len(pixel_coords)
        center_y = sum(py for px, py in pixel_coords) / len(pixel_coords)
        
        # Draw semi-transparent background for text
        text_bbox = (center_x - 80, center_y - 15, center_x + 80, center_y + 15)
        draw.rectangle(text_bbox, fill=hex_to_rgb(COLORS['background']) + (200,))
        
        # Draw zone label
        try:
            font = ImageFont.truetype("arial.ttf", 24)
        except:
            font = ImageFont.load_default()
        
        draw.text((center_x, center_y), zone_name, fill=hex_to_rgb(COLORS['text']), font=font, anchor='mm')
        
        print(f"✓ {zone_name} zone drawn")
    
    # ========== 3. Draw entrance/exit areas ==========
    
    # Gate area
    gate_pixel = latLngToPixel(-7.2099123, 112.7244489)
    gate_radius = 60
    draw.circle(
        gate_pixel,
        gate_radius,
        fill=hex_to_rgb(COLORS['accent']) + (80,),
        outline=hex_to_rgb(COLORS['accent']),
        width=2
    )
    
    # Parking area
    parking_pixel = latLngToPixel(-7.209907, 112.724877)
    draw.rectangle(
        [(parking_pixel[0]-70, parking_pixel[1]-70), (parking_pixel[0]+70, parking_pixel[1]+70)],
        fill=hex_to_rgb(COLORS['water']) + (100,),
        outline=hex_to_rgb(COLORS['border']),
        width=2
    )
    
    print("✓ Special areas drawn")
    
    # ========== 4. Add decorative compass rose ==========
    compass_x, compass_y = CANVAS_WIDTH - 150, CANVAS_HEIGHT - 150
    compass_size = 80
    
    # Draw compass circle
    draw.ellipse(
        [(compass_x - compass_size, compass_y - compass_size),
         (compass_x + compass_size, compass_y + compass_size)],
        outline=hex_to_rgb(COLORS['border']),
        width=2
    )
    
    # Draw compass points
    points = [
        ('N', 0),
        ('S', 180),
        ('E', 90),
        ('W', 270),
    ]
    
    for direction, angle in points:
        rad = math.radians(angle)
        x = compass_x + int(compass_size * 0.7 * math.sin(rad))
        y = compass_y - int(compass_size * 0.7 * math.cos(rad))
        
        try:
            font = ImageFont.truetype("arial.ttf", 16)
        except:
            font = ImageFont.load_default()
        
        draw.text((x, y), direction, fill=hex_to_rgb(COLORS['text']), font=font, anchor='mm')
    
    print("✓ Compass rose drawn")
    
    # ========== 5. Add border frame ==========
    border_width = 8
    draw.rectangle(
        [(0, 0), (CANVAS_WIDTH - 1, CANVAS_HEIGHT - 1)],
        outline=hex_to_rgb(COLORS['border']),
        width=border_width
    )
    
    print("✓ Border frame added")
    
    # ========== 6. Add title and info ==========
    try:
        font_large = ImageFont.truetype("arial.ttf", 32)
        font_small = ImageFont.truetype("arial.ttf", 14)
    except:
        font_large = font_small = ImageFont.load_default()
    
    # Title
    draw.text(
        (CANVAS_WIDTH // 2, 40),
        'Terminal Nilam - Live Map',
        fill=hex_to_rgb(COLORS['text']),
        font=font_large,
        anchor='mm'
    )
    
    # Info
    draw.text(
        (CANVAS_WIDTH // 2, CANVAS_HEIGHT - 40),
        'Singapore Container Terminal • Generated Layout v2',
        fill=hex_to_rgb(COLORS['text']),
        font=font_small,
        anchor='mm'
    )
    
    print("✓ Title and info added")
    
    # ========== 7. Add legend ==========
    legend_x, legend_y = 30, 100
    legend_items = [
        ('CY1 - Blue', COLORS['cy1']),
        ('CY2 - Green', COLORS['cy2']),
        ('CY3 - Orange', COLORS['cy3']),
        ('Gate Area', COLORS['accent']),
    ]
    
    for i, (label, color) in enumerate(legend_items):
        y = legend_y + (i * 40)
        
        # Color box
        draw.rectangle(
            [(legend_x, y), (legend_x + 25, y + 25)],
            fill=hex_to_rgb(color),
            outline=hex_to_rgb(COLORS['border']),
            width=1
        )
        
        # Label
        try:
            font = ImageFont.truetype("arial.ttf", 12)
        except:
            font = ImageFont.load_default()
        
        draw.text(
            (legend_x + 35, y + 12),
            label,
            fill=hex_to_rgb(COLORS['text']),
            font=font,
            anchor='lm'
        )
    
    print("✓ Legend added")
    
    # ========== 8. Save image ==========
    output_path = 'assets/images/nilam_layout.png'
    img.save(output_path, 'PNG', quality=95)
    
    print(f"\n✅ Layout generated successfully!")
    print(f"📁 Saved: {output_path}")
    print(f"📐 Dimensions: {CANVAS_WIDTH}×{CANVAS_HEIGHT}")
    print(f"🎨 Theme: Modern Professional")
    print(f"📍 Coordinates preserved: YES")

# ============================================================================
# MAIN
# ============================================================================

if __name__ == '__main__':
    try:
        generate_layout()
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
