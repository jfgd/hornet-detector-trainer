

SCRIPTS_PATH=scripts

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

# Proto python out
pyout:
	mkdir -p $@
pyout/object_detection: pyout models
	cd models/research && protoc object_detection/protos/*.proto --python_out=../../$<

# Record files
images/test.record: images/test_labels.csv models
	PYTHONPATH=$PYTHONPATH:models/research/slim/ ./generate_tfrecord.py --csv_input=$<  --output_path=$@  --image_dir=images/test
images/train.record: images/train_labels.csv models
	PYTHONPATH=$PYTHONPATH:models/research/slim/ ./generate_tfrecord.py --csv_input=$<  --output_path=$@ --image_dir=images/train

record: images/test.record images/train.record

.PHONY: default csv record
