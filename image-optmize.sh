#!/bin/bash

# Install:
# brew install jpegoptim oxipng webp

MAX_SIZE=148576
TARGET_SIZE=100000
ATTACHMENTS_DIR="Settings/Attachments"

# ----------------------------------------
# Create WebP
# Stop immediately when <= TARGET_SIZE
# ----------------------------------------

make_webp() {
    input="$1"
    output="$2"
    original_size="$3"

    tmp="${input}.tmp.webp"
    resize_tmp="${input}.resize.webp"
    best="${input}.best.webp"
    best_size="$original_size"

    rm -f "$tmp" "$resize_tmp" "$best"

    for dimension in original 2000 1600 1400 1200 1000 800; do

        if [ "$dimension" = "original" ]; then
            source="$input"
        else
            sips --resampleHeightWidthMax "$dimension" \
                "$input" \
                --out "$resize_tmp" >/dev/null 2>&1 || continue
            source="$resize_tmp"
        fi

        for q in 90 82 75 68 60 52 45 38 32 26; do

            cwebp -quiet -q "$q" "$source" \
                -o "$tmp" 2>/dev/null || continue

            size=$(stat -f%z "$tmp")

            # Keep smallest result found
            if [ "$size" -lt "$best_size" ]; then
                cp "$tmp" "$best"
                best_size="$size"
            fi

            # Target reached → stop immediately
            if [ "$size" -le "$TARGET_SIZE" ]; then
                mv "$tmp" "$output"
                rm -f "$best" "$resize_tmp"

                echo "  → WebP: $(du -h "$output" | cut -f1)"
                echo "  → Target reached: <= 100 KB"

                return 0
            fi
        done

        rm -f "$resize_tmp"
    done

    rm -f "$tmp"

    # Target not reached, but keep smallest result
    if [ -f "$best" ] && [ "$best_size" -lt "$original_size" ]; then
        mv "$best" "$output"

        echo "  → WebP: $(du -h "$output" | cut -f1)"
        echo "  → Target not reached, but smaller than original"

        return 0
    fi

    rm -f "$best"
    return 1
}


# ----------------------------------------
# Find Markdown files
# ----------------------------------------

find . -type f -name "*.md" -print0 |
while IFS= read -r -d '' note; do

    grep -oE '!\[\[[^]]+\.(jpg|jpeg|png|webp|JPG|JPEG|PNG|WEBP)(\|[^]]+)?\]\]' "$note" |
    while IFS= read -r link; do

        image="${link#![[}"
        image="${image%%|*}"
        image="${image%]]}"

        case "$image" in
            Settings/Attachments/*)
                image_path="$image"
                ;;
            *)
                image_path="$ATTACHMENTS_DIR/$image"
                ;;
        esac

        image_base="${image_path%.*}"

        for ext in jpg jpeg png webp JPG JPEG PNG WEBP; do
            candidate="${image_base}.${ext}"

            if [ -f "$candidate" ]; then
                image_path="$candidate"
                break
            fi
        done

        [ -n "$image_path" ] || continue

        case "$image_path" in
            *.old.*) continue ;;
        esac

        original_size=$(stat -f%z "$image_path")

        [ "$original_size" -gt "$MAX_SIZE" ] || continue

        ext="${image_path##*.}"
        base="${image_path%.*}"
        backup="${image_path}.old.${ext}"

        echo "========================================"
        echo "file: $note"
        echo "Processing: $image_path"
        echo "Original: $(du -h "$image_path" | cut -f1)"

        # ----------------------------------------
        # Backup
        # ----------------------------------------

        [ -f "$backup" ] || cp "$image_path" "$backup"

        # ----------------------------------------
        # Optimize source
        # ----------------------------------------

        case "$ext" in

            jpg|JPG|jpeg|JPEG)
                jpegoptim \
                    --strip-all \
                    --max=85 \
                    "$image_path" >/dev/null 2>&1
                ;;

            png|PNG)
                oxipng \
                    -o 4 \
                    --strip safe \
                    "$image_path" >/dev/null 2>&1
                ;;

            webp|WEBP)
                ;;
                
            *)
                echo "  → Unsupported format"
                echo
                continue
                ;;
        esac

        # ----------------------------------------
        # Existing WebP
        # ----------------------------------------

        if [[ "$ext" == "webp" || "$ext" == "WEBP" ]]; then

            tmp_webp="${image_path}.optimized.webp"

            if make_webp \
                "$image_path" \
                "$tmp_webp" \
                "$original_size"; then

                mv "$tmp_webp" "$image_path"
                echo "  → Optimized existing WebP"

            else
                rm -f "$tmp_webp"
                echo "  → No smaller WebP found"
            fi

            echo
            continue
        fi

        # ----------------------------------------
        # JPG / PNG → WebP
        # ----------------------------------------

        webp="${base}.webp"

        if ! make_webp \
            "$image_path" \
            "$webp" \
            "$original_size"; then

            rm -f "$webp"

            echo "  → No smaller WebP found"
            echo
            continue
        fi

        # ----------------------------------------
        # Update Obsidian link
        # ----------------------------------------

        old_name=$(basename "$image_path")
        new_name=$(basename "$webp")

        sed -i '' "s/${old_name}/${new_name}/g" "$note"

        rm -f "$image_path"

        echo "  → $old_name → $new_name"
        echo
        rm -f "$backup"

    done
done