#!/bin/bash

# Function to display help information
show_help() {
    echo "Usage: $0 [OPTIONS] [FILES]"
    echo "Display or modify color information from color configuration files."
    echo ""
    echo "Options:"
    echo "  -n, --name             List all color names"
    echo "  -c, --code             List all color hex codes"
    echo "  -a, --accent           Show the current accent color (both name and code)"
    echo "  -a -n                  Show only the name of the accent color"
    echo "  -a -c                  Show only the hex code of the accent color"
    echo "  -s, --set NAME         Set accent color to specified name"
    echo "  -h, --help             Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --name colors.conf                # Lists all color names from colors.conf"
    echo "  $0 --code colors.conf                # Lists all hex codes from colors.conf"
    echo "  $0 --accent colors.conf              # Shows the current accent color"
    echo "  $0 -a -n colors.conf                 # Shows only the accent color name"
    echo "  $0 --set blue colors.conf theme.css  # Sets accent color to blue in both files"
}

# Function to list all color names from a file
list_color_names() {
    local file=$1
    
    if [[ "$file" == *.conf ]]; then
        grep -E '^\$[a-z0-9]+\s=' "$file" | cut -d'=' -f1 | grep -v "accent" | sed 's/\$//'
    elif [[ "$file" == *.css ]]; then
        grep -E '^@define-color [a-z0-9]+ #' "$file" | awk '{print $2}' | grep -v "accent"
    else
        echo "Unsupported file type: $file"
        return 1
    fi
}

# Function to list all color hex codes from a file
list_color_codes() {
    local file=$1
    
    if [[ "$file" == *.conf ]]; then
        grep -E '^\$[a-z0-9]+\s=' "$file" | grep -v "accent" | sed 's/.*rgb(\([A-Za-z0-9]*\)).*/\1/'
    elif [[ "$file" == *.css ]]; then
        grep -E '^@define-color [a-z0-9]+ #' "$file" | grep -v "accent" | awk '{print $3}' | sed 's/#//'
    else
        echo "Unsupported file type: $file"
        return 1
    fi
}

# Function to get accent information from a file
get_accent_info() {
    local format=$1
    local file=$2
    
    if [[ "$file" == *.conf ]]; then
        accent_line=$(grep '^\$accent\s=' "$file")
        accent_var=$(echo "$accent_line" | cut -d'=' -f2 | tr -d ' ')
        
        # Get the color value that accent points to
        accent_color=$(grep "^$accent_var\s=" "$file" | sed 's/.*rgb(\([A-Za-z0-9]*\)).*/\1/')
        accent_name=$(echo "$accent_var" | sed 's/\$//')
    elif [[ "$file" == *.css ]]; then
        accent_line=$(grep '^@define-color accent #' "$file")
        accent_color=$(echo "$accent_line" | awk '{print $3}' | sed 's/#//')
        
        # Try to determine which color name corresponds to this value
        color_line=$(grep -F "#$accent_color" "$file" | grep -v "accent" | head -1)
        if [[ -n "$color_line" ]]; then
            accent_name=$(echo "$color_line" | awk '{print $2}')
        else
            accent_name="custom"
        fi
    else
        echo "Unsupported file type: $file"
        return 1
    fi
    
    # Return based on the requested format
    if [[ "$format" == "name" ]]; then
        echo "$accent_name"
    elif [[ "$format" == "code" ]]; then
        echo "$accent_color"
    else
        echo "Current accent in $file: $accent_name (#$accent_color)"
    fi
}

# Function to set accent color in a file
set_accent_color() {
    local color_name=$1
    local file=$2
    
    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi
    
    if [[ "$file" == *.conf ]]; then
        # Check if color exists
        if ! grep -q "^\$$color_name\s=" "$file"; then
            echo "Color '$color_name' not found in $file"
            return 1
        fi
        
        # Update the accent line
        sed -i "s/^\$accent\s=.*$/\$accent = \$$color_name/" "$file"
        echo "Updated accent to $color_name in $file"
    elif [[ "$file" == *.css ]]; then
        # Find the hex code for the specified color
        color_line=$(grep -E "^@define-color $color_name #" "$file")
        
        if [[ -z "$color_line" ]]; then
            echo "Color '$color_name' not found in $file"
            return 1
        fi
        
        hex_code=$(echo "$color_line" | awk '{print $3}')
        
        # Update the accent line
        sed -i "s/^@define-color accent #.*$/@define-color accent $hex_code/" "$file"
        echo "Updated accent to $color_name ($hex_code) in $file"
    else
        echo "Unsupported file type: $file"
        return 1
    fi
}

# Parse command line arguments
show_names=false
show_codes=false
show_accent=false
set_color=""
accent_format="full"
files=()

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
        -*)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            # Add to files array if it's a file
            if [[ -f "$1" ]]; then
                files+=("$1")
            else
                echo "File not found: $1"
                exit 1
            fi
            ;;
    esac
    shift
done

# Check if we have files to process
if [[ ${#files[@]} -eq 0 ]]; then
    echo "Error: No files specified"
    show_help
    exit 1
fi

# Execute requested functions for each file
for file in "${files[@]}"; do
    if [[ "$show_names" == true ]]; then
        echo "Color names in $file:"
        list_color_names "$file"
        echo ""
    fi

    if [[ "$show_codes" == true ]]; then
        echo "Color codes in $file:"
        list_color_codes "$file"
        echo ""
    fi

    if [[ "$show_accent" == true ]]; then
        get_accent_info "$accent_format" "$file"
    fi

    if [[ -n "$set_color" ]]; then
        set_accent_color "$set_color" "$file"
    fi
done

# If no action options were provided, show help
if [[ "$show_names" == false && "$show_codes" == false && "$show_accent" == false && -z "$set_color" ]]; then
    show_help
fi

exit 0
