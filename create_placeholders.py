"""
Generate simple placeholder logos for teams not in Blood Bowl 3.
"""

import os

from PIL import Image, ImageDraw, ImageFont

ASSETS_DIR = os.path.join(os.path.dirname(__file__), "assets", "teams")

# Teams that need placeholder images
MISSING_TEAMS = {
    "gnome": {"name": "Gnome", "color": (139, 69, 19)},  # Brown
    "high_elf": {"name": "High Elf", "color": (255, 215, 0)},  # Gold
    "ogre": {"name": "Ogre", "color": (128, 128, 128)},  # Gray
    "snotling": {"name": "Snotling", "color": (0, 128, 0)},  # Green
    "tomb_kings": {"name": "Tomb Kings", "color": (218, 165, 32)},  # Goldenrod
    "bretonnian": {"name": "Bretonnian", "color": (30, 144, 255)},  # Dodger Blue
}


def create_placeholder(team_id: str, team_info: dict, size: int = 256):
    """Create a simple circular placeholder logo with team initials."""
    team_dir = os.path.join(ASSETS_DIR, team_id)
    os.makedirs(team_dir, exist_ok=True)

    # Create image with transparency
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw circle background
    margin = 10
    draw.ellipse(
        [margin, margin, size - margin, size - margin],
        fill=team_info["color"],
        outline=(0, 0, 0),
    )

    # Get initials
    words = team_info["name"].split()
    initials = "".join(w[0].upper() for w in words)

    # Draw text (use default font since custom fonts may not be available)
    try:
        font = ImageFont.truetype("arial.ttf", size // 3)
    except:
        font = ImageFont.load_default()

    # Calculate text position to center it
    bbox = draw.textbbox((0, 0), initials, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - bbox[1]  # Adjust for baseline

    draw.text((x, y), initials, fill=(255, 255, 255), font=font)

    # Save
    logo_path = os.path.join(team_dir, "logo.png")
    wallpaper_path = os.path.join(team_dir, "wallpaper.png")

    img.save(logo_path, "PNG")
    print(f"Created placeholder logo: {logo_path}")

    # Create a larger wallpaper version with the same style
    wp_size = 512
    wp_img = Image.new("RGBA", (wp_size, wp_size), team_info["color"])
    wp_draw = ImageDraw.Draw(wp_img)

    # Draw a subtle pattern or just paste the logo in center
    small_logo = img.resize((wp_size // 2, wp_size // 2), Image.Resampling.LANCZOS)
    paste_pos = ((wp_size - wp_size // 2) // 2, (wp_size - wp_size // 2) // 2)
    wp_img.paste(small_logo, paste_pos, small_logo)

    wp_img.save(wallpaper_path, "PNG")
    print(f"Created placeholder wallpaper: {wallpaper_path}")


def main():
    print("=" * 60)
    print("Creating placeholder images for missing BB3 teams")
    print("=" * 60)

    for team_id, team_info in MISSING_TEAMS.items():
        create_placeholder(team_id, team_info)

    print("\nDone!")


if __name__ == "__main__":
    main()
    main()
    main()
