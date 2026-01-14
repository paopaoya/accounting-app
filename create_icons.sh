#!/bin/bash

# 创建应用图标的脚本
# 这个脚本会生成简单的图标文件

mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

# 创建简单的 PNG 图标（使用 ImageMagick 如果可用）
# 这里我们创建一个简单的 SVG 转换脚本

# 由于没有 ImageMagick，我们创建一个说明文件
cat > android/app/src/main/res/mipmap-hdpi/README.txt << 'EOF'
此目录需要包含 ic_launcher.png (72x72)
可以使用在线工具生成：https://icon.kitchen/
或使用 Android Studio 的 Image Asset Studio
EOF

cat > android/app/src/main/res/mipmap-mdpi/README.txt << 'EOF'
此目录需要包含 ic_launcher.png (48x48)
可以使用在线工具生成：https://icon.kitchen/
或使用 Android Studio 的 Image Asset Studio
EOF

cat > android/app/src/main/res/mipmap-xhdpi/README.txt << 'EOF'
此目录需要包含 ic_launcher.png (96x96)
可以使用在线工具生成：https://icon.kitchen/
或使用 Android Studio 的 Image Asset Studio
EOF

cat > android/app/src/main/res/mipmap-xxhdpi/README.txt << 'EOF'
此目录需要包含 ic_launcher.png (144x144)
可以使用在线工具生成：https://icon.kitchen/
或使用 Android Studio 的 Image Asset Studio
EOF

cat > android/app/src/main/res/mipmap-xxxhdpi/README.txt << 'EOF'
此目录需要包含 ic_launcher.png (192x192)
可以使用在线工具生成：https://icon.kitchen/
或使用 Android Studio 的 Image Asset Studio
EOF

echo "图标目录已创建。请使用以下方法之一添加图标："
echo "1. 访问 https://icon.kitchen/ 生成图标"
echo "2. 使用 Android Studio 的 Image Asset Studio"
echo "3. 手动创建 PNG 文件并放置到相应目录"