

SCRIPTS_PATH=scripts
PYTHON_PATH=$$PYTHONPATH:models/research/:models/research/slim

default:
	@echo "Hornet Killer Makefile"

# CSV files
images/test_labels.csv: $(wildcard images/test/*.xml)
	$(SCRIPTS_PATH)/xml_to_csv.py -i images/test -o $@
images/train_labels.csv: $(wildcard images/train/*.xml)
	$(SCRIPTS_PATH)/xml_to_csv.py -i images/train -o $@

csv: images/test_labels.csv images/train_labels.csv


# Tensorflow models submodule
models:
	git submodule update --init

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

train_test: models proto
	PYTHONPATH=$(PYTHON_PATH) python3 models/research/object_detection/builders/model_builder_test.py

train: record models proto faster_rcnn_inception_v2_coco_2018_01_28
	PYTHONPATH=$(PYTHON_PATH) python3 models/research/object_detection/model_main.py \
			--pipeline_config_path=training/faster_rcnn_inception_v2_hornet.config \
			--model_dir=training --num_train_steps=50000 \
			--sample_1_of_n_eval_examples=1 --alsologtostderr

.PHONY: default csv proto record train_test train
