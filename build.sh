#!/bin/bash

# Get the specified architecture (default to arm64-v8a if not set)
ARCH=${1:-arm64-v8a}

# Download latest APK from GitLab releases
LATEST_RELEASE=$(curl -s https://gitlab.com/api/v4/projects/ironfox-oss%2FIronFox/releases | jq -r '.[0]')
APK_URL=$(echo "$LATEST_RELEASE" | jq -r '.assets.links[] | select(.name | endswith("'"-$ARCH.apk"'")) | .url')
wget -q "$APK_URL" -O latest.apk

# Download build tools
wget -q https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.11.1.jar -O apktool.jar
wget -q https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool
chmod +x apktool*

# Clean and patch
rm -rf patched patched_signed.apk
./apktool d latest.apk -o patched 
rm -rf patched/META-INF

# Apply patches
sed -i 's/<color name="fx_mobile_layer_color_1">.*/<color name="fx_mobile_layer_color_1">#ff000000<\/color>/g' patched/res/values-night/colors.xml
sed -i 's/<color name="fx_mobile_layer_color_2">.*/<color name="fx_mobile_layer_color_2">@color\/photonDarkGrey90<\/color>/g' patched/res/values-night/colors.xml
sed -i 's/ff1c1b22/ff000000/g' patched/smali_classes2/mozilla/components/ui/colors/PhotonColors.smali
sed -i 's/ff2b2a33/ff000000/g' patched/smali_classes2/mozilla/components/ui/colors/PhotonColors.smali
sed -i 's/ff42414d/ff15141a/g' patched/smali_classes2/mozilla/components/ui/colors/PhotonColors.smali
sed -i 's/ff52525e/ff15141a/g' patched/smali_classes2/mozilla/components/ui/colors/PhotonColors.smali

# Build and align
./apktool b patched -o patched.apk --use-aapt2
zipalign 4 patched.apk patched_signed.apk
rm -rf patched patched.apk