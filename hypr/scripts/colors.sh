#!/bin/bash

# Configuration files to update
FILES=(
    "$HOME/.config/hypr/colorscheme.conf"  # Cache file - must be first
    "$HOME/.config/fuzzel/colors.ini"
    "$HOME/.config/waybar/colors.css"
)

# Color names in order of preference
COLOR_NAMES=(
    "rosewater"
    "flamingo"
    "pink"
    "mauve"
    "red"
    "maroon"
    "peach"
    "yellow"
    "green"
    "teal"
    "sky"
    "sapphire"
    "blue"
    "lavender"
)

# Function to display help information
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Display or modify color information across theme files."
    echo ""
    echo "Options:"
    echo "  -n, --name       List all color names"
    echo "  -c, --code       List all color hex codes"
    echo "  -a, --accent     Show the current accent color (both name and code)"
    echo "  -a -n            Show only the name of the accent color"
    echo "  -a -c            Show only the hex code of the accent color"
    echo "  -s, --set NAME   Set accent color to specified name"
    echo "  -h, --help       Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --name        # Lists all color names"
    echo "  $0 --code        # Lists all hex codes"
    echo "  $0 --accent      # Shows the current accent color"
    echo "  $0 -s blue       # Sets accent color to blue in all files"
}

# Function to check if cache file exists
check_cache_file() {
    if [[ ! -f "${FILES[0]}" ]]; then
        echo "Error: Cache file not found: ${FILES[0]}"
        echo "Please make sure the configuration file exists before using this script."
        exit 1
    fi
}

# Function to get all color names from cache file
get_color_names() {
    local cache_file="${FILES[0]}"
    local colors=()
    
    # Read color names from cache file
    while IFS= read -r line; do
        if [[ "$line" =~ ^\$([a-zA-Z0-9_]+)[[:space:]]*=[[:space:]]*rgb ]]; then
            color_name="${BASH_REMATCH[1]}"
            # Skip 'accent' since it's not a real color
            if [[ "$color_name" != "accent" ]]; then
                colors+=("$color_name")
            fi
        fi
    done < "$cache_file"
    
    # Sort colors according to predefined order
    local sorted_colors=()
    
    # First add colors from our preferred list in order
    for pref_color in "${COLOR_NAMES[@]}"; do
        if [[ " ${colors[*]} " =~ " $pref_color " ]]; then
            sorted_colors+=("$pref_color")
        fi
    done
    
    # Then add any remaining colors alphabetically
    for color in $(printf '%s\n' "${colors[@]}" | sort); do
        if ! [[ " ${sorted_colors[*]} " =~ " $color " ]]; then
            sorted_colors+=("$color")
        fi
    done
    
    # Return the sorted color list
    printf '%s\n' "${sorted_colors[@]}"
}

# Function to get hex code for a color name from cache file
get_hex_code() {
    local color_name="$1"
    local cache_file="${FILES[0]}"
    
    # Get hex code from cache file using better regex
    if [[ "$color_name" == "accent" ]]; then
        # For accent, we need to get the referenced color first
        local accent_ref
        accent_ref=$(grep -E "^\\\$accent\s*=" "$cache_file" | sed -n 's/.*=\s*\$\([a-zA-Z0-9_]\+\).*/\1/p')
        if [[ -n "$accent_ref" ]]; then
            color_name="$accent_ref"
        else
            echo ""
            return
        fi
    fi
    
    # Extract the hex code using improved regex
    local hex_code
    hex_code=$(grep -E "^\\\$$color_name\s*=" "$cache_file" | sed -n 's/.*rgb(\([0-9A-Fa-f]\+\)).*/\1/p')
    
    echo "$hex_code"
}

# Function to get current accent color from cache file
get_accent_info() {
    local format="$1"  # Can be "name", "code", or "full"
    local cache_file="${FILES[0]}"
    
    # Get accent name from cache file with improved regex
    local accent_var
    accent_var=$(grep -E "^\\\$accent\s*=" "$cache_file" | sed -n 's/.*=\s*\$\([a-zA-Z0-9_]\+\).*/\1/p')
    
    if [[ -z "$accent_var" ]]; then
        accent_var="blue"  # Default
    fi
    
    # Get hex code for the accent color
    local accent_hex
    accent_hex=$(get_hex_code "$accent_var")
    
    if [[ -z "$accent_hex" ]]; then
        accent_hex="89B4FA"  # Default blue hex
    fi
    
    # Return based on format
    case "$format" in
        name)
            echo "$accent_var"
            ;;
        code)
            echo "$accent_hex"
            ;;
        *)
            echo "Current accent: $accent_var (#$accent_hex)"
            ;;
    esac
}

