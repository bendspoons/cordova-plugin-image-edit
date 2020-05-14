# Cordova Plugin for Editing Images / Pictures #

- Android (Java): Crop, Rotate, BlackWhite, Greyscale, Sharpness | Input: file and base64
- iOS (Swift): Crop, Rotate (Draw Shape, NOT EXECUTED as of 11 05 2020), BlackWhite, Greyscale, Sharpness, Brightness | Input: file only
- Quite nice UI, Colors and Icons
- all Descriptions/Labels are in German
- **!! under active Development !!**
- **!! Currently the Callback Data is _NOT_ consistent between iOS and Android, im working on it !!**#

*DISCLAIMER: This plugin was  created for editing Scans/Photos of Documents, not regular Photos. It works anyways, but some functions, like the BlackWhite, were adjusted to work good with Documents and not a Photo of a nice sunset or whatever...*

## Installation ##

    cordova plugin add https://github.com/bendspoons/cordova-plugin-image-edit.git

## Usage ##

    imageEdit.edit(function(success) {
		// success.code = 201
		// success.result = "SUCCESS"
		// success.path = Path to created/edited Image
    }, function(error) {
    	// error.code = INT
		// error.result = STRING
    }, {
		'sourceData'       : 'file:///path/to/image.jpg',
		'sourceType'       : 'file',
		'destType'         : 'png', 	// OPTIONAL - jpg/png, default jpg
		'allowCrop'        : 1, 		// OPTIONAL - 1 or 0, default 1
		'allowRotate'      : 1, 		// OPTIONAL - 1 or 0, default 1
		'allowFilter'      : 1  		// OPTIONAL - 1 or 0, default 1
    });


Success Code:

    - 201 / SUCCESS

Possible Error Codes:

    - 101 / ABORTED
    - 401 / ERROR_OPTION_INPUTDATA_NOTEXISTS
    - 501 / ERROR_OPTION_INPUTTYPE
    - 502 / ERROR_OPTION_INPUTDATA_EMPTY
    - 503 / ERROR_OPTION_INPUTDATA_BASE64

Returns fully qualified image path like file:///saved/to/path/filename.jpg

base64 mode is not recommended, its likely the app will crash unless you hand over a really small image on Adnroid (prbably remove this whole base64 chunk because i do not need it anymore, and you can always save the base64 data to file and use this plugin with that saved file... amiright?!)

*--> Conclusion: i will definitly remove the buggy base64 functionality*

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
      	console.log('Camera Picture Path: ' + success.path);

      	imageEdit.edit(function(editedImagePath) {
     		console.log('Edited Image Path: ' + editedImagePath);   
      	}, function(error) {
     		alert('Failed because: ' + JSON.stringify(error);
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
