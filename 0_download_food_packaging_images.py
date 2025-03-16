from datasets import load_dataset
import os
import requests
from tqdm import tqdm
import concurrent.futures

SUBFOLDER = "images/packaging"

# Load the dataset
# (Note this caches a ~5-10GB file in your computer's ~/.cache/huggingface/datasets directory)
# Can go there and do `du -sh` to see the size
dataset = load_dataset("openfoodfacts/product-database")

# Create a directory to save the images
os.makedirs(SUBFOLDER, exist_ok=True)

def download_image(item):
    filetype = "jpg"
    
    # Format the image URL correctly according to Open Food Facts structure
    # Pad the barcode to 13 digits if needed
    image_id = item["code"]
    padded_code = image_id.zfill(13)
    
    # Split the barcode into folder structure: xxx/xxx/xxx/xxxx
    folder_path = f"{padded_code[:3]}/{padded_code[3:6]}/{padded_code[6:9]}/{padded_code[9:]}"
    
    # Use the first image from the images field
    if "images" in item and len(item["images"]) > 0:
        # Find image with key "1" if available
        image_key = None
        for img in item["images"]:
            if img.get("key") == "1":
                image_key = "1"
                break
        
        # If no image with key "1", use the first image's key
        if image_key is None and len(item["images"]) > 0:
            image_key = item["images"][0].get("key")
            
        if image_key:
            image_url = f"https://images.openfoodfacts.org/images/products/{folder_path}/{image_key}.{filetype}"
        else:
            return f"Skipped {image_id} (no valid image key)"
    else:
        return f"Skipped {image_id} (no image available)"
    
    filepath = f"{SUBFOLDER}/{image_id}.{filetype}"
    
    # Skip if already downloaded
    if os.path.exists(filepath):
        return f"Skipped {image_id} (already exists)"
    
    try:
        response = requests.get(image_url, timeout=10)
        if response.status_code == 200:
            with open(filepath, "wb") as f:
                f.write(response.content)
            return f"Downloaded {image_id}"
        else:
            return f"Failed to download {image_id}: HTTP {response.status_code}"
    except Exception as e:
        return f"Error downloading {image_id}: {str(e)}"

# Select and filter data
food_dataset = dataset["food"]

# Select only the columns we need and subset of data given there are millions of rows
food_dataset = food_dataset.select_columns(["code", "images", "countries_tags"]).select(range(100000))

# Filter for Canadian products and products with images
filtered_dataset = food_dataset.filter(
    lambda x: (
        ("en:canada" in (x.get("countries_tags") or []) or "fr:canada" in (x.get("countries_tags") or [])) and 
        len(x.get("images", [])) > 0
    )
)

# Put limit on rows
filtered_dataset = filtered_dataset.select(range(500))

# Download images in parallel
print(f"Found {len(filtered_dataset)} Canadian products with images")
print(f"Downloading images...")
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
    results = list(tqdm(
        executor.map(download_image, filtered_dataset), 
        total=len(filtered_dataset)
    ))

# Count successes and failures
successes = sum(1 for r in results if r.startswith("Downloaded"))
print(f"Successfully downloaded {successes} images")
print(f"Total images processed: {len(results)}")
