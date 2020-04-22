# Hornet Detector Tensorflow Model Trainer

Train a tensorflow model to detect hornets and bees in pictures


## Dependencies

Some dependencies are listed in file `toinstall.sourceme.sh`.

```
source scripts/toinstall.sourceme.sh
```

## Annotate new images

### Automatic annotation from an existing model

The last iteration of the model can be used to annotate new image
files, therefore the effort to annotate the images can be
significantly reduced. After the automatic annotation you just need to
browse the generated annotations and fix them if necessary.

For this, the script `auto_annotate.py` can be used:
```
./scripts/auto_annotate.py images/mynewpics/*.jpg
```
It will create a `.xml` next to each `.jpg` file. labelImg can then be
used to see/fix the annotations.

### Manually annotate

labelImg program is used to annotate image files, it can be compiled
and launched simply with:
```
make label
```

Once labelImg is opened use "Open Dir" and "Change Save Dir" button to
change the directory to you image directory.

Some useful shortcuts:
 * `d` 	Next image
 * `a` 	Previous image
 * `w` 	Create a rect box

> Note: the "Auto Save Mode" from "View" menu can be very useful

## Run a training

Basically `make train` should do everything to create a new trained
model. It might take several dozens of hours to run depending on the
hardware.

`make export-graph` exports the trained model in `graphs/` folder.


## Folder description

* `graphs` Where generated graph are stored by `make export-graph`
* `images` All the image file for the model to train
   - `test` Image files for evaluation
   - `train` Image files for training
* `training` Where configuration files are stored, also used as
  working directory by `make train`
* `scripts` Some useful scripts
* `videos` Some videos to test the model
