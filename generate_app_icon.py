#!/usr/bin/env python3
"""
Generate app icon for BreatheWithMe
Creates a 1024x1024 PNG icon with a calming, minimalist design
"""

from PIL import Image, ImageDraw, ImageFilter
import math

# App color scheme - soft blue
APP_BLUE = (166, 204, 235)  # RGB for Color(red: 0.65, green: 0.8, blue: 0.92)
DARKER_BLUE = (130, 170, 210)
LIGHTER_BLUE = (200, 230, 250)
WHITE = (255, 255, 255)

def create_app_icon():
    """Create a 1024x1024 app icon"""
    size = 1024
    center = size // 2
    max_dist = math.sqrt(center ** 2 + center ** 2)
    
    # Create RGBA image for better blending
    img = Image.new('RGBA', (size, size), WHITE)
    
    # Create a radial gradient background more efficiently
    pixels = img.load()
    for y in range(size):
        for x in range(size):
            distance = math.sqrt((x - center) ** 2 + (y - center) ** 2)
            ratio = min(distance / max_dist, 1.0)
            # Smooth easing function for better gradient
            ratio = ratio * ratio  # Quadratic easing
            
            r = int(LIGHTER_BLUE[0] * (1 - ratio) + WHITE[0] * ratio)
            g = int(LIGHTER_BLUE[1] * (1 - ratio) + WHITE[1] * ratio)
            b = int(LIGHTER_BLUE[2] * (1 - ratio) + WHITE[2] * ratio)
            pixels[x, y] = (r, g, b, 255)
    
    # Draw concentric circles representing breathing pattern
    # Three circles at different scales to represent inhale/exhale cycle
    circle_radii = [380, 280, 180]  # Outer to inner
    circle_opacities = [0.25, 0.35, 0.45]  # Increasing opacity toward center
    circle_widths = [12, 10, 8]  # Decreasing width toward center
    
    for radius, opacity, width in zip(circle_radii, circle_opacities, circle_widths):
        # Create a temporary image for the circle with alpha
        circle_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        circle_draw = ImageDraw.Draw(circle_img)
        
        # Draw the circle outline with smooth edges
        bbox = [center - radius, center - radius, center + radius, center + radius]
        
        # Blend the blue color with transparency
        alpha = int(255 * opacity)
        circle_color = (*APP_BLUE, alpha)
        
        # Draw circle outline with specified width
        circle_draw.ellipse(bbox, outline=circle_color, width=width)
        
        # Composite the circle onto the main image
        img = Image.alpha_composite(img, circle_img)
    
    # Add a subtle center point
    center_radius = 40
    center_alpha = 0.7
    center_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    center_draw = ImageDraw.Draw(center_img)
    center_bbox = [center - center_radius, center - center_radius,
                   center + center_radius, center + center_radius]
    center_color = (*DARKER_BLUE, int(255 * center_alpha))
    center_draw.ellipse(center_bbox, fill=center_color)
    
    img = Image.alpha_composite(img, center_img)
    
    # Convert to RGB for final output
    img = img.convert('RGB')
    
    return img

if __name__ == '__main__':
    print("Generating app icon...")
    icon = create_app_icon()
    
    output_path = 'BreatheWithMe/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
    icon.save(output_path, 'PNG', optimize=True)
    print(f"✓ App icon saved to {output_path}")
    print("Icon size: 1024x1024 pixels")

