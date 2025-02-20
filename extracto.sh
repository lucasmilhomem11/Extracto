#!/bin/bash

# Check if a file path is provided as an argument
if [ -z "$1" ]; then
    echo "Please provide a file path as an argument."
    exit 1
fi

# Path to the file you want to check and process (from command-line argument)
FILE_PATH="$1"
OUTPUT_DIR="$HOME/Downloads"
PASSWORD="$2"

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Function to attempt extraction
extract_file() {
    FILE_TYPE=$(file -b "$FILE_PATH")
    echo "Current file type: $FILE_TYPE"

    # If the file is gzipped, decompress it
    if [[ "$FILE_TYPE" == *"gzip compressed data"* ]]; then
        echo "Decompressing gzipped file..."
        gunzip -c "$FILE_PATH" > "$OUTPUT_DIR/$(basename "$FILE_PATH" .gz)"
        echo "Extraction successful: $OUTPUT_DIR"
        exit 0
    fi

    # If the file is a tar archive, extract it
    if [[ "$FILE_TYPE" == *"POSIX tar archive"* ]]; then
        echo "Extracting tar archive..."
        tar -xf "$FILE_PATH" -C "$OUTPUT_DIR"
        echo "Extraction successful: $OUTPUT_DIR"
        exit 0
    fi

    # If the file is a bzip2 compressed file, decompress it
    if [[ "$FILE_TYPE" == *"bzip2 compressed data"* ]]; then
        echo "Decompressing bzip2 file..."
        bunzip2 -c "$FILE_PATH" > "$OUTPUT_DIR/$(basename "$FILE_PATH" .bz2)"
        echo "Extraction successful: $OUTPUT_DIR"
        exit 0
    fi

    # If the file is a ZIP archive, attempt to extract using unzip and bsdtar
    if [[ "$FILE_TYPE" == *"Zip archive data"* ]]; then
        echo "ZIP archive detected. Attempting extraction..."

        # Check if a password is needed
        unzip -t "$FILE_PATH" 2>&1 | grep -q "incorrect password"
        if [ $? -eq 0 ]; then
            if [ -z "$PASSWORD" ]; then
                read -s -p "Enter password for ZIP file: " PASSWORD
                echo
            fi
        fi

        # Try extracting with unzip
        if unzip -P "$PASSWORD" "$FILE_PATH" -d "$OUTPUT_DIR"; then
            echo "Extraction successful: $OUTPUT_DIR"
            exit 0
        else
            echo "unzip failed. Trying bsdtar...Wait a few minutes, depending on the file size it may take a little..."
            if bsdtar -xvf "$FILE_PATH" --passphrase "$PASSWORD" -C "$OUTPUT_DIR"; then
                echo "Extraction successful: $OUTPUT_DIR"
                exit 0
            else
                echo "Extraction failed. Check file format or if file requires a password."
                exit 1
            fi
        fi
    fi

    echo "Unknown or unsupported file type: $FILE_TYPE. Exiting."
    exit 1
}

# Call extraction function
extract_file
