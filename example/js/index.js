/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
var app = {
    // Application Constructor
    initialize: function() {
        document.addEventListener('deviceready', this.onDeviceReady.bind(this), false);
    },

    // deviceready Event Handler
    //
    // Bind any cordova events here. Common events are:
    // 'pause', 'resume', etc.
    onDeviceReady: function() {
        /*
        setTimeout(function() {
            //var success =  cordova.file.applicationStorageDirectory + 'img/beleg.jpeg';
            var success =  'img/beleg.jpeg';
           console.log('load image from www' + success)
           $('#cameraImage').attr('src', success);
           $('#cameraImage').attr('alt', success);
           $('#cameraImage').attr('title', success);
           $('#cameraImageSrc').html(success);
           $('.show-when-image').show();
        }, 3000);
        */
    },

    camera: function() {
      navigator.camera.getPicture(function(success) {
        console.log('Camera Source: ' + success);

        $('#cameraImage').attr('src', success);
        $('#cameraImageSrc').html(success);
        $('.show-when-image').show();
      }, function(message) {
         alert('Failed because: ' + message);
      }, {
         quality: 80,
         destinationType: Camera.DestinationType.FILE_URI
      });
    },

    editImage: function() {
      imageEdit.edit(function(success) {
        console.log('Edited Image Source: ', JSON.stringify(success));
        alert('Edited Image Source: ' + JSON.stringify(success));

         $('#editedImage').attr('src', success.path);
         $('#editedImageSrc').html(JSON.stringify(success));
         $('.show-when-edited').show();
      }, function(error) {
        console.log('Failed because: ', JSON.stringify(error));
        alert('Failed because: ' + JSON.stringify(error));
      }, {
         'sourceData'       : $('#cameraImage').attr('src'),
         'sourceType'       : 'file',
         //'destType'         : 'png', // jpg or png, default jpg
         //'allowCrop'        : 1, // 1 or 0, default 1
         //'allowRotate'      : 1, // 1 or 0, default 1
         //'allowFilter'      : 1 // 1 or 0, default 1
      });
    },

    setBasicImage: function() {
      var success = 'file:///storage/emulated/0/Android/data/com.bendspoons.imageedit/cache/1588864986783.jpg';
       console.log('Edited Image Source: ' + success);
       $('#cameraImage').attr('src', success);
       $('#cameraImageSrc').html(success);
       $('.show-when-image').show();
    },

    setPickImage: function() {
        window.imagePicker.getPictures(function(results) {

            var imgSrc = 'file://' + results[0];
            console.log('Edited Image Source: ' + imgSrc);
            $('#cameraImage').attr('src', imgSrc);
            $('#cameraImageSrc').html(imgSrc);
            $('.show-when-image').show();

            for (var i = 0; i < results.length; i++) {
                console.log('Image URI: ' + results[i]);
            }
        }, function (error) {
            console.log('Error: ' + error);
        });
    },

    photoAndEdit: function() {
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
    }
};

app.initialize();
