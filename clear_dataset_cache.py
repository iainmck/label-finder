from datasets.config import HF_DATASETS_CACHE, DOWNLOADED_DATASETS_PATH, EXTRACTED_DATASETS_PATH
import shutil
from pathlib import Path
import os

PREFIX_TO_CLEAR = "datasets--openfoodfacts"

# Helper function to clear only items with the specified prefix
def clear_items_with_prefix(directory, prefix):
    count = 0
    for item in directory.iterdir():
        if item.name.startswith(prefix):
            if item.is_dir():
                shutil.rmtree(str(item))
            else:
                item.unlink()
            count += 1
    return count

# Function to handle clearing process for a directory
def process_directory(directory_path, directory_description):
    directory = Path(directory_path)
    if directory.exists():
        print(f"About to clear items starting with '{PREFIX_TO_CLEAR}' in {directory_description} at: {directory}")
        confirm = input("Continue? (y/n): ")
        if confirm.lower() == 'y':
            count = clear_items_with_prefix(directory, PREFIX_TO_CLEAR)
            print(f"Cleared {count} items from {directory_description} at {directory}")
        else:
            print(f"Skipped clearing {directory_description}")

# Process each cache directory
process_directory(HF_DATASETS_CACHE, "datasets cache")
process_directory(DOWNLOADED_DATASETS_PATH, "downloads cache")
process_directory(EXTRACTED_DATASETS_PATH, "extracted files cache")
process_directory(Path(os.path.dirname(HF_DATASETS_CACHE)) / "hub", "Hugging Face Hub cache")
