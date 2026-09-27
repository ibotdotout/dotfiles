# Image Optmized Support jpg jpeg png
# brew install jpegoptim oxipng
MAX_SIZE=748576 #750kb

find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 |
while IFS= read -r -d '' f; do
    size=$(stat -f%z "$f")

    # Only process files > 1 MB
    if [ "$size" -le $MAX_SIZE ]; then
        continue
    fi

    echo "Processing: $f ($(du -h "$f" | cut -f1))"

    # Keep original
    [ -f "$f.old" ] || cp "$f" "$f.old"

    case "${f##*.}" in
        jpg|JPG|jpeg|JPEG)
            # JPEG compression
            jpegoptim --strip-all --max=85 "$f"

            if [ "$(stat -f%z "$f")" -gt $MAX_SIZE ]; then
                jpegoptim --strip-all --max=75 "$f"
            fi

            if [ "$(stat -f%z "$f")" -gt $MAX_SIZE ]; then
                sips --resampleHeightWidthMax 2000 "$f" --out "$f.tmp.jpg" >/dev/null &&
                mv "$f.tmp.jpg" "$f"

                jpegoptim --strip-all --max=80 "$f"
            fi
            ;;

        png|PNG)
            # Lossless PNG optimization
            oxipng -o 4 --strip safe "$f"

            # If still >1 MB, resize
            if [ "$(stat -f%z "$f")" -gt $MAX_SIZE ]; then
                sips --resampleHeightWidthMax 1600 "$f" --out "$f.tmp.png" >/dev/null &&
                mv "$f.tmp.png" "$f"

                oxipng -o 4 --strip safe "$f"
            fi
            ;;
    esac

    echo "     → $(du -h "$f" | cut -f1)"
done
