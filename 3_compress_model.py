

import coremltools as ct
from ultralytics import YOLO

MODEL_RUN = "yolov5nano"

# Load trained YOLO model and convert to CoreML
model = YOLO(f'models/{MODEL_RUN}.pt')
model.export(format='coreml', nms=True, int8=True, imgsz=640)

# Load CoreML model
coreml_model = ct.models.MLModel(f'models/{MODEL_RUN}.mlmodel')

# Apply quantization
model_quantized = ct.models.neural_network.quantization_utils.quantize_weights(coreml_model, nbits=8)

# Save the compressed model
model_quantized.save(f"models/{MODEL_RUN}_compressed.mlmodel")
