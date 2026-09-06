#!/bin/bash

# Path to the file where URLs will be stored
url_file="userscript_urls.txt"

# Check if the file exists, create it if not
if [ ! -e "$url_file" ]; then
    touch "$url_file"
fi

# Function to add a URL to the list
add_url() {
    echo "$1" >> "$url_file"
    echo "URL added: $1"
}

# Function to download content from a URL and overwrite a file
download_url() {
    url="$1"
    filename="$2"

    echo $filename

    wget -O "$filename" "$url"
}

download_all_urls() {
    while IFS= read -r url; do
        filename="${url##*/}"  # Extract filename from URL
        download_url "$url" ./greasemonkey/"$filename"
    done < "$url_file"
}

# Main menu loop
while true; do
    echo "Select an option:"
    echo "1. Add URL"
    echo "2. View URLs"
    echo "3. Download from URL"
    echo "4. Download from all URLs"
    echo "5. Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            read -p "Enter the URL to add: " new_url
            add_url "$new_url"
            ;;
        2)
            echo "List of URLs:"
            cat "$url_file"
            ;;
        3)
            read -p "Enter the URL to download: " download_url
            read -p "Enter the filename to save as: " save_as
            download_url "$download_url" "$save_as"
            ;;
        4)
            download_all_urls
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select a valid option."
            ;;
    esac
done
