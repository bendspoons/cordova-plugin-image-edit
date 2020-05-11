# Cordova Plugin for Editing Images / Pictures #

- Currently only available for Android
- iOS Version (Swift) is in development
- Quite nice UI, Colors and Icons
- all Descriptions/Labels are in German
- **!! under active Development !!**

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


Returns fully qualified image path like file:///filename.jpg

base64 mode is not recommended, its likely the app will crash unless you hand over a really small image

## Edit options ##

### Filter ###

Black / White

Greyscale

Sharpness

(Sepia)
 
### Cropping ###

with Rectangle Drawing
 
### Rotate ###

in 90° steps


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
