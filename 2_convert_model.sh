# Need to git clone https://github.com/ultralytics/yolov5
# Do it as a sibling folder to this repo

# Run `pip install -r requirements.txt` there

# May need to run `chmod +x 2_convert_model.sh` to call this file

python ./../yolov5/export.py --weights models/yolov5nano.pt --include coreml --imgsz 640 640 --int8 

# Other options to consider:
# --nms | This will create a CoreML pipeline model with NMS built-in, which might be slightly larger but more convenient for deployment.
# remove --int8, add --half | While INT8 quantization provides smallest size, it may cause some accuracy loss. To balance size and accuracy, test both the INT8 and FP16 (half) versions of model.
