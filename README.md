# Overview

This contains a demo of techniques to recognize Nutrition Fact labels in images.

Three techniques are applied:
- **Object detection**: YOLO model trained to put a bounding box around nutrition labels
- **Image classification**: CreateML model trained to say if the image as a whole contains or doesn't contain a nutrition label
- **Text recognition / OCR**: iOS built-in text recognizer to check for terms we'd expect in a nutrition label

## Conclusions

The detection model is the most precise.
- Because it knows the exact label location, we can determine if the label is cut off or too small.
- However it has a 2MB model size to consider. It also is weak at angled labels (between 20-70 degrees), though we can likely train for this.

The classification model is smallest/fastest.
- The model size is 10KB.
- It is fast enough to run in real time (ie over a camera feed), where the detection takes a few hundred ms.
- It gives more false positives than detection.

Text recognition is a great compliment.
- It is a great preview of what a full LLM vision model may be able to see (eg is it too blurry?)
- It can add additional support for detecting if a label is cut off, if we are missing key terms

&nbsp;

# Training Approach

Iain has labeled ~200 training data (food package images). It's pulled from datasets on huggingface and the scripts are in this project.

YOLO V5 (via [google colab](https://colab.research.google.com/drive/1ercLQs1rCQbTgoLBCyqB4S9rajaGFfKt?usp=sharing)) was used to train the detection model. Images were labeled on RoboFlow.
- Note: Model had to be export to a format usable in iOS (see [file](2_convert_model.sh))

CreateML (on local mac) was used to train the classification model. Used Image Feature Print V2 with 50 iterations.

Model/weight outputs are in the iOS project.
