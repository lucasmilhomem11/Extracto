#!/bin/bash

# Check if a file path is provided as an argument
if [ -z "$1" ]; then
    echo "Please provide a file path as an argument."
    exit 1
fi

# Path to the file you want to check and process (from command-line argument)
FILE_PATH="$1"
OUTPUT_DIR="$HOME/downloads"
PASSWORD="$2"

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Function to attempt extraction
extract_file() {
    FILE_TYPE=$(file -b "$FILE_PATH")
    echo "Current file type: $FILE_TYPE"

    # Ensure the output directory exists
    mkdir -p "$OUTPUT_DIR"

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

    # If the file is a ZIP archive, attempt extraction using both unzip and 7z
    if [[ "$FILE_TYPE" == *"Zip archive data"* ]]; then
        echo "ZIP archive detected. Attempting extraction..."

        # Check if a password is needed
        if [[ -z "$PASSWORD" ]]; then
            echo "This ZIP file requires a password."
            read -s -p "Enter password: " PASSWORD
            echo ""
        fi
        

        # Try extracting with unzip first
        echo "Trying unzip..."
        if [[ -n "$PASSWORD" ]]; then
            if unzip -P "$PASSWORD" "$FILE_PATH" -d "$OUTPUT_DIR"; then
                echo "Extraction successful with unzip: $OUTPUT_DIR"
                exit 0
            else
                echo "unzip failed. Trying 7z..."

                # Try extracting with 7z if unzip failed
                if 7z x -p"$PASSWORD" -o"$OUTPUT_DIR" "$FILE_PATH" -y; then
                    echo "Extraction successful with 7z: $OUTPUT_DIR"
                    exit 0
                else
                    echo "7z extraction failed. Check file format or password."
                    exit 1
                fi
            fi
        else
            if unzip "$FILE_PATH" -d "$OUTPUT_DIR"; then
                echo "Extraction successful with unzip: $OUTPUT_DIR"
                exit 0
            else
                echo "unzip failed. Trying 7z..."

                # Try extracting with 7z if unzip failed
                if 7z x -o"$OUTPUT_DIR" "$FILE_PATH" -y; then
                    echo "Extraction successful with 7z: $OUTPUT_DIR"
                    exit 0
                else
                    echo "7z extraction failed. Check file format or password."
                    exit 1
                fi
            fi
        fi
    fi

    # If the file is a 7-zip archive, extract using 7z
    if [[ "$FILE_TYPE" == *"7-zip archive"* ]]; then
        echo "7-zip archive detected. Attempting extraction..."

        # Ensure password is set if required
        if [[ -z "$PASSWORD" ]]; then
            echo "This 7z file may require a password."
            read -s -p "Enter password: " PASSWORD
            echo ""
        fi

        # Try extracting with 7z
        if 7z x -p"$PASSWORD" -o"$OUTPUT_DIR" "$FILE_PATH" -y; then
            echo "Extraction successful: $OUTPUT_DIR"
            exit 0
        else
            echo "7z extraction failed. Check file format or password."
            exit 1
        fi
    fi

    echo "Unknown or unsupported file type: $FILE_TYPE. Exiting."
    exit 1
}

# Call extraction function
extract_file