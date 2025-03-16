### Trained in Colab Notebook

https://colab.research.google.com/drive/1ercLQs1rCQbTgoLBCyqB4S9rajaGFfKt?usp=sharing

Download output weights and put in /models/yolov5nano.pt

### Instructions below if you want to do local

1. Cloned YOLO V5 in a sibling folder to this repo
```bash
cd ..
git clone https://github.com/ultralytics/yolov5
cd yolov5
pip install -r requirements.txt
```

2. Created YOLO format folders
- Contains images sized down to 640px max dimentions
- Contains rectangle label files

3. Made a yaml in this project defining these details
See 1_train_model_local.yaml

4. Execute from yolov5 folder (to use pip packages installed there)
```bash
cd yolov5
./../LabelClassifier/1_train_model_local.sh
```
- Might need to do `chmod +x 1_train_model_local.sh` to call file