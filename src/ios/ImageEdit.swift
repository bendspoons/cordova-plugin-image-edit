@objc(ImageEdit) class ImageEdit : CDVPlugin, ImageEditDelegate {

    var commandCollbackId = "";

    /*
    let RESULT_CODES: [Int] = [200,400,401,402,403]
    let RESULT_MSGS: [String] = [
        "SUCCESS",
        "ABORT",
        "ERROR",
        "ERROR_OPTION_INPUTTYPE",
        "ERROR_OPTION_INPUTDATA"
    ]

    let RESULT_CODES: KeyValuePairs = [
        200: "SUCCESS",
        400: "ABORT",
        401: "ERROR",
        501: "ERROR_OPTION_INPUTTYPE",
        502: "ERROR_OPTION_INPUTDATA_EMPTY",
        503: "ERROR_OPTION_INPUTDATA_BASE64"
    ] as KeyValuePairs<AnyHashable, NSString>
    */

    // initialize pluin
    override func pluginInitialize() {
        print("ImageEdit :: pluginInitialize")
    }

    /* version */
    @objc(edit:)
    func edit(command: CDVInvokedUrlCommand) {
        print("ImageEdit :: edit")

        DispatchQueue.main.async {
            // Store cordova callback
            self.commandCollbackId = command.callbackId;

            print("options \(command.arguments ?? [])")

            // inputType file
            // on iOS, only file is allowed
            let inputType = command.arguments[1] as? String ?? ""
            if(inputType != "file") {
                self.imageEdited(resultCode: 501, resultString: "ERROR_OPTION_INPUTTYPE", imagePath: "");
                return;
            }

            // FileURL
            // on iOS, only fileURLs are allowed
            var fileURL = command.arguments[0] as? String ?? ""
            if(fileURL == "data:image/jpeg;base64,") {
                fileURL = "";
            }

            // empty fileURL
            if(fileURL.isEmpty) {
                self.imageEdited(resultCode: 502, resultString: "ERROR_OPTION_INPUTDATA_EMPTY", imagePath: "");
                return;
            }

            // base64 fileURL
            if(fileURL.contains("data:image/")) {
                self.imageEdited(resultCode: 503, resultString: "ERROR_OPTION_INPUTDATA_BASE64", imagePath: "");
                return;
            }

            let destType = command.arguments[2] as? String ?? "jpg"
            let allowCrop = command.arguments[3] as? Int ?? 1
            let allowRotate = command.arguments[4] as? Int ?? 1
            let allowFilter = command.arguments[5] as? Int ?? 1


            print("ImageEdit :: fileURL ", fileURL)
            print("ImageEdit :: inputType", inputType)

            print("ImageEdit :: destType", destType)
            print("ImageEdit :: allowCrop", allowCrop)
            print("ImageEdit :: allowRotate", allowRotate)
            print("ImageEdit :: allowFilter", allowFilter)

            // ImageEditViewController
            let detailVC = ImageEditViewController()

            detailVC.filePath = fileURL;

            detailVC.allowCrop = allowCrop;
            detailVC.allowRotate = allowRotate;
            detailVC.allowFilter = allowFilter;

            detailVC.destType = destType;

            detailVC.delegate = self;

            // navigationController
            let navigationController = UINavigationController(rootViewController: detailVC)
            navigationController.modalPresentationStyle = .fullScreen

            self.viewController?.present(navigationController, animated: true)
        }
    }

    func imageEdited(resultCode: NSInteger, resultString: NSString, imagePath: NSString) {
        print("ImageEdit :: imageEdited CALLBACK")
        print("ImageEdit :: imageEdited resultCode", resultCode)
        print("ImageEdit :: imageEdited resultString", resultString)
        print("ImageEdit :: imageEdited imagePath", imagePath)

        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )

        if(resultCode == 201) { // Success, imagepath returned
            let successResult: [String: Any] = [
              "code"    : resultCode,
              "result"  : resultString,
              "path"    : imagePath
            ]

            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: successResult
            )
        } else { // Abort or Error
            let errorResult: [String: Any] = [
              "code": resultCode,
              "result": resultString
            ]

            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: errorResult
            )
        }

        self.commandDelegate!.send(
            pluginResult,
            callbackId: self.commandCollbackId
        )
    }

    func parseTuple(from string: String) -> (String, Int)? {

        if let theRange = string.range(of: "/", options: .backwards),
            let i = Int(string[theRange.upperBound...]) {
            return (String(string[...theRange.lowerBound]), i)
        } else {
            return nil
        }
    }

}




 /* version
 @objc(abort:)
   func abort(imagePath: NSString) {
   print("ImageEdit :: abort", imagePath)

 }
*/

    /*
     let toastController: UIAlertController =
        UIAlertController(
          title: "",
          message: fileData,
          preferredStyle: .alert
        )

      self.viewController?.present(
        toastController,
        animated: true,
        completion: nil
      )

      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        toastController.dismiss(
          animated: true,
          completion: nil
        )
      }
*/
