# Yolov8nDemo
## Guide for converting Yolov8* models to CoreML object

Install virtualenv (if not already installed):
```
➜  pip install virtualenv
```
Create a virtual environment using venv:
```
➜  python3 -m venv env
```
Activate the virtual environment:
```
➜  source env/bin/activate
```
Install required utilities for model conversion:
```
➜  pip3 install сoremltools
➜  pip3 install ultralytics
```
Download required yolov8 model:
 I’ve downloaded one simple model from the ultralytics main page https://github.com/ultralytics/ultralytics
YOLOv8n
Created python script file named convert.py:
```
➜  view convert.py
---
	from ultralytics import YOLO
	model=YOLO(r'/Users/User/yolo8/yolov8n.pt')
	model.export(format='coreml',nms=True)
---
```
Add required permissions and run freshly created script: 
```
➜  Chmod +x convert.py
➜  Pyton3 convert.py

Ultralytics YOLOv8.1.8 🚀 Python-3.11.6 torch-2.2.0 CPU (Apple M1)
YOLOv8n summary (fused): 168 layers, 3151904 parameters, 0 gradients, 8.7 GFLOPs
PyTorch: starting from '/Users/User/yolo8/yolov8n.pt' with input shape (1, 3, 640, 640) BCHW and output shape(s) (1, 84, 8400) (6.2 MB)
Torch version 2.2.0 has not been tested with coremltools. You may run into unexpected errors. Torch 2.1.0 is the most recent version that has been tested.
CoreML: starting export with coremltools 7.1...
Tuple detected at graph output. This will be flattened in the converted model.
Converting PyTorch Frontend ==> MIL Ops: 100%|███████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████▌| 523/525 [00:00<00:00, 11500.82 ops/s]
Running MIL frontend_pytorch pipeline: 100%|█████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 5/5 [00:00<00:00, 686.80 passes/s]
Running MIL default pipeline: 100%|████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 71/71 [00:00<00:00, 106.13 passes/s]
Running MIL backend_mlprogram pipeline: 100%|██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 12/12 [00:00<00:00, 918.65 passes/s]
CoreML Pipeline: starting pipeline with coremltools 7.1...
CoreML Pipeline: pipeline success
CoreML: export success ✅ 23.4s, saved as '/Users/User/yolo8/yolov8n.mlpackage' (6.2 MB)
Export complete (23.7s)
Results saved to /Users/Dmitrii/yolo8
Predict:         yolo predict task=detect model=/Users/User/yolo8/yolov8n.mlpackage imgsz=640
Validate:        yolo val task=detect model=/Users/User/yolo8/yolov8n.mlpackage imgsz=640 data=coco.yaml
Visualize:       https://netron.app
```
As a result we have following file `yolov8n.mlpackage`:
```
➜  yolo8 ls -ltrh
total 12776
-rw-r--r--@ 1 User  staff   6.2M Feb  2 19:04 yolov8n.pt
-rwxr-xr-x@ 1 User  staff   117B Feb  5 11:50 convert.py
drwxr-xr-x@ 4 User  staff   128B Feb  5 12:00 yolov8n.mlpackage
```
