"""
Download Blood Bowl 3 team logos and wallpapers from Cyanide Studio CDN.
"""

import os
import ssl
import urllib.request

# Disable SSL verification for simplicity
ssl._create_default_https_context = ssl._create_unverified_context

LOGOS_URL = "https://images.cyanide-studio.com/bb3/logos/"
WALLPAPERS_URL = "https://images.cyanide-studio.com/bb3/races/team_screenshots/"
ASSETS_DIR = os.path.join(os.path.dirname(__file__), "assets", "teams")

# Mapping from backend team IDs to Cyanide logo names
TEAM_LOGO_MAPPING = {
    "amazon": "Logo_Amazon_01.png",
    "black_orcs": "Logo_BlackOrc_01.png",
    "chaos_chosen": "Logo_ChaosChosen_01.png",
    "chaos_dwarf": "Logo_ChaosDwarf_01.png",
    "chaos_renegades": None,  # Not available in logos
    "dark_elves": "Logo_DarkElf_01.png",
    "dwarfs": "Logo_Dwarf_01.png",
    "elven_union": "Logo_ElvenUnion_01.png",
    "gnome": None,  # Not available
    "goblin": "Logo_Goblin_01.png",
    "halfling": "Logo_Halfling_01.png",
    "high_elf": None,  # Not available
    "humans": "Logo_Human_01.png",
    "imperial_nobility": "Logo_ImperialNobility_01.png",
    "khorne": "Logo_Khorne_01.png",
    "lizardmen": "Logo_Lizardman_01.png",
    "necromantic_horrors": "Logo_Necromantic_01.png",
    "norse": "Logo_Norse_01.png",
    "nurgles": "Logo_Nurgle_01.png",
    "ogre": None,  # Not available
    "old_world_alliance": None,  # Not available in logos
    "orcs": "Logo_Orc_01.png",
    "shambling_undead": "Logo_Undead_01.png",
    "skaven": "Logo_Skaven_01.png",
    "snotling": None,  # Not available
    "tomb_kings": None,  # Not available
    "underworld_denizens": "Logo_Underworld_01.png",
    "vampire": "Logo_Vampire_01.png",
    "wood_elves": "Logo_WoodElf_01.png",
    "bretonnian": None,  # Not available
}

# Mapping for wallpapers (team_screenshots)
TEAM_WALLPAPER_MAPPING = {
    "amazon": "amazon.png",
    "black_orcs": "blackOrc.png",
    "chaos_chosen": "chaosChosen.png",
    "chaos_dwarf": "chaosDwarf.png",
    "chaos_renegades": "chaosRenegade.png",
    "dark_elves": "darkElf.png",
    "dwarfs": "dwarf.png",
    "elven_union": "elvenUnion.png",
    "gnome": None,  # Not available
    "goblin": "goblin.png",
    "halfling": "halfling.png",
    "high_elf": None,  # Not available
    "humans": "human.png",
    "imperial_nobility": "imperialNobility.png",
    "khorne": "khorne.png",
    "lizardmen": "lizardman.png",
    "necromantic_horrors": "necromanticHorror.png",
    "norse": "norse.png",
    "nurgles": "nurgle.png",
    "ogre": None,  # Not available
    "old_world_alliance": "oldWorldAlliance.png",
    "orcs": "orc.png",
    "shambling_undead": "shamblingUndead.png",
    "skaven": "skaven.png",
    "snotling": None,  # Not available
    "tomb_kings": None,  # Not available
    "underworld_denizens": "underworldDenizen.png",
    "vampire": "vampire.png",
    "wood_elves": "woodElf.png",
    "bretonnian": None,  # Not available
}


def download_file(url: str, dest_path: str):
    """Download a file from URL to destination path."""
    try:
        urllib.request.urlretrieve(url, dest_path)
        return True
    except Exception as e:
        print(f"  -> ERROR: {e}")
        return False


def download_logo(team_folder: str, logo_filename: str):
    """Download a logo from Cyanide CDN to the team folder."""
    team_dir = os.path.join(ASSETS_DIR, team_folder)
    os.makedirs(team_dir, exist_ok=True)

    url = f"{LOGOS_URL}{logo_filename}"
    dest_path = os.path.join(team_dir, "logo.png")

    print(f"Downloading {team_folder} logo from {url}...")
    if download_file(url, dest_path):
        print(f"  -> Saved to {dest_path}")
        return True
    return False


def download_wallpaper(team_folder: str, wallpaper_filename: str):
    """Download a wallpaper from Cyanide CDN to the team folder."""
    team_dir = os.path.join(ASSETS_DIR, team_folder)
    os.makedirs(team_dir, exist_ok=True)

    url = f"{WALLPAPERS_URL}{wallpaper_filename}"
    dest_path = os.path.join(team_dir, "wallpaper.png")

    print(f"Downloading {team_folder} wallpaper from {url}...")
    if download_file(url, dest_path):
        print(f"  -> Saved to {dest_path}")
        return True
    return False


def main():
    print("=" * 60)
    print("Blood Bowl 3 Logo & Wallpaper Downloader")
    print("Source: Cyanide Studio CDN")
    print("=" * 60)

    # Download logos
    print("\n--- LOGOS ---")
    logo_success = 0
    logo_failed = 0
    logo_skipped = 0

    for team_folder, logo_filename in TEAM_LOGO_MAPPING.items():
        if logo_filename is None:
            print(f"Skipping {team_folder} logo - not available in BB3")
            logo_skipped += 1
            continue

        if download_logo(team_folder, logo_filename):
            logo_success += 1
        else:
            logo_failed += 1

    # Download wallpapers
    print("\n--- WALLPAPERS ---")
    wp_success = 0
    wp_failed = 0
    wp_skipped = 0

    for team_folder, wallpaper_filename in TEAM_WALLPAPER_MAPPING.items():
        if wallpaper_filename is None:
            print(f"Skipping {team_folder} wallpaper - not available in BB3")
            wp_skipped += 1
            continue

        if download_wallpaper(team_folder, wallpaper_filename):
            wp_success += 1
        else:
            wp_failed += 1

    print("\n" + "=" * 60)
    print(
        f"Logos:     {logo_success} downloaded, {logo_failed} failed, {logo_skipped} skipped"
    )
    print(
        f"Wallpapers: {wp_success} downloaded, {wp_failed} failed, {wp_skipped} skipped"
    )
    print("=" * 60)

    # Show teams that need placeholders (no logo AND no wallpaper)
    missing_both = [
        t
        for t in TEAM_LOGO_MAPPING
        if TEAM_LOGO_MAPPING[t] is None and TEAM_WALLPAPER_MAPPING.get(t) is None
    ]
    if missing_both:
        print("\nTeams without ANY BB3 assets (need placeholders):")
        for team in missing_both:
            print(f"  - {team}")


if __name__ == "__main__":
    main()
