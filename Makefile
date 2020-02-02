

SCRIPTS_PATH=scripts

default:
	@echo "Hornet Killer Makefile"

images/test_labels.csv:
	$(SCRIPTS_PATH)/xml_to_csv.py -i images/test -o $@
images/train_labels.csv:
	$(SCRIPTS_PATH)/xml_to_csv.py -i images/train -o $@

csv: images/test_labels.csv images/train_labels.csv

