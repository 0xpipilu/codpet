#!/usr/bin/env python3

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
BIRD_PATH = ROOT / "pets" / "blackbird" / "base.png"
FAVICON_PATH = ROOT / "assets" / "brand" / "favicon.png"

def make_favicon():
    if not BIRD_PATH.exists():
        print(f"Error: {BIRD_PATH} not found. Run scripts/generate_thumbnails.py first.")
        return

    try:
        with Image.open(BIRD_PATH) as img:
            # Ensure we are in RGBA mode for transparency
            if img.mode != "RGBA":
                img = img.convert("RGBA")

            # 1. Get the bounding box of the non-transparent pixels (the bird)
            bbox = img.getbbox()
            if not bbox:
                print("Error: The base image seems to be completely transparent.")
                return
            
            # Crop to the bird content
            cropped_bird = img.crop(bbox)
            
            # 2. Define standard target square favicon size
            # 64x64 is the optimal size for modern high-definition retina favicons
            size = 64
            favicon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
            
            # 3. Proportionally resize the cropped bird to fit inside the square with a nice padding
            # We want the bird to occupy a maximum of 80% (51px) of the canvas,
            # leaving a clean, breathing-room margin so the icon looks premium in tab bars.
            max_content_size = int(size * 0.82)
            
            w, h = cropped_bird.size
            if w > h:
                new_w = max_content_size
                new_h = int(h * (max_content_size / w))
            else:
                new_h = max_content_size
                new_w = int(w * (max_content_size / h))
                
            resized_bird = cropped_bird.resize((new_w, new_h), Image.Resampling.LANCZOS)
            
            # 4. Center the resized bird on the transparent square canvas
            x = (size - new_w) // 2
            y = (size - new_h) // 2
            
            favicon.paste(resized_bird, (x, y), resized_bird)
            
            # 5. Save the premium high-definition favicon.png
            favicon.save(FAVICON_PATH, "PNG", optimize=True)
            print(f"Successfully generated a premium 64x64 favicon.png at {FAVICON_PATH}")
            
    except Exception as e:
        print(f"Error generating favicon: {e}")

if __name__ == "__main__":
    make_favicon()
