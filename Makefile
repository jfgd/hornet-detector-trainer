

SCRIPTS_PATH=scripts
PYTHON_PATH=$$PYTHONPATH:models/research/:models/research/slim

# GPU accel
CUDA_LIB_PATH=/usr/local/cuda/extras/CUPTI/lib64
ifneq ("$(wildcard $(CUDA_LIB_PATH))","")
$(info "CUDA found")
LD_LIB=$$LD_LIBRARY_PATH:$(CUDA_PATH)
else
LD_LIB=$$LD_LIBRARY_PATH
endif

default:
	@echo "Hornet Killer Makefile"

# CSV files
images/test_labels.csv: $(wildcard images/test/*.xml)
	$(SCRIPTS_PATH)/xml_to_csv.py -i images/test -o $@
images/train_labels.csv: $(wildcard images/train/*.xml)
	$(SCRIPTS_PATH)/xml_to_csv.py -i images/train -o $@

csv: images/test_labels.csv images/train_labels.csv


# Tensorflow models submodule
models/research:
	git submodule update --init
models: models/research


# Proto compilation
proto: models
	cd models/research && protoc object_detection/protos/*.proto --python_out=.

# Record files
images/test.record: images/test_labels.csv models
	PYTHONPATH=$(PYTHON_PATH) ./generate_tfrecord.py --csv_input=$<  --output_path=$@  --image_dir=images/test
images/train.record: images/train_labels.csv models
	PYTHONPATH=$(PYTHON_PATH) ./generate_tfrecord.py --csv_input=$<  --output_path=$@ --image_dir=images/train

record: images/test.record images/train.record


faster_rcnn_inception_v2_coco_2018_01_28.tar.gz:
	wget http://download.tensorflow.org/models/object_detection/$@

faster_rcnn_inception_v2_coco_2018_01_28: faster_rcnn_inception_v2_coco_2018_01_28.tar.gz
	tar -xf $^
	touch $@ # For dependency tree

train_test: models proto
	PYTHONPATH=$(PYTHON_PATH) python3 models/research/object_detection/builders/model_builder_test.py

train: models proto images/test.record images/train.record faster_rcnn_inception_v2_coco_2018_01_28
	LD_LIBRARY_PATH=$(LD_LIB) PYTHONPATH=$(PYTHON_PATH) python3 models/research/object_detection/model_main.py \
			--pipeline_config_path=training/faster_rcnn_inception_v2_hornet.config \
			--model_dir=training --num_train_steps=50000 \
			--sample_1_of_n_eval_examples=1 --alsologtostderr

export-graph: models
	PYTHONPATH=$(PYTHON_PATH) python3 models/research/object_detection/export_inference_graph.py \
			--input_type image_tensor \
			--pipeline_config_path training/faster_rcnn_inception_v2_hornet.config \
			--trained_checkpoint_prefix training/model.ckpt-50000 \
			--output_directory trained-inference-graphs/faster_rcnn_inception_v2_hornet_$(shell date +%Y-%m-%d-%H-%M)


.PHONY: default csv models proto record train_test train export-graph
