

SCRIPTS_PATH=scripts
PYTHON_PATH=$$PYTHONPATH:models/research/:models/research/slim
EXPORT_GRAPH_PATH=graphs

# Default model config
CONFIG ?= ssdlite_mobilenet_v2_hornet.config

# If GPU/Cuda acceleration found enable it
CUDA_LIB_PATH=/usr/local/cuda/extras/CUPTI/lib64
ifneq ("$(wildcard $(CUDA_LIB_PATH))","")
$(info "CUDA found")
LD_LIB=$$LD_LIBRARY_PATH:$(CUDA_PATH)
else
LD_LIB=$$LD_LIBRARY_PATH
endif

help:
	@echo "Hornet Detector Tensorflow Model Trainer "
	@echo ""
	@echo "train:\tTrain tensorflow model"
	@echo "export-graph:\tExport inference graph"
	@echo "export-tflite-graph:\tExport tflite inference graph"

# CSV files
images/test_labels.csv: $(wildcard images/test/*.xml)
	$(SCRIPTS_PATH)/xml_to_csv.py -i images/test -o $@
images/train_labels.csv: $(wildcard images/train/*.xml)
	$(SCRIPTS_PATH)/xml_to_csv.py -i images/train -o $@

csv: images/test_labels.csv images/train_labels.csv


# Tensorflow models submodule
models/research:
	git submodule update --init models
models: models/research


# Proto compilation
proto: models
	cd models/research && protoc object_detection/protos/*.proto --python_out=.

# Generate Record files
images/test.record: images/test_labels.csv models
	PYTHONPATH=$(PYTHON_PATH) ./scripts/generate_tfrecord.py \
			--csv_input=$< --output_path=$@  --image_dir=images/test
images/train.record: images/train_labels.csv models
	PYTHONPATH=$(PYTHON_PATH) ./scripts/generate_tfrecord.py \
			--csv_input=$< --output_path=$@ --image_dir=images/train

record: images/test.record images/train.record


# Detection Model Zoo
faster_%.tar.gz ssd_%.tar.gz ssdlite_%.tar.gz:
	wget http://download.tensorflow.org/models/object_detection/$@

# Uncompress model archive on-demand
%_model: %.tar.gz
	tar -xf $^ --one-top-level=$@ --strip-components 1
	touch $@ # For dependency tree


# Test trainer (do nothing)
train_test: models proto
	PYTHONPATH=$(PYTHON_PATH) python3 models/research/object_detection/builders/model_builder_test.py

# Default model to train
train: train_ssdmbnetv2

# Train a model based on ssdlite_mobilenet_v2_coco_2018_05_09
train_ssdmbnetv2: models proto images/test.record images/train.record ssdlite_mobilenet_v2_coco_2018_05_09_model
	LD_LIBRARY_PATH=$(LD_LIB) PYTHONPATH=$(PYTHON_PATH) python3 models/research/object_detection/model_main.py \
			--pipeline_config_path=training/ssdlite_mobilenet_v2_hornet.config \
			--model_dir=training --num_train_steps=50000 \
			--sample_1_of_n_eval_examples=1 --alsologtostderr

# Train a model based on ssd_mobilenet_v1_coco_2018_01_28
train_ssdmbnetv1: models proto images/test.record images/train.record ssd_mobilenet_v1_coco_2018_01_28_model
	LD_LIBRARY_PATH=$(LD_LIB) PYTHONPATH=$(PYTHON_PATH) python3 models/research/object_detection/model_main.py \
			--pipeline_config_path=training/ssd_mobilenet_v1_hornet.config \
			--model_dir=training --num_train_steps=50000 \
			--sample_1_of_n_eval_examples=1 --alsologtostderr

# Train a model based on faster_rcnn_inception_v2_coco_2018_01_28
train_frcnnv2: models proto images/test.record images/train.record faster_rcnn_inception_v2_coco_2018_01_28_model
	LD_LIBRARY_PATH=$(LD_LIB) PYTHONPATH=$(PYTHON_PATH) python3 models/research/object_detection/model_main.py \
			--pipeline_config_path=training/faster_rcnn_inception_v2_hornet.config \
			--model_dir=training --num_train_steps=50000 \
			--sample_1_of_n_eval_examples=1 --alsologtostderr

# Run Tensorboard web server
board:
	PYTHONPATH=$(PYTHON_PATH) tensorboard --logdir training

export-graph: models
	@echo "Exporting graph for $(CONFIG)"
	PYTHONPATH=$(PYTHON_PATH) python3 models/research/object_detection/export_inference_graph.py \
			--input_type image_tensor \
			--pipeline_config_path training/$(CONFIG) \
			--trained_checkpoint_prefix training/model.ckpt-50000 \
			--output_directory $(EXPORT_GRAPH_PATH)/$(basename $(CONFIG))_$(shell date +%Y-%m-%d-%H-%M)

export-tflite-graph: models
	@echo "Exporting tflite graph for $(CONFIG)"
	PYTHONPATH=$(PYTHON_PATH) python3 models/research/object_detection/export_tflite_ssd_graph.py \
		--pipeline_config_path=training/$(CONFIG) \
		--trained_checkpoint_prefix=training/model.ckpt-50000 \
		--add_postprocessing_op=true \
		--output_directory=$(EXPORT_GRAPH_PATH)/$(basename $(CONFIG))_tflite_$(shell date +%Y-%m-%d-%H-%M)


# Label images with labelImg
labelImg/labelImg.py:
	git submodule update --init labelImg
labelImg: labelImg/labelImg.py

labelImg/libs/resources.py: labelImg
	make -C labelImg qt5py3

# Run labeImg
label: labelImg/libs/resources.py
	python3 labelImg/labelImg.py images/



.PHONY: help csv models proto record train_test train train_ssdmbnetv2 train_ssdmbnetv1 train_frcnnv2 export-graph-classic export-graph board label
