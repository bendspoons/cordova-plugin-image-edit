# Cordova Plugin for Editing Images / Pictures #

- Android (Java): Crop, Rotate, BlackWhite, Greyscale, Sharpness | Input: file and base64
- iOS (Swift): Crop, Rotate (Draw Shape, NOT EXECUTED as of 11 05 2020), BlackWhite, Greyscale, Sharpness, Brightness | Input: file only
- Quite nice UI, Colors and Icons
- all Descriptions/Labels are in German
- **!! under active Development !!**
- **!! Currently the Callback Data is _NOT_ consistent between iOS and Android, im working on it !!**

## Installation ##

    cordova plugin add https://github.com/bendspoons/cordova-plugin-image-edit.git

## Usage ##

    imageEdit.edit(function(success) {
     console.log('Edited Image Source: ' + success);
    
    }, function(error) {
     alert('Failed because: ' + error);
    }, {
     'sourceData': 'file:///storage/emulated/.../image.jpg',
     'sourceType': 'file'
     //'sourceData': 'data:image/jpg;base64,iVBORw0....',
     //'sourceType': 'base64'
    });


Returns fully qualified image path like file:///saved/to/path/filename.jpg

base64 mode is not recommended, its likely the app will crash unless you hand over a really small image on Adnroid (prbably remove this whole base64 chunk because i do not need it anymore, and you can always save the base64 data to file and use this plugin with that saved file... amiright?!)

## Edit options ##

### Filter ###

Black / White (on iOS with a little analysing of the given image brightness and according actions)

Greyscale

Sharpness

(Brightness iOS only)
 
### Cropping ###

with Rectangle Drawing
 
### Rotate ###

in 90° steps (on iOS with additinal UISlider)


## Example with Camera ##

    navigator.camera.getPicture(function(cameraPicturePath) {
      	console.log('Camera Picture Path: ' + success);

      	imageEdit.edit(function(editedImagePath) {
     		console.log('Edited Image Path: ' + editedImagePath);   
      	}, function(error) {
     		alert('Failed because: ' + error);
      	}, {
     		sourceData: cameraPicturePath,
     		sourceType: 'file'
      	});

    }, function(cameraError) {
      alert('Camera failed because: ' + cameraError);
    }, {
      quality: 80,
      destinationType: Camera.DestinationType.FILE_URI
    });
