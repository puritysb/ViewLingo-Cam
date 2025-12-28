#!/bin/bash

# Generate all required iOS app icon sizes from 1024x1024 source
# Source: AppIcon-1024.png

SOURCE_DIR="/Users/puritysb/github/ViewTrans/ViewTrans/ViewLingo-Cam/Assets.xcassets/AppIcon.appiconset"
SOURCE_FILE="$SOURCE_DIR/AppIcon-1024.png"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source file $SOURCE_FILE not found!"
    exit 1
fi

echo "Generating iOS app icons from $SOURCE_FILE..."

# iPhone Notification 20pt
sips -z 40 40 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-20@2x.png"
sips -z 60 60 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-20@3x.png"

# iPhone Settings 29pt
sips -z 58 58 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-29@2x.png"
sips -z 87 87 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-29@3x.png"

# iPhone Spotlight 40pt
sips -z 80 80 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-40@2x.png"
sips -z 120 120 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-40@3x.png"

# iPhone App 60pt
sips -z 120 120 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-60@2x.png"
sips -z 180 180 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-60@3x.png"

# iPad Notification 20pt
sips -z 20 20 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-20.png"
sips -z 40 40 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-20@2x-ipad.png"

# iPad Settings 29pt
sips -z 29 29 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-29.png"
sips -z 58 58 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-29@2x-ipad.png"

# iPad Spotlight 40pt
sips -z 40 40 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-40.png"
sips -z 80 80 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-40@2x-ipad.png"

# iPad App 76pt
sips -z 76 76 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-76.png"
sips -z 152 152 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-76@2x.png"

# iPad Pro App 83.5pt
sips -z 167 167 "$SOURCE_FILE" --out "$SOURCE_DIR/AppIcon-83.5@2x.png"

echo "✅ All app icons generated successfully!"
echo "📍 Location: $SOURCE_DIR"
ls -la "$SOURCE_DIR"/*.png | wc -l
echo "icon files created"