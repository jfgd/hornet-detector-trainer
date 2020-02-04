

SCRIPTS_PATH=scripts

default:
	@echo "Hornet Killer Makefile"

images/test_labels.csv: $(wildcard images/test/*.xml)
	$(SCRIPTS_PATH)/xml_to_csv.py -i images/test -o $@
images/train_labels.csv: $(wildcard images/train/*.xml)
	$(SCRIPTS_PATH)/xml_to_csv.py -i images/train -o $@

csv: images/test_labels.csv images/train_labels.csv

images/test.record: images/test_labels.csv
	./generate_tfrecord.py --csv_input=$^  --output_path=$@  --image_dir=images/test
images/train.record: images/train_labels.csv
	./generate_tfrecord.py --csv_input=$^  --output_path=$@ --image_dir=images/train


.PHONY: default csv
