#!/usr/bin/env python3
"""
Script to remove "Can Can" text from app icon and splash screen images.
The text is located in the bottom portion of the images.
"""

from PIL import Image, ImageDraw
import os
import sys

def remove_text_from_image(input_path, output_path=None):
    """
    Remove the "Can Can" text from an image by filling the text area with white.
    
    For a 1024x1024 reference image, the text area is:
    - x: [280, 736] (27.3% to 71.9% of width)
    - y: [716, 796] (69.9% to 77.7% of height)
    
    Args:
        input_path: Path to the input image
        output_path: Path to save the output image (default: overwrite input)
    
    Returns:
        True if successful, False otherwise
    """
    try:
        img = Image.open(input_path)
        width, height = img.size
        
        # Calculate text area proportionally
        # Based on the 1024x1024 reference image
        x_start = int(width * 0.273)  # 27.3%
        x_end = int(width * 0.719)    # 71.9%
        y_start = int(height * 0.699) # 69.9%
        y_end = int(height * 0.777)   # 77.7%
        
        # Create a draw object
        draw = ImageDraw.Draw(img)
        
        # Fill the text area with white
        draw.rectangle([x_start, y_start, x_end, y_end], fill=(255, 255, 255))
        
        # Save the image
        if output_path is None:
            output_path = input_path
        
        img.save(output_path)
        print(f"✓ Processed: {input_path} -> {output_path}")
        return True
        
    except Exception as e:
        print(f"✗ Error processing {input_path}: {e}")
        return False

def main():
    # List of all image files to process
    image_files = [
        # Android icons
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
        
        # Android splash/foreground images
        "android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png",
        "android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png",
        "android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png",
        "android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png",
        "android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png",
        
        # iOS icons
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-50x50@1x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-50x50@2x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-57x57@1x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-57x57@2x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-72x72@1x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-72x72@2x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png",
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png",
        
        # iOS splash screen
        "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png",
        "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png",
        "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png",
        
        # Web icons
        "web/icons/Icon-192.png",
        "web/icons/Icon-512.png",
        "web/icons/Icon-maskable-192.png",
        "web/icons/Icon-maskable-512.png",
        
        # Main assets
        "assets/icons/app_icon.png",
        "assets/images/Can Can [Logo].png",
    ]
    
    print("Removing 'Can Can' text from images...")
    print("=" * 60)
    
    success_count = 0
    fail_count = 0
    
    for image_file in image_files:
        if os.path.exists(image_file):
            if remove_text_from_image(image_file):
                success_count += 1
            else:
                fail_count += 1
        else:
            print(f"⊘ File not found: {image_file}")
            fail_count += 1
    
    print("=" * 60)
    print(f"Complete: {success_count} processed, {fail_count} failed/not found")
    
    return 0 if fail_count == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