# Function to set accent color in all files
set_accent_color() {
    local color_name="$1"
    local cache_file="${FILES[0]}"
    
    # Check if color exists in cache file
    if ! grep -q "^\$$color_name\s*=" "$cache_file"; then
        echo "Error: Color '$color_name' not defined in $cache_file"
        echo "Available colors:"
        get_color_names
        exit 1
    fi
    
    # Get hex code from cache file
    local hex_code
    hex_code=$(get_hex_code "$color_name")
    
    if [[ -z "$hex_code" ]]; then
        echo "Error: Could not find hex code for color '$color_name'"
        exit 1
    fi
    
    # Update each file
    for file in "${FILES[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo "Warning: File not found: $file"
            continue
        fi
        
        case "${file##*.}" in
            conf)
                # For hypr/colorscheme.conf
                # Update the accent line
                if grep -q "^\$accent\s*=" "$file"; then
                    sed -i "s|^\$accent\s*=.*$|\$accent = \$$color_name|" "$file"
                else
                    echo "\$accent = \$$color_name" >> "$file"
                fi
                ;;
                
            css)
                # For waybar/colors.css
                local css_hex="#${hex_code,,}"  # Convert to lowercase for CSS
                
                # Update the accent line
                if grep -q "^@define-color accent #" "$file"; then
                    sed -i "s|^@define-color accent #.*$|@define-color accent ${css_hex};|" "$file"
                else
                    echo "@define-color accent ${css_hex};" >> "$file"
                fi
                ;;
                
            ini)
                # For fuzzel/colors.ini
                local ini_hex="${hex_code,,}ff"  # Lowercase + alpha channel
                
                # Create a temporary file
                local temp_file
                temp_file=$(mktemp)
                
                # Process the file
                local in_accents=false
                
                while IFS= read -r line; do
                    if [[ "$line" == "#ACCENTS" ]]; then
                        in_accents=true
                        echo "$line" >> "$temp_file"
                    elif [[ "$line" == "#END" ]]; then
                        in_accents=false
                        echo "$line" >> "$temp_file"
                    elif $in_accents; then
                        # Update colors in ACCENTS section
                        # if [[ "$line" =~ ^(selection|match|border)= ]]; then
                        #     key="${BASH_REMATCH[1]}"
                        #     echo "$key=$ini_hex" >> "$temp_file"
                        # else
                        #     echo "$line" >> "$temp_file"
                        # fi
                        key=(${line//=/ })
                        echo "$key=$ini_hex" >> "$temp_file"
                    else
                        # Other sections
                        if [[ "$line" =~ ^accent= ]]; then
                            echo "accent=$ini_hex" >> "$temp_file"
                        else
                            echo "$line" >> "$temp_file"
                        fi
                    fi
                done < "$file"
                
                # Replace original with temp file
                mv "$temp_file" "$file"
                ;;
        esac
        
        echo "Updated accent to $color_name in $file"
    done
    
    echo "Successfully updated accent color to $color_name (#$hex_code) across all configuration files"
}

sync_background() {
    local color_name="$1"
    pngDir="$HOME/.config/hypr/assets/cat_colored_backgrounds"
    bgDir="$HOME/.config/hypr/assets/background"
    ln -sf $pngDir/$color_name.png $bgDir/lockscreen.png
    ln -sf $pngDir/$color_name.png $bgDir/wallpaper.png
}

# Main script execution
check_cache_file

# Parse command line arguments
show_names=false
show_codes=false
show_accent=false
set_color=""
accent_format="full"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)
            if [[ "$show_accent" == true ]]; then
                accent_format="name"
            else
                show_names=true
            fi
            ;;
        -c|--code)
            if [[ "$show_accent" == true ]]; then
                accent_format="code"
            else
                show_codes=true
            fi
            ;;
        -a|--accent)
            show_accent=true
            ;;
        -s|--set)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --set requires a color name"
                show_help
                exit 1
            fi
            set_color="$2"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

# Execute requested functions
if [[ "$show_names" == true ]]; then
    get_color_names
fi

if [[ "$show_codes" == true ]]; then
    for color in $(get_color_names); do
        hex=$(get_hex_code "$color")
        if [[ -n "$hex" ]]; then
            echo "$color: $hex"
        fi
    done
fi

if [[ "$show_accent" == true ]]; then
    get_accent_info "$accent_format"
fi

if [[ -n "$set_color" ]]; then
    sync_background "$set_color"
    set_accent_color "$set_color"
fi

# If no action options were provided, show help
if [[ "$show_names" == false && "$show_codes" == false && "$show_accent" == false && -z "$set_color" ]]; then
    show_help
fi

exit 0
