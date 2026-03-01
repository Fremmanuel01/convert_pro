#!/bin/bash
set -e

echo "Fixing ImageMagick PDF security policy..."

# Sometimes ImageMagick is installed in /etc/ImageMagick-6/
if [ -f "/etc/ImageMagick-6/policy.xml" ]; then
  sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read | write" pattern="PDF" \/>/g' /etc/ImageMagick-6/policy.xml
  echo "Updated /etc/ImageMagick-6/policy.xml"
fi

# Sometimes ImageMagick is installed in /etc/ImageMagick/
if [ -f "/etc/ImageMagick/policy.xml" ]; then
  sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read | write" pattern="PDF" \/>/g' /etc/ImageMagick/policy.xml
  echo "Updated /etc/ImageMagick/policy.xml"
fi

echo "ImageMagick policy fix complete."
