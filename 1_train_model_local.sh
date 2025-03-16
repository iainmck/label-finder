python train.py \
  --img 640 --rect \
  --batch 16 --epochs 100 \
  --data ../LabelClassifier/1_train_model_local.yaml \
  --weights yolov5n.pt \
  --cfg models/yolov5n.yaml

# COMMENTS
# - 640 is image dimension
# - specify "rect" because images are not square
# - using Nano model which is smallest (to minimize iOS space)
# - NOT specifying "--device mps" to use GPU on M-chip mac because it's actually slower for this task