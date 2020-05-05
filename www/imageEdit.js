module.exports = {
  edit: function (successCallback, errorCallback, options) {
    options = options || {};

      var sourceData = options.sourceData || 'data:image/jpeg;base64,';	// base 64 data
      var sourceType = options.sourceType || 'jpg';	// base 64 data
			var args = [sourceData, sourceType];

    	cordova.exec(successCallback, errorCallback, "ImageEdit", "edit", args);
  }
};
