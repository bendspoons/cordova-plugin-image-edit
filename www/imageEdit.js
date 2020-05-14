module.exports = {
  edit: function (successCallback, errorCallback, options) {
    options = options || {};

    var sourceData = options.sourceData || '';
    var sourceType = options.sourceType || 'file';
    var destType = options.destType || 'jpg';
    var allowCrop = options.allowCrop || 1;
    var allowRotate = options.allowRotate || 1;
    var allowFilter = options.allowFilter || 1;

    var args = [sourceData, sourceType, destType, allowCrop, allowRotate, allowFilter];

    cordova.exec(successCallback, errorCallback, "ImageEdit", "edit", args);
  }
};
