"""
Download neutral logos for teams not in Blood Bowl 3.
"""

import os
import ssl
import urllib.request

ssl._create_default_https_context = ssl._create_unverified_context

BASE_URL = "https://images.cyanide-studio.com/bb3/logos/"
ASSETS_DIR = os.path.join(os.path.dirname(__file__), "assets", "teams")

# Use different neutral logos for variety
MISSING_TEAMS = {
    "gnome": "Logo_Neutral_01.png",
    "high_elf": "Logo_Neutral_02.png",
    "ogre": "Logo_Neutral_03.png",
    "snotling": "Logo_Neutral_04.png",
    "tomb_kings": "Logo_Neutral_05.png",
    "bretonnian": "Logo_Neutral_06.png",
}


def download_placeholder(team_id: str, logo_filename: str):
    team_dir = os.path.join(ASSETS_DIR, team_id)
    os.makedirs(team_dir, exist_ok=True)

    url = f"{BASE_URL}{logo_filename}"
    logo_path = os.path.join(team_dir, "logo.png")
    wallpaper_path = os.path.join(team_dir, "wallpaper.png")

    print(f"Downloading placeholder for {team_id}...")
    try:
        urllib.request.urlretrieve(url, logo_path)
        # Copy same file as wallpaper too
        urllib.request.urlretrieve(url, wallpaper_path)
        print(f"  -> Saved to {team_dir}")
        return True
    except Exception as e:
        print(f"  -> ERROR: {e}")
        return False


if __name__ == "__main__":
    print("Creating placeholders for missing teams...")
    for team_id, logo in MISSING_TEAMS.items():
        download_placeholder(team_id, logo)
    print("Done!")
