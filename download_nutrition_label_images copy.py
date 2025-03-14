from datasets import load_dataset, concatenate_datasets
import os
import requests
from tqdm import tqdm
import concurrent.futures

SUBFOLDER = "images/nutrition_labels"

# Load the dataset
dataset = load_dataset("openfoodfacts/nutrition-table-detection")

# Create a directory to save the images
os.makedirs(SUBFOLDER, exist_ok=True)

def download_image(item):
    image_id = item["image_id"]
    image_url = item["meta"]["image_url"]
    filetype = image_url.split(".")[-1]
    filename = f"{image_id}.{filetype}"
    
    # Skip if already downloaded
    if os.path.exists(filename):
        return f"Skipped {image_id} (already exists)"
    
    try:
        response = requests.get(image_url, timeout=10)
        if response.status_code == 200:
            with open(f"{SUBFOLDER}/{filename}", "wb") as f:
                f.write(response.content)
            return f"Downloaded {image_id}"
        else:
            return f"Failed to download {image_id}: HTTP {response.status_code}"
    except Exception as e:
        return f"Error downloading {image_id}: {str(e)}"

# Download images in parallel
# Use concatenate_datasets instead of + operator
combined_dataset = concatenate_datasets([dataset["train"], dataset["val"]])
print(f"Downloading {len(combined_dataset)} images...")
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
    results = list(tqdm(
        executor.map(download_image, combined_dataset), 
        total=len(combined_dataset)
    ))

# Count successes and failures
successes = sum(1 for r in results if r.startswith("Downloaded"))
print(f"Successfully downloaded {successes} images")
print(f"Total images processed: {len(results)}")
