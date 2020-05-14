import UIKit

protocol ImageEditDelegate: class {
    func imageEdited(resultCode: NSInteger, resultString: NSString, imagePath: NSString)
}

class ImageEditViewController: UIViewController {
    var imageView:UIImageView = UIImageView.init()

    var filePath:String = "";

    var allowCrop:Int = 1; // not used yet
    var allowRotate:Int = 1; // not used yet
    var allowFilter:Int = 1; // not used yet

    var destType:String = "jpg";

    weak var delegate:ImageEditDelegate?

    var filterButton = UIButton(type: .roundedRect)
    var filterButtonActive:Bool = false;
    var filterButtonSW = UIButton(type: .roundedRect)
    var filterButtonGreyscale = UIButton(type: .roundedRect)
    var filterButtonBrightness = UIButton(type: .roundedRect)
    var filterButtonSharpness = UIButton(type: .roundedRect)
    var filterButtonReset = UIButton(type: .roundedRect)

    var cropButton = UIButton(type: .roundedRect)
    var cropSaveButton = UIButton(type: .roundedRect)
    var cropAbortButton = UIButton(type: .roundedRect)
    var cropDetectButton = UIButton(type: .roundedRect)

    var cropRectangleLayer = CAShapeLayer();
    var cropRectangle = CGRect();
    var cropRectangleDrawn:Bool = false;

    var cropDragStart:Bool = false
    var cropDragMove:Bool = false
    var cropDragMoveDir:String = ""

    var topLeftHandle = UIButton(type: .roundedRect)
    var topRightHandle = UIButton(type: .roundedRect)
    var bottomRightHandle = UIButton(type: .roundedRect)
    var bottomLeftHandle = UIButton(type: .roundedRect)
    var centerHandle = UIButton(type: .roundedRect)

    var handleSize = 32

    var topLeftToBottomRightLayer = CAShapeLayer()
    var topRoghtToBottomLeftLayer = CAShapeLayer()

    var cropStartX:Int = 0;
    var cropStartY:Int = 0;

    var cropWidth:Int = 0;
    var cropHeight:Int = 0;

    var cropMinWidth:Int = 60;
    var cropMinHeight:Int = 85;

    var cropCenterTopBottomDragSpace:Int = 0;
    var cropCenterLeftRightDragSpace:Int = 0;
    var cropLeftDragSpace:Int = 0;
    var cropRightDragSpace:Int = 0;
    var cropTopDragSpace:Int = 0;
    var cropBottomDragSpace:Int = 0;

    var cropButtonActive:Bool = false;

    var rotateButton = UIButton(type: .roundedRect)
    var rotateButtonActive:Bool = false;
    let rotateSlider = UISlider();
    var rotateButtonNinety = UIButton(type: .roundedRect)
    var rotateDegrees:Int = 0;

    let bgColor:UIColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
    let textColor:UIColor = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1.00)

    var originalImage:UIImage? = nil;
    var filterTempImage:UIImage? = nil;

    var lastLocation = CGPoint()

    override func viewDidLoad() {
        super.viewDidLoad()

        print("ImageEditViewController :: viewDidLoad");
        print("ImageEditViewController :: filePath", filePath);

    // Top Bar
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(ImageEditViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton

        let newSaveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(ImageEditViewController.save(sender:)))
        self.navigationItem.rightBarButtonItem = newSaveButton

    // Bild
        addImageView()

    // Buttons
    // Filter
        if #available(iOS 13.0, *) {
            self.filterButton.frame = CGRect(x: 25, y: view.bounds.height - 250, width: 60, height: 60)
            self.filterButton.setImage(UIImage(systemName: "wrench"), for: .normal)

            self.filterButton.layer.cornerRadius = 0.5 * self.filterButton.bounds.size.width // circular
            let spacing: CGFloat = 8.0
            self.filterButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
        } else {
            self.filterButton.frame = CGRect(x: 25, y: view.bounds.height - 200, width: 100, height: 40)
            self.filterButton.setTitle("Filter", for: .normal)

            self.filterButton.layer.cornerRadius = 5
        }

        self.filterButton.backgroundColor = textColor
        self.filterButton.tintColor = .white
        self.filterButton.layer.borderColor = UIColor.black.cgColor
        self.filterButton.clipsToBounds = true

        self.filterButton.addTarget(self, action: #selector(ImageEditViewController.startFilter(sender:)), for: .touchUpInside)

        self.view.addSubview(self.filterButton)

        // SW
            if #available(iOS 13.0, *) {
                self.filterButtonSW.frame = CGRect(x: 110, y: view.bounds.height - 250, width: 60, height: 60)
                self.filterButtonSW.setImage(UIImage(systemName: "circle.lefthalf.fill"), for: .normal)

                self.filterButtonSW.layer.cornerRadius = 0.5 * self.filterButtonSW.bounds.size.width // circular
                let spacing: CGFloat = 8.0
                self.filterButtonSW.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
            } else {
                self.filterButtonSW.frame = CGRect(x: 145, y: view.bounds.height - 200, width: 40, height: 40)
                self.filterButtonSW.setTitle("S/W", for: .normal)

                self.filterButtonSW.layer.cornerRadius = 5
            }

            self.filterButtonSW.isHidden = true
            self.filterButtonSW.backgroundColor = textColor
            self.filterButtonSW.tintColor = .white
            self.filterButtonSW.layer.borderColor = UIColor.black.cgColor
            self.filterButtonSW.clipsToBounds = true

            self.filterButtonSW.addTarget(self, action: #selector(ImageEditViewController.startSWFilter(sender:)), for: .touchUpInside)

            self.view.addSubview(self.filterButtonSW)

        // Grey
            if #available(iOS 13.0, *) {
                self.filterButtonGreyscale.frame = CGRect(x: 190, y: view.bounds.height - 250, width: 60, height: 60)
                self.filterButtonGreyscale.setImage(UIImage(systemName: "circle.righthalf.fill"), for: .normal)

                self.filterButtonGreyscale.layer.cornerRadius = 0.5 * self.filterButtonGreyscale.bounds.size.width // circular
                let spacing: CGFloat = 8.0
                self.filterButtonGreyscale.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
            } else {
                self.filterButtonGreyscale.frame = CGRect(x: 205, y: view.bounds.height - 200, width: 40, height: 40)
                self.filterButtonGreyscale.setTitle("Grau", for: .normal)

                self.filterButtonGreyscale.layer.cornerRadius = 5
            }

            self.filterButtonGreyscale.isHidden = true
            self.filterButtonGreyscale.backgroundColor = textColor
            self.filterButtonGreyscale.tintColor = .white
            self.filterButtonGreyscale.layer.borderColor = UIColor.black.cgColor
            self.filterButtonGreyscale.clipsToBounds = true

            self.filterButtonGreyscale.addTarget(self, action: #selector(ImageEditViewController.startGreyscaleFilter(sender:)), for: .touchUpInside)

            self.view.addSubview(self.filterButtonGreyscale)

        // Brightness top level
            if #available(iOS 13.0, *) {
                self.filterButtonBrightness.frame = CGRect(x: 190, y: view.bounds.height - 325, width: 60, height: 60)
                self.filterButtonBrightness.setImage(UIImage(systemName: "sun.max"), for: .normal)

                self.filterButtonBrightness.layer.cornerRadius = 0.5 * self.filterButtonBrightness.bounds.size.width // circular
                let spacing: CGFloat = 8.0
                self.filterButtonBrightness.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
            } else {
                self.filterButtonBrightness.frame = CGRect(x: 205, y: view.bounds.height - 275, width: 40, height: 40)
                self.filterButtonBrightness.setTitle("Hell", for: .normal)

                self.filterButtonBrightness.layer.cornerRadius = 5
            }

            self.filterButtonBrightness.isHidden = true
            self.filterButtonBrightness.backgroundColor = textColor
            self.filterButtonBrightness.tintColor = .white
            self.filterButtonBrightness.layer.borderColor = UIColor.black.cgColor
            self.filterButtonBrightness.clipsToBounds = true

            self.filterButtonBrightness.addTarget(self, action: #selector(ImageEditViewController.startBrightnessFilter(sender:)), for: .touchUpInside)

            self.view.addSubview(self.filterButtonBrightness)

        // Sharp
            if #available(iOS 13.0, *) {
                self.filterButtonSharpness.frame = CGRect(x: 270, y: view.bounds.height - 250, width: 60, height: 60)
                self.filterButtonSharpness.setImage(UIImage(systemName: "bolt"), for: .normal)

                self.filterButtonSharpness.layer.cornerRadius = 0.5 * self.filterButtonSharpness.bounds.size.width // circular
                let spacing: CGFloat = 8.0
                self.filterButtonSharpness.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
            } else {
                self.filterButtonSharpness.frame = CGRect(x: 265, y: view.bounds.height - 200, width: 75, height: 40)
                self.filterButtonSharpness.setTitle("Schärfe", for: .normal)

                self.filterButtonSharpness.layer.cornerRadius = 5
            }

            self.filterButtonSharpness.isHidden = true
            self.filterButtonSharpness.backgroundColor = textColor
            self.filterButtonSharpness.tintColor = .white
            self.filterButtonSharpness.layer.borderColor = UIColor.black.cgColor
            self.filterButtonSharpness.clipsToBounds = true

            self.filterButtonSharpness.addTarget(self, action: #selector(ImageEditViewController.startSharpnessFilter(sender:)), for: .touchUpInside)

            self.view.addSubview(self.filterButtonSharpness)

        // Reset Filter top level
            if #available(iOS 13.0, *) {
                self.filterButtonReset.frame = CGRect(x: 270, y: view.bounds.height - 325, width: 60, height: 60)
                self.filterButtonReset.setImage(UIImage(systemName: "trash"), for: .normal)

                self.filterButtonReset.layer.cornerRadius = 0.5 * self.filterButtonReset.bounds.size.width // circular
                let spacing: CGFloat = 8.0
                self.filterButtonReset.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
            } else {
                self.filterButtonReset.frame = CGRect(x: 265, y: view.bounds.height - 275, width: 75, height: 40)
                self.filterButtonReset.setTitle("Reset", for: .normal)

                self.filterButtonReset.layer.cornerRadius = 5
            }

            self.filterButtonReset.isHidden = true
            self.filterButtonReset.backgroundColor = .red
            self.filterButtonReset.tintColor = .white
            self.filterButtonReset.layer.borderColor = UIColor.black.cgColor
            self.filterButtonReset.clipsToBounds = true

            self.filterButtonReset.addTarget(self, action: #selector(ImageEditViewController.resetFilter(sender:)), for: .touchUpInside)

            self.view.addSubview(self.filterButtonReset)



    // Zuschnitt
        if #available(iOS 13.0, *) {
            self.cropButton.frame = CGRect(x: 25, y: view.bounds.height - 175, width: 60, height: 60)
            self.cropButton.setImage(UIImage(systemName: "skew"), for: .normal)

            self.cropButton.layer.cornerRadius = 0.5 * self.cropButton.bounds.size.width // circular
            let spacing: CGFloat = 8.0
            self.cropButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
        } else {
            self.cropButton.frame = CGRect(x: 25, y: view.bounds.height - 150, width: 100, height: 40)
            self.cropButton.setTitle("Zuschnitt", for: .normal)

            self.cropButton.layer.cornerRadius = 5
        }

        self.cropButton.backgroundColor = textColor
        self.cropButton.tintColor = .white
        self.cropButton.layer.borderColor = UIColor.black.cgColor
        self.cropButton.clipsToBounds = true

        self.cropButton.addTarget(self, action: #selector(ImageEditViewController.toggleCropping(sender:)), for: .touchUpInside)

        self.view.addSubview(self.cropButton)

        // Zuschnitt magic
            if #available(iOS 13.0, *) {
                self.cropDetectButton.frame = CGRect(x: 110, y: view.bounds.height - 175, width: 60, height: 60)
                self.cropDetectButton.setImage(UIImage(systemName: "wand.and.stars"), for: .normal)

                self.cropDetectButton.layer.cornerRadius = 0.5 * self.cropButton.bounds.size.width // circular
                let spacing: CGFloat = 8.0
                self.cropDetectButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
            } else {
                self.cropDetectButton.frame = CGRect(x: 145, y: view.bounds.height - 150, width: 100, height: 40)
                self.cropDetectButton.setTitle("Detect", for: .normal)

                self.cropDetectButton.layer.cornerRadius = 5
            }

            self.cropDetectButton.backgroundColor = textColor
            self.cropDetectButton.tintColor = .white
            self.cropDetectButton.layer.borderColor = UIColor.black.cgColor
            self.cropDetectButton.clipsToBounds = true

            self.cropDetectButton.isHidden = true

            self.cropDetectButton.addTarget(self, action: #selector(ImageEditViewController.detectContour(sender:)), for: .touchUpInside)

            self.view.addSubview(self.cropDetectButton)

        // Zuschnitt execute
            if #available(iOS 13.0, *) {
                self.cropSaveButton.frame = CGRect(x: 190, y: view.bounds.height - 175, width: 60, height: 60)
                self.cropSaveButton.setImage(UIImage(systemName: "checkmark"), for: .normal)

                self.cropSaveButton.layer.cornerRadius = 0.5 * self.cropButton.bounds.size.width // circular
                let spacing: CGFloat = 8.0
                self.cropSaveButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
            } else {
                self.cropSaveButton.frame = CGRect(x: 205, y: view.bounds.height - 150, width: 100, height: 40)
                self.cropSaveButton.setTitle("Zuschnitt", for: .normal)

                self.cropSaveButton.layer.cornerRadius = 5
            }

            self.cropSaveButton.backgroundColor = UIColor.green
            self.cropSaveButton.tintColor = .white
            self.cropSaveButton.layer.borderColor = UIColor.black.cgColor
            self.cropSaveButton.clipsToBounds = true

            self.cropSaveButton.isHidden = true

            self.cropSaveButton.addTarget(self, action: #selector(ImageEditViewController.saveCropping(sender:)), for: .touchUpInside)

            self.view.addSubview(self.cropSaveButton)

        // Zuschnitt abort
            if #available(iOS 13.0, *) {
                self.cropAbortButton.frame = CGRect(x: 270, y: view.bounds.height - 175, width: 60, height: 60)
                self.cropAbortButton.setImage(UIImage(systemName: "trash.slash"), for: .normal)

                self.cropAbortButton.layer.cornerRadius = 0.5 * self.cropButton.bounds.size.width // circular
                let spacing: CGFloat = 8.0
                self.cropAbortButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
            } else {
                self.cropAbortButton.frame = CGRect(x: 265, y: view.bounds.height - 150, width: 100, height: 40)
                self.cropAbortButton.setTitle("abbrechen", for: .normal)

                self.cropAbortButton.layer.cornerRadius = 5
            }

            self.cropAbortButton.backgroundColor = UIColor.red
            self.cropAbortButton.tintColor = .white
            self.cropAbortButton.layer.borderColor = UIColor.black.cgColor
            self.cropAbortButton.clipsToBounds = true

            self.cropAbortButton.isHidden = true

            self.cropAbortButton.addTarget(self, action: #selector(ImageEditViewController.cancelCroppingDraw(sender:)), for: .touchUpInside)

            self.view.addSubview(self.cropAbortButton)

    // Rotate
        if #available(iOS 13.0, *) {
            self.rotateButton.frame = CGRect(x: 25, y: view.bounds.height - 100, width: 60, height: 60)
            self.rotateButton.setImage(UIImage(systemName: "goforward"), for: .normal)

            self.rotateButton.layer.cornerRadius = 0.5 * self.rotateButton.bounds.size.width // circular
            let spacing: CGFloat = 8.0
            self.rotateButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
        } else {
            self.rotateButton.frame = CGRect(x: 25, y: view.bounds.height - 100, width: 100, height: 40)
            self.rotateButton.setTitle("Drehen", for: .normal)

            self.rotateButton.layer.cornerRadius = 5
        }

        self.rotateButton.backgroundColor = textColor
        self.rotateButton.tintColor = .white
        self.rotateButton.layer.borderColor = UIColor.black.cgColor
        self.rotateButton.clipsToBounds = true

        self.rotateButton.addTarget(self, action: #selector(ImageEditViewController.toggleRotate(sender:)), for: .touchUpInside)

        self.view.addSubview(self.rotateButton)

        // Rotate Button, only iOS 13
            if #available(iOS 13.0, *) {
                self.rotateButtonNinety.frame = CGRect(x: 110, y: view.bounds.height - 100, width: 60, height: 60)
                self.rotateButtonNinety.setImage(UIImage(systemName: "goforward.90"), for: .normal)

                self.rotateButtonNinety.layer.cornerRadius = 0.5 * self.rotateButtonNinety.bounds.size.width // circular
                let spacing: CGFloat = 8.0
                self.rotateButtonNinety.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)

                self.rotateButtonNinety.backgroundColor = textColor
                self.rotateButtonNinety.tintColor = .white
                self.rotateButtonNinety.layer.borderColor = UIColor.black.cgColor
                self.rotateButtonNinety.clipsToBounds = true
                self.rotateButtonNinety.isHidden = true;

                self.rotateButtonNinety.addTarget(self, action: #selector(ImageEditViewController.setRotateNinety(sender:)), for: .touchUpInside)

                self.view.addSubview(self.rotateButtonNinety)
            }

        // Rotate Slider
            if #available(iOS 13.0, *) {
                let sW = UIScreen.main.bounds.size.width - 215;
                self.rotateSlider.frame = CGRect(x: 195, y: view.bounds.height - 100, width: sW, height: 60);
                self.rotateSlider.layer.cornerRadius = 0.5 * self.rotateSlider.bounds.size.height // circular
            } else {
                let sW = UIScreen.main.bounds.size.width - 180;
                self.rotateSlider.frame = CGRect(x: 145, y: view.bounds.height - 100, width: sW, height: 40);
                self.rotateSlider.layer.cornerRadius = 5
            }
            self.rotateSlider.backgroundColor = textColor
            self.rotateSlider.isHidden = true;
            self.rotateSlider.isContinuous = false
            self.rotateSlider.minimumValue = 0;
            self.rotateSlider.maximumValue = 360;
            self.rotateSlider.thumbTintColor = .white
            self.rotateSlider.minimumTrackTintColor = .white
            self.rotateSlider.layer.borderColor = UIColor.black.cgColor

            //let image = textColor.image(CGSize(width: 20, height: 60))
            //self.rotateSlider.setMaximumTrackImage(image, for: .normal);
            //self.rotateSlider.setMinimumTrackImage(image, for: .normal);

            self.rotateSlider.addTarget(self, action: #selector(ImageEditViewController.setRotateSlider(sender:)), for: .valueChanged)

            self.view.addSubview(self.rotateSlider)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        print("ImageEditViewController :: didMove");

        if parent == nil {
            debugPrint("Back Button pressed.")
        }
    }

    /*
     * Filter Button clicked, start filter
     */
    @objc func startFilter(sender: UIBarButtonItem) {
        print("ImageEditViewController :: startFilter");

        if self.filterButtonActive {
            self.navigationController?.navigationBar.isHidden = false

            self.filterButtonActive = false;

            self.filterButtonSharpness.isHidden = true
            self.filterButtonSW.isHidden = true
            self.filterButtonGreyscale.isHidden = true
            self.filterButtonBrightness.isHidden = true
            self.filterButtonReset.isHidden = true

            self.cropButton.isEnabled = true;
            self.rotateButton.isEnabled = true;

            // Save self.filterTempImage = self.originalImage to original
            self.originalImage = self.filterTempImage
            self.filterTempImage = nil
        } else {
            self.navigationController?.navigationBar.isHidden = true

            self.filterButtonActive = true;

            self.filterButtonSharpness.isHidden = false
            self.filterButtonSW.isHidden = false
            self.filterButtonGreyscale.isHidden = false
            self.filterButtonBrightness.isHidden = false
            //self.filterButtonReset.isHidden = false

            self.cropButton.isEnabled = false;
            self.rotateButton.isEnabled = false;

            self.filterTempImage = self.originalImage
        }
    }

    @objc func resetFilter(sender: UIBarButtonItem) {
        print("ImageEditViewController :: resetFilter");

        self.filterTempImage = self.originalImage;
        imageView.image = self.originalImage

        self.filterButtonReset.isHidden = true
    }

    @objc func startSWFilter(sender: UIBarButtonItem) {
        print("ImageEditViewController :: startSWFilter");

        let image = self.filterTempImage

        let blackWhiteImage = image!.toBlackAndWhite()

        self.filterTempImage = blackWhiteImage
        imageView.image = blackWhiteImage

        self.filterButtonReset.isHidden = false
    }

    @objc func startGreyscaleFilter(sender: UIBarButtonItem) {
        print("ImageEditViewController :: startGreyscaleFilter");

        let image = self.filterTempImage

        guard let currentCGImage = image?.cgImage else {
            print("NO valid IMAGE")
            return
        }
        let currentCIImage = CIImage(cgImage: currentCGImage)

        let filter = CIFilter(name: "CIColorMonochrome")
        filter?.setValue(currentCIImage, forKey: "inputImage")

        // set a gray value for the tint color
        filter?.setValue(CIColor(red: 0.7, green: 0.7, blue: 0.7), forKey: "inputColor")

        filter?.setValue(1.0, forKey: "inputIntensity")
        guard let outputImage = filter?.outputImage else {
            print("NO apply")
            return
        }

        let context = CIContext()

        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let processedImage = UIImage(cgImage: cgimg)
            print(processedImage.size)

            self.filterTempImage = processedImage
            imageView.image = processedImage

            self.filterButtonReset.isHidden = false
        }
    }

    @objc func startBrightnessFilter(sender: UIBarButtonItem) {
        print("ImageEditViewController :: startBrightnessFilter");

        let image = self.filterTempImage

        let currentBrightness = image?.brightness;
        print("ImageEditViewController :: currentBrightness", currentBrightness as Any);


        guard let currentCGImage = image?.cgImage else {
            print("NO valid IMAGE")
            return
        }
        let currentCIImage = CIImage(cgImage: currentCGImage)

        let filter = CIFilter(name: "CIColorControls")
        //filter?.setValue(currentCIImage, forKey: "inputImage")
        filter?.setValue(currentCIImage, forKey: kCIInputImageKey)
        filter?.setValue(0.25, forKey: kCIInputBrightnessKey)


        guard let outputImage = filter?.outputImage else {
            print("NO apply")
            return
        }

        let context = CIContext()

        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let processedImage = UIImage(cgImage: cgimg)
            print(processedImage.size)

            self.filterTempImage = processedImage
            imageView.image = processedImage

            self.filterButtonReset.isHidden = false
        }

        /*
        if ((currentBrightness?.isLess(than: 34))!) {
            print("ImageEditViewController :: currentBrightness isLess 34", currentBrightness as Any);
        }

        if ((Double(242).isLess(than: currentBrightness!))) {
            print("ImageEditViewController :: currentBrightness isMore 242", currentBrightness as Any);
        }
        */
    }

    @objc func startSharpnessFilter(sender: UIBarButtonItem) {
        print("ImageEditViewController :: startSharpnessFilter");

        let image = self.filterTempImage

        guard let currentCGImage = image?.cgImage else {
            print("NO valid IMAGE")
            return
        }
        let currentCIImage = CIImage(cgImage: currentCGImage)

        let filter = CIFilter(name: "CIUnsharpMask")
        filter?.setValue(currentCIImage, forKey: "inputImage")

        filter?.setValue(2.5, forKey: kCIInputRadiusKey)
        filter?.setValue(4.0, forKey: kCIInputIntensityKey)

        filter?.setValue(1.0, forKey: "inputIntensity")
        guard let outputImage = filter?.outputImage else {
            print("NO apply")
            return
        }

        let context = CIContext()

        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let processedImage = UIImage(cgImage: cgimg)
            print(processedImage.size)

            self.filterTempImage = processedImage
            imageView.image = processedImage

            self.filterButtonReset.isHidden = false
        }
    }

    /*
     * Cropping
     */
     @objc func toggleCropping(sender: UIBarButtonItem) {
         print("ImageEditViewController :: toggleCropping");

         if self.cropButtonActive {
             self.stopCropping()
         } else {
             self.startCropping();
         }
     }

    @objc func cancelCroppingDraw(sender: UIBarButtonItem) {
        print("ImageEditViewController :: cancelCroppingDraw");

        self.cropSaveButton.isHidden = true
        self.cropAbortButton.isHidden = true
        self.cropRectangleDrawn = false

        self.cropRectangleLayer.removeFromSuperlayer()

        self.topLeftToBottomRightLayer.removeFromSuperlayer()
        self.topRoghtToBottomLeftLayer.removeFromSuperlayer()

        self.topLeftHandle.removeFromSuperview()
        self.topRightHandle.removeFromSuperview()
        self.bottomLeftHandle.removeFromSuperview()
        self.bottomRightHandle.removeFromSuperview()
        self.centerHandle.removeFromSuperview()
    }

    @objc func detectContour(sender: UIBarButtonItem) {
        print("ImageEditViewController :: detectContour");

        let sourceImage = CIImage(image: self.filterTempImage!)

        let detectedImage = performRectangleDetection(image: sourceImage!)

        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(detectedImage!, from: detectedImage!.extent)!
        let croppedImage:UIImage = UIImage.init(cgImage: cgImage)

        self.originalImage = croppedImage
        imageView.image = croppedImage

        self.view.setNeedsDisplay()

        stopCropping()
    }


    func performRectangleDetection(image: CIImage) -> CIImage? {
        var resultImage: CIImage?
        resultImage = image
        //let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.41, CIDetectorMaxFeatureCount: 1] )!
        let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh] )!

        // Get the detections
        //var halfPerimiterValue = 0.0 as Float;

        //let path = UIBezierPath()

        //self.cropRectangleLayer.borderWidth = 2;
        //self.cropRectangleLayer.borderColor = UIColor.red.cgColor
        //self.cropRectangleLayer.backgroundColor = UIColor.white.cgColor
        //self.cropRectangleLayer.opacity = 0.5;
        //self.cropRectangleLayer.strokeColor = UIColor.red.cgColor
        //self.cropRectangleLayer.lineWidth = 2.0

        //self.view.layer.addSublayer(self.cropRectangleLayer)

        /*
        for feature in features {

            guard let rect = feature as? CIRectangleFeature else {
                continue
            }

            let topLeft = CGPoint(x: (rect.topLeft.x * factor) + infoO.origin.x, y: (rect.topLeft.y * factor) + infoO.origin.y)
            let topRight = CGPoint(x: (rect.topRight.x * factor) + infoO.origin.x, y: (rect.topRight.y * factor) + infoO.origin.y)
            let bottomRight = CGPoint(x: (rect.bottomRight.x * factor) + infoO.origin.x, y: (rect.bottomRight.y * factor) + infoO.origin.y)
            let bottomLeft = CGPoint(x: (rect.bottomLeft.x * factor) + infoO.origin.x, y: (rect.bottomLeft.y * factor) + infoO.origin.y)

            //path.move(to: rect.topLeft)
            //path.addLine(to: rect.topRight)
            //path.addLine(to: rect.bottomRight)
            //path.addLine(to: rect.bottomLeft)
            path.move(to: topLeft)
            path.addLine(to: topRight)
            path.addLine(to: bottomRight)
            path.addLine(to: bottomLeft)

            path.close()
        }
        */

        var halfPerimiterValue = 0.0 as Float;
        let features = detector.features(in: image)
        print("feature \(features.count)")
        for feature in features as! [CIRectangleFeature] {

            let p1 = feature.topLeft
            let p2 = feature.topRight
            let width = hypotf(Float(p1.x - p2.x), Float(p1.y - p2.y));
            //NSLog(@"xaxis    %@", @(p1.x));
            //NSLog(@"yaxis    %@", @(p1.y));
            let p3 = feature.topLeft
            let p4 = feature.bottomLeft
            let height = hypotf(Float(p3.x - p4.x), Float(p3.y - p4.y));
            let currentHalfPerimiterValue = height+width;

            if (halfPerimiterValue < currentHalfPerimiterValue)
            {
             halfPerimiterValue = currentHalfPerimiterValue

                resultImage = cropBusinessCardForPoints(image: image, topLeft: feature.topLeft, topRight: feature.topRight, bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)

                print("feature.topLeft   \(feature.topLeft)")
                print("feature.topRight   \(feature.topRight)")
                print("feature.bottomLeft   \(feature.bottomLeft)")
                print("feature.bottomRight   \(feature.bottomRight)")

                let newTopLeft = imageView.convertPoint(fromImagePoint: feature.topLeft)
                let newTopRight = imageView.convertPoint(fromImagePoint: feature.topRight)
                let newBottomLeft = imageView.convertPoint(fromImagePoint: feature.bottomLeft)
                let newBottomRight = imageView.convertPoint(fromImagePoint: feature.bottomRight)

                //path.move(to: newTopLeft)
                //path.addLine(to: newTopRight)
                //path.addLine(to: newBottomRight)
                //path.addLine(to: newBottomLeft)

                //path.close()


                print("newTopLeft   \(newTopLeft)")
                print("newTopRight   \(newTopRight)")
                print("newBottomLeft   \(newBottomLeft)")
                print("newBottomRight   \(newBottomRight)")
            }

        }

        //self.cropRectangleLayer.path = path.cgPath;

        return resultImage
    }

    func cropBusinessCardForPoints(image: CIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {

        var businessCard: CIImage
        businessCard = image.applyingFilter(
            "CIPerspectiveTransformWithExtent",
            parameters: [
                "inputExtent": CIVector(cgRect: image.extent),
                "inputTopLeft": CIVector(cgPoint: topLeft),
                "inputTopRight": CIVector(cgPoint: topRight),
                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                "inputBottomRight": CIVector(cgPoint: bottomRight)])
        businessCard = image.cropped(to: businessCard.extent)

        return businessCard
    }



    @objc func saveCropping(sender: UIBarButtonItem) {
        print("ImageEditViewController :: saveCropping");

        /*
        let info = imageView.contentClippingRect
        print("IMG width = \(info.size.width), height = \(info.size.height)")
        print("IMG width O = \(imageView.image!.size.width), height O = \(imageView.image!.size.height)")

        let factor = imageView.image!.size.height / info.size.height

        let cropFinalX = (CGFloat(self.cropStartX) * factor)
        let cropFinalY = (CGFloat(self.cropStartY) * factor)
        let cropFinalWidth = (CGFloat(self.cropWidth) * factor)
        let cropFinalHeight = (CGFloat(self.cropHeight) * factor)

        print("self.cropStartX = \(self.cropStartX), factor = \(factor) = cropStartX = \(cropFinalX)")
        print("self.cropStartY = \(self.cropStartY), factor = \(factor) = cropFinalY = \(cropFinalY)")
        print("self.cropWidth = \(self.cropWidth), factor = \(factor) = cropFinalWidth = \(cropFinalWidth)")
        print("self.cropHeight = \(self.cropHeight), factor = \(factor) = cropFinalHeight = \(cropFinalHeight)")

        let cropFinalRect = CGRect(x: cropFinalX, y: cropFinalY, width: cropFinalWidth, height: cropFinalHeight)

        let croppedImage = self.CropImage(image: self.filterTempImage!, cropRect: cropFinalRect)

        imageView.image = croppedImage

        self.view.setNeedsDisplay()
        */

        let infoO = calculateRectOfImageInImageView(imageView: imageView);
        print("IMG X = \(infoO.origin.x), Y = \(infoO.origin.y)")

        let cropRect = CGRect(x: self.cropStartX - Int(imageView.realImageRect().origin.x),
                              y: self.cropStartY - Int(imageView.realImageRect().origin.y),
                              width: self.cropWidth,
                              height: self.cropHeight)

        let croppedImage = self.cropImage(self.filterTempImage!,
                                                                     toRect: cropRect,
                                                                     imageViewWidth: imageView.frame.width,
                                                                     imageViewHeight: imageView.frame.height)
        imageView.image = croppedImage

        self.originalImage = croppedImage

        self.view.setNeedsDisplay()

        stopCropping()
    }

    func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect, imageViewWidth: CGFloat, imageViewHeight: CGFloat) -> UIImage? {
        let imageViewScale = max(inputImage.size.width / imageViewWidth,
                                 inputImage.size.height / imageViewHeight)

        // Scale cropRect to handle images larger than shown-on-screen size
        let cropZone = CGRect(x: cropRect.origin.x * imageViewScale,
                              y: cropRect.origin.y * imageViewScale,
                              width: cropRect.size.width * imageViewScale,
                              height: cropRect.size.height * imageViewScale)

        // Perform cropping in Core Graphics
        guard let cutImageRef: CGImage = inputImage.cgImage?.cropping(to: cropZone)
            else {
                return nil
        }

        // Return image to UIImage
        let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
        return croppedImage
    }

    /*
    private func CropImage( image:UIImage , cropRect:CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(cropRect.size, false, 0);
        let context = UIGraphicsGetCurrentContext();

        context?.translateBy(x: 0.0, y: image.size.height);
        context?.scaleBy(x: 1.0, y: -1.0);
        context?.draw(image.cgImage!, in: CGRect(x:0, y:0, width:image.size.width, height:image.size.height), byTiling: false);
        context?.clip(to: [cropRect]);

        let croppedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        return croppedImage!;
    }
    */

    @objc func stopCropping() {
    print("ImageEditViewController :: stopCropping");

        self.navigationController?.navigationBar.isHidden = false

        self.cropButtonActive = false;

        self.cropSaveButton.isHidden = true
        self.cropAbortButton.isHidden = true
        self.cropDetectButton.isHidden = true
        self.cropRectangleDrawn = false

        imageView.isUserInteractionEnabled = false

        self.filterButton.isEnabled = true
        self.rotateButton.isEnabled = true

        //self.originalImage = self.filterTempImage
        self.filterTempImage = nil

        self.cropRectangleLayer.removeFromSuperlayer()

        self.topLeftToBottomRightLayer.removeFromSuperlayer()
        self.topRoghtToBottomLeftLayer.removeFromSuperlayer()

        self.topLeftHandle.removeFromSuperview()
        self.topRightHandle.removeFromSuperview()
        self.bottomLeftHandle.removeFromSuperview()
        self.bottomRightHandle.removeFromSuperview()
        self.centerHandle.removeFromSuperview()

        self.filterTempImage = nil;
    }

    func calculateRectOfImageInImageView(imageView: UIImageView) -> CGRect {
        let imageViewSize = imageView.frame.size
        let imgSize = imageView.image?.size

        guard let imageSize = imgSize else {
            return CGRect.zero
        }

        let scaleWidth = imageViewSize.width / imageSize.width
        let scaleHeight = imageViewSize.height / imageSize.height
        let aspect = fmin(scaleWidth, scaleHeight)

        var imageRect = CGRect(x: 0, y: 0, width: imageSize.width * aspect, height: imageSize.height * aspect)
        // Center image
        imageRect.origin.x = (imageViewSize.width - imageRect.size.width) / 2
        imageRect.origin.y = (imageViewSize.height - imageRect.size.height) / 2

        // Add imageView offset
        imageRect.origin.x += imageView.frame.origin.x
        imageRect.origin.y += imageView.frame.origin.y

        return imageRect
    }

     @objc func startCropping() {
        print("ImageEditViewController :: startCropping");

        self.navigationController?.navigationBar.isHidden = true

        self.cropButtonActive = true;

        self.filterButton.isEnabled = false
        self.rotateButton.isEnabled = false

        self.cropDetectButton.isHidden = false

        imageView.isUserInteractionEnabled = true

        self.filterTempImage = self.originalImage

        /*
        let info = imageView.contentClippingRect
        print("IMG width = \(info.size.width), height = \(info.size.height)")
        print("IMG width O = \(imageView.image!.size.width), height O = \(imageView.image!.size.height)")

        let factor = info.size.height / imageView.image!.size.height
        print("factor = \(info.size.height) / \(imageView.image!.size.height) = \(factor)")

        let infoO = calculateRectOfImageInImageView(imageView: imageView);
        print("IMG X = \(infoO.origin.x), Y = \(infoO.origin.y)")

        var factorView = infoO.origin.y / info.size.height;
        if(infoO.origin.y > infoO.origin.x) {
            factorView = infoO.origin.y / info.size.height
            print("factorView FROM Y = \(infoO.origin.y) / \(info.size.height) = \(factorView)")
        } else if infoO.origin.x > infoO.origin.y {
            factorView = infoO.origin.x / info.size.width
            print("factorView FROM X = \(infoO.origin.x) / \(info.size.width) = \(factorView)")
        } else {
            factorView = 100 / 100;
        }

        let detector:CIDetector = CIDetector(
            ofType: CIDetectorTypeRectangle,
            context: nil,
            options: [CIDetectorAccuracy : CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.41, CIDetectorMaxFeatureCount: 10]
            )!

        let sourceImage = CIImage(image: self.originalImage!)

        let features = detector.features(in: sourceImage!)

        print("features = \(features)")

        self.cropRectangleLayer.borderWidth = 2;
        //self.cropRectangleLayer.borderColor = UIColor.red.cgColor
        self.cropRectangleLayer.backgroundColor = UIColor.white.cgColor
        self.cropRectangleLayer.opacity = 0.5;
        self.cropRectangleLayer.strokeColor = UIColor.red.cgColor
        self.cropRectangleLayer.lineWidth = 2.0

        self.view.layer.addSublayer(self.cropRectangleLayer)

        let path = UIBezierPath()

        for feature in features {

            guard let rect = feature as? CIRectangleFeature else {
                continue
            }

            let topLeft = imageView.convertPoint(fromImagePoint: rect.topLeft)
            let topRight = imageView.convertPoint(fromImagePoint: rect.topRight)
            let bottomRight = imageView.convertPoint(fromImagePoint: rect.bottomLeft)
            let bottomLeft = imageView.convertPoint(fromImagePoint: rect.bottomRight)

            //path.move(to: rect.topLeft)
            //path.addLine(to: rect.topRight)
            //path.addLine(to: rect.bottomRight)
            //path.addLine(to: rect.bottomLeft)
            path.move(to: topLeft)
            path.addLine(to: topRight)
            path.addLine(to: bottomRight)
            path.addLine(to: bottomLeft)

            path.close()
        }

        self.cropRectangleLayer.path = path.cgPath;
        */

        //self.filterTempImage = self.originalImage
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first!

        if touch.view == imageView && self.cropRectangleDrawn {
            self.lastLocation = touch.location(in: self.view)

            let touchPoint:CGPoint =  touch.location(in: imageView)

            // touch IN Rect from left
            if Int(touchPoint.x) > self.cropStartX && Int(touchPoint.x) < (self.cropStartX + self.cropWidth) {
                //print("Touch in rect from left")
                // touch IN Rect from top
                if Int(touchPoint.y) > self.cropStartY && Int(touchPoint.y) < (self.cropStartY + self.cropHeight) {
                    //print("Touch in rect left move top")

                    // Move borders
                    let leftThreshold = (self.cropStartX + self.cropWidth/10*3) // 30% from left border
                    let rightThreshold = (self.cropStartX + self.cropWidth/10*7) // 30% from right border 100%
                    let topThreshold = (self.cropStartY + self.cropHeight/10*3) // 30% from top border 100%
                    let bottomThreshold = (self.cropStartY + self.cropHeight/10*7) // 30% from bottom border 100%

                    if(Int(touchPoint.x) < leftThreshold) { // Left
                        print("Touch in rect from left within \(leftThreshold)")
                        self.cropDragMove = true;
                        self.cropDragMoveDir = "left";
                    } else if(Int(touchPoint.x) > rightThreshold) { // Right
                        print("Touch in rect right move within \(rightThreshold)")
                        self.cropDragMove = true;
                        self.cropDragMoveDir = "right";
                    } else if(Int(touchPoint.y) < topThreshold && Int(touchPoint.x) > leftThreshold && Int(touchPoint.x) < rightThreshold) { // Top
                        print("Touch in rect top move within \(rightThreshold)")
                        self.cropDragMove = true;
                        self.cropDragMoveDir = "top";
                    } else if(Int(touchPoint.y) > bottomThreshold && Int(touchPoint.x) > leftThreshold && Int(touchPoint.x) < rightThreshold) { // // Bottom
                        print("Touch in rect bottom move within \(rightThreshold)")
                        self.cropDragMove = true;
                        self.cropDragMoveDir = "bottom";
                    } else {// Drag rect

                        self.cropDragStart = true;
                    }
                }
            }

            return
        }

        if touch.view == imageView && self.cropButtonActive && !self.cropRectangleDrawn {
            print("image touched draw rect")

            self.topLeftToBottomRightLayer.removeFromSuperlayer()
            self.topRoghtToBottomLeftLayer.removeFromSuperlayer()

            let location = touch.location(in: imageView)
            print("Start x = \(location.x), Start y = \(location.y)")

            self.cropStartX = Int(location.x);
            self.cropStartY = Int(location.y);

            self.cropWidth = self.cropMinWidth
            self.cropHeight = self.cropMinHeight

            self.cropRectangle = CGRect(x: self.cropStartX, y: self.cropStartY, width: self.cropWidth, height: self.cropHeight)

            self.cropRectangleLayer.path = UIBezierPath(roundedRect: self.cropRectangle, cornerRadius: 2).cgPath
            self.cropRectangleLayer.borderWidth = 2;
            //self.cropRectangleLayer.borderColor = UIColor.red.cgColor
            self.cropRectangleLayer.backgroundColor = UIColor.white.cgColor
            self.cropRectangleLayer.opacity = 0.35;
            self.cropRectangleLayer.strokeColor = textColor.cgColor
            self.cropRectangleLayer.lineWidth = 2.0

            self.view.layer.addSublayer(self.cropRectangleLayer)

            let handleHalfSize = handleSize / 2;

            // top left handle
            self.topLeftHandle.frame = CGRect(x: self.cropStartX - handleHalfSize, y: self.cropStartY - handleHalfSize, width: handleSize, height: handleSize)
            self.topLeftHandle.setTitle(" ", for: .normal)
            if #available(iOS 13.0, *) {
                self.topLeftHandle.setImage(UIImage(systemName: "arrow.up"), for: .normal)
            }
            self.topLeftHandle.backgroundColor = textColor
            self.topLeftHandle.layer.cornerRadius = CGFloat(handleHalfSize)
            self.topLeftHandle.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8.0, bottom: 0, right: 8.0)

            self.view.addSubview(self.topLeftHandle)

            // topRightHandle
            self.topRightHandle.frame = CGRect(x: (self.cropStartX + self.cropMinWidth) - handleHalfSize, y: self.cropStartY - handleHalfSize, width: handleSize, height: handleSize)
            self.topRightHandle.setTitle(" ", for: .normal)
            if #available(iOS 13.0, *) {
                self.topRightHandle.setImage(UIImage(systemName: "arrow.right"), for: .normal)
            }
            self.topRightHandle.backgroundColor = textColor
            self.topRightHandle.layer.cornerRadius = CGFloat(handleHalfSize)
            self.topRightHandle.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8.0, bottom: 0, right: 8.0)
            self.view.addSubview(self.topRightHandle)

            // bottomLeftHandle
            self.bottomLeftHandle.frame = CGRect(x: self.cropStartX - handleHalfSize, y: (self.cropStartY + self.cropMinHeight) - handleHalfSize, width: handleSize, height: handleSize)
            self.bottomLeftHandle.setTitle(" ", for: .normal)
            if #available(iOS 13.0, *) {
                self.bottomLeftHandle.setImage(UIImage(systemName: "arrow.left"), for: .normal)
            }
            self.bottomLeftHandle.backgroundColor = textColor
            self.bottomLeftHandle.layer.cornerRadius = CGFloat(handleHalfSize)
            self.bottomLeftHandle.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8.0, bottom: 0, right: 8.0)
            self.view.addSubview(self.bottomLeftHandle)

            // bottomRightHandle
            self.bottomRightHandle.frame = CGRect(x: (self.cropStartX + self.cropMinWidth) - handleHalfSize, y: (self.cropStartY + self.cropMinHeight) - handleHalfSize, width: handleSize, height: handleSize)
            self.bottomRightHandle.setTitle(" ", for: .normal)
            if #available(iOS 13.0, *) {
                self.bottomRightHandle.setImage(UIImage(systemName: "arrow.down"), for: .normal)
            }
            self.bottomRightHandle.backgroundColor = textColor
            self.bottomRightHandle.layer.cornerRadius = CGFloat(handleHalfSize)
            self.bottomRightHandle.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8.0, bottom: 0, right: 8.0)
            self.view.addSubview(self.bottomRightHandle)

            // cen
            let centerX = self.cropStartX + (self.cropWidth / 2)
            let centerY = self.cropStartY + (self.cropHeight / 2)

            self.centerHandle.frame = CGRect(x: centerX - handleHalfSize, y: centerY - handleHalfSize, width: handleSize, height: handleSize)

            if #available(iOS 13.0, *) {
                self.centerHandle.setImage(UIImage(systemName: "crop"), for: .normal)

                self.centerHandle.layer.cornerRadius = CGFloat(handleHalfSize) // circular
                let spacing: CGFloat = 8.0
                self.centerHandle.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
            } else {
                self.centerHandle.setTitle("X", for: .normal)
                self.centerHandle.layer.cornerRadius = 5
            }

            self.centerHandle.backgroundColor = textColor
            self.centerHandle.tintColor = .white
            self.centerHandle.layer.borderColor = UIColor.black.cgColor
            self.centerHandle.clipsToBounds = true
            //self.centerHandle.isHidden = true

            self.view.addSubview(self.centerHandle)
        }
    }

    /*
    @objc func startDragHandle(sender: UIView) {
        print("ImageEditViewController :: startDragHandle");
        self.cropDragStart = true;
        self.centerHandle.isHidden = true
    }
    */

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        /*
        if let touch = touches.first {
            let location = touch.location(in: self.view)
            self.imageView.center = CGPoint(x: (location.x - self.lastLocation.x) + self.imageView.center.x, y: (location.y - self.lastLocation.y) + self.imageView.center.y)
            lastLocation = touch.location(in: self.view)
        }
        */

        guard let touch = touches.first else {
            return
        }

        // Move Side rect
        if touch.view == imageView && self.cropButtonActive && self.cropDragMove {
            let location = touch.location(in: self.view)

            if self.cropDragMoveDir == "top" {
                print("move TOP border \(location.y)")

                let oldH = self.cropHeight
                let oldY = self.cropStartY
                let newY = Int(location.y)

                self.cropHeight = oldH + (oldY - newY)

                print("move TOP border \(self.cropHeight)")

                if self.cropHeight < self.cropMinHeight {
                    self.cropHeight = self.cropMinHeight
                }

                self.cropStartY = newY

            } else if self.cropDragMoveDir == "right" {
                print("move RIGHT border \(location.x)")

                let moveX = Int(location.x)
                self.cropWidth = (moveX - self.cropStartX)

                if self.cropWidth < self.cropMinWidth {
                    self.cropWidth = self.cropMinWidth
                }

            } else if self.cropDragMoveDir == "bottom" {
                print("move BOTTOM border \(location.y)")

                let moveY = Int(location.y)
                self.cropHeight = (moveY - self.cropStartY)

                if self.cropHeight < self.cropMinHeight {
                    self.cropHeight = self.cropMinHeight
                }

            } else if self.cropDragMoveDir == "left" {
                print("move LEFT border \(location.x)")

                let oldW = self.cropWidth
                let oldX = self.cropStartX
                let newX = Int(location.x)

                self.cropWidth = oldW + (oldX - newX)

                print("move LEFT border \(self.cropWidth)")

                if self.cropWidth < self.cropMinHeight {
                    self.cropWidth = self.cropMinHeight
                }

                self.cropStartX = newX
            }

            let newRect = CGRect(x: self.cropStartX, y: self.cropStartY, width: self.cropWidth, height: self.cropHeight)
            self.cropRectangleLayer.path = UIBezierPath(roundedRect: newRect, cornerRadius: 2).cgPath

            let handleHalfSize = handleSize / 2;

            // topLeftHandle --> top center
            //self.topLeftHandle.frame = CGRect(x: self.cropStartX - handleHalfSize, y: self.cropStartY - handleHalfSize, width: handleSize, height: handleSize)
            self.topLeftHandle.frame = CGRect(x: self.cropStartX + (self.cropWidth/2) - handleHalfSize, y: self.cropStartY - handleHalfSize, width: handleSize, height: handleSize)

            // topRightHandle --> right center
            //self.topRightHandle.frame = CGRect(x: (self.cropStartX + self.cropWidth) - handleHalfSize, y: self.cropStartY - handleHalfSize, width: handleSize, height: handleSize)
            self.topRightHandle.frame = CGRect(x: (self.cropStartX + self.cropWidth) - handleHalfSize, y: self.cropStartY + (self.cropHeight/2) - handleHalfSize, width: handleSize, height: handleSize)

            // bottomRightHandle --> bottom center
            //self.bottomRightHandle.frame = CGRect(x: (self.cropStartX + self.cropWidth) - handleHalfSize, y: (self.cropStartY + self.cropHeight) - handleHalfSize, width: handleSize, height: handleSize)
            self.bottomRightHandle.frame = CGRect(x: (self.cropStartX + (self.cropWidth/2)) - handleHalfSize, y: (self.cropStartY + self.cropHeight) - handleHalfSize, width: handleSize, height: handleSize)

            // bottomLeftHandle --> right center
            //self.bottomLeftHandle.frame = CGRect(x: self.cropStartX - handleHalfSize, y: (self.cropStartY + self.cropHeight) - handleHalfSize, width: handleSize, height: handleSize)
            self.bottomLeftHandle.frame = CGRect(x: self.cropStartX - handleHalfSize, y: (self.cropStartY + (self.cropHeight/2)) - handleHalfSize, width: handleSize, height: handleSize)

            // center
            let centerX = self.cropStartX + (self.cropWidth / 2)
            let centerY = self.cropStartY + (self.cropHeight / 2)
            self.centerHandle.frame = CGRect(x: centerX - handleHalfSize, y: centerY - handleHalfSize, width: handleSize, height: handleSize)

            return
        }

        // Drag rect
        if touch.view == imageView && self.cropButtonActive && self.cropDragStart {
            let location = touch.location(in: self.view)

            self.cropStartX = Int(location.x) - (self.cropWidth / 2)
            self.cropStartY = Int(location.y) - (self.cropHeight / 2)

            if self.cropStartX < 0 {
                self.cropStartX = 0
            }

            if self.cropStartX > (Int(location.x) + self.cropWidth) {
                self.cropStartX = (Int(location.x) + self.cropWidth)
            }

            if self.cropStartY < 0 {
                self.cropStartY = 0
            }

            if self.cropStartY > (Int(location.y) + self.cropHeight) {
                self.cropStartY = (Int(location.y) + self.cropHeight)
            }

            // Check min height/width
            if self.cropWidth < self.cropMinWidth {
                self.cropWidth = self.cropMinWidth
            }

            if self.cropHeight < self.cropMinHeight {
                self.cropHeight = self.cropMinHeight
            }


            let newRect = CGRect(x: self.cropStartX, y: self.cropStartY, width: self.cropWidth, height: self.cropHeight)
            self.cropRectangleLayer.path = UIBezierPath(roundedRect: newRect, cornerRadius: 2).cgPath

            let handleHalfSize = handleSize / 2;

            // topLeftHandle --> top center
            //self.topLeftHandle.frame = CGRect(x: self.cropStartX - handleHalfSize, y: self.cropStartY - handleHalfSize, width: handleSize, height: handleSize)
            self.topLeftHandle.frame = CGRect(x: self.cropStartX + (self.cropWidth/2) - handleHalfSize, y: self.cropStartY - handleHalfSize, width: handleSize, height: handleSize)

            // topRightHandle --> right center
            //self.topRightHandle.frame = CGRect(x: (self.cropStartX + self.cropWidth) - handleHalfSize, y: self.cropStartY - handleHalfSize, width: handleSize, height: handleSize)
            self.topRightHandle.frame = CGRect(x: (self.cropStartX + self.cropWidth) - handleHalfSize, y: self.cropStartY + (self.cropHeight/2) - handleHalfSize, width: handleSize, height: handleSize)

            // bottomRightHandle --> bottom center
            //self.bottomRightHandle.frame = CGRect(x: (self.cropStartX + self.cropWidth) - handleHalfSize, y: (self.cropStartY + self.cropHeight) - handleHalfSize, width: handleSize, height: handleSize)
            self.bottomRightHandle.frame = CGRect(x: (self.cropStartX + (self.cropWidth/2)) - handleHalfSize, y: (self.cropStartY + self.cropHeight) - handleHalfSize, width: handleSize, height: handleSize)

            // bottomLeftHandle --> right center
            //self.bottomLeftHandle.frame = CGRect(x: self.cropStartX - handleHalfSize, y: (self.cropStartY + self.cropHeight) - handleHalfSize, width: handleSize, height: handleSize)
            self.bottomLeftHandle.frame = CGRect(x: self.cropStartX - handleHalfSize, y: (self.cropStartY + (self.cropHeight/2)) - handleHalfSize, width: handleSize, height: handleSize)

            // center
            let centerX = self.cropStartX + (self.cropWidth / 2)
            let centerY = self.cropStartY + (self.cropHeight / 2)
            self.centerHandle.frame = CGRect(x: centerX - handleHalfSize, y: centerY - handleHalfSize, width: handleSize, height: handleSize)

            return
        }

        // draw rect
        if touch.view == imageView && !self.cropRectangleDrawn {
            let location = touch.location(in: imageView)
            print("Move x = \(location.x), y = \(location.y)")

            //self.cropStartX = Int(location.x);
            //self.cropStartY = Int(location.y);
            //self.cropWidth = self.cropMinWidth
            //self.cropHeight = self.cropMinHeight

            self.cropWidth = Int(location.x)-self.cropStartX
            if self.cropWidth < self.cropMinWidth {
                self.cropWidth = self.cropMinWidth
            }

            self.cropHeight = Int(location.y)-self.cropStartY
            if self.cropHeight < self.cropMinHeight {
                self.cropHeight = self.cropMinHeight
            }

            //print("cropWidth = \(self.cropWidth)")
            //print("cropHeight = \(self.cropHeight)")
            print("cropWidth = \(self.cropWidth), cropHeight = \(self.cropHeight)")

            let newRect = CGRect(x: self.cropStartX, y: self.cropStartY, width: self.cropWidth, height: self.cropHeight)
            self.cropRectangleLayer.path = UIBezierPath(roundedRect: newRect, cornerRadius: 2).cgPath

            let handleHalfSize = handleSize / 2;

            // topLeftHandle --> top center
            //self.topLeftHandle.frame = CGRect(x: self.cropStartX - handleHalfSize, y: self.cropStartY - handleHalfSize, width: handleSize, height: handleSize)
            self.topLeftHandle.frame = CGRect(x: self.cropStartX + (self.cropWidth/2) - handleHalfSize, y: self.cropStartY - handleHalfSize, width: handleSize, height: handleSize)

            // topRightHandle --> right center
            //self.topRightHandle.frame = CGRect(x: (self.cropStartX + self.cropWidth) - handleHalfSize, y: self.cropStartY - handleHalfSize, width: handleSize, height: handleSize)
            self.topRightHandle.frame = CGRect(x: (self.cropStartX + self.cropWidth) - handleHalfSize, y: self.cropStartY + (self.cropHeight/2) - handleHalfSize, width: handleSize, height: handleSize)

            // bottomRightHandle --> bottom center
            //self.bottomRightHandle.frame = CGRect(x: (self.cropStartX + self.cropWidth) - handleHalfSize, y: (self.cropStartY + self.cropHeight) - handleHalfSize, width: handleSize, height: handleSize)
            self.bottomRightHandle.frame = CGRect(x: (self.cropStartX + (self.cropWidth/2)) - handleHalfSize, y: (self.cropStartY + self.cropHeight) - handleHalfSize, width: handleSize, height: handleSize)

            // bottomLeftHandle --> right center
            //self.bottomLeftHandle.frame = CGRect(x: self.cropStartX - handleHalfSize, y: (self.cropStartY + self.cropHeight) - handleHalfSize, width: handleSize, height: handleSize)
            self.bottomLeftHandle.frame = CGRect(x: self.cropStartX - handleHalfSize, y: (self.cropStartY + (self.cropHeight/2)) - handleHalfSize, width: handleSize, height: handleSize)

            // center
            let centerX = self.cropStartX + (self.cropWidth / 2)
            let centerY = self.cropStartY + (self.cropHeight / 2)
            self.centerHandle.frame = CGRect(x: centerX - handleHalfSize, y: centerY - handleHalfSize, width: handleSize, height: handleSize)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first!

        self.cropDragStart = false;
        self.cropDragMove = false;
        self.cropDragMoveDir = "";
        //self.centerHandle.isHidden = false

        if touch.view == imageView && !self.cropRectangleDrawn {
            print("image released")

            self.cropRectangleDrawn = true

            self.cropSaveButton.isHidden = false
            self.cropAbortButton.isHidden = false

            /*
            // stroke
            let topLeftToBottomRightPath = UIBezierPath();
            topLeftToBottomRightPath.move(to: CGPoint(x: self.cropStartX, y: self.cropStartY))
            topLeftToBottomRightPath.addLine(to: CGPoint(x: (self.cropStartX + self.cropWidth), y: (self.cropStartY + self.cropHeight)))

            self.topLeftToBottomRightLayer.fillColor = textColor.cgColor
            self.topLeftToBottomRightLayer.lineWidth = 1
            self.topLeftToBottomRightLayer.strokeColor = textColor.cgColor
            self.topLeftToBottomRightLayer.path = topLeftToBottomRightPath.cgPath
            self.view.layer.addSublayer(self.topLeftToBottomRightLayer)


            let topRoghtToBottomLeftPath = UIBezierPath();
            topRoghtToBottomLeftPath.move(to: CGPoint(x: (self.cropStartX + self.cropWidth), y: self.cropStartY))
            topRoghtToBottomLeftPath.addLine(to: CGPoint(x: self.cropStartX, y: (self.cropStartY + self.cropHeight)))

            self.topRoghtToBottomLeftLayer.fillColor = textColor.cgColor
            self.topRoghtToBottomLeftLayer.lineWidth = 1
            self.topRoghtToBottomLeftLayer.strokeColor = textColor.cgColor
            self.topRoghtToBottomLeftLayer.path = topRoghtToBottomLeftPath.cgPath
            self.view.layer.addSublayer(self.topRoghtToBottomLeftLayer)
            */

            self.view.setNeedsDisplay()
        }
    }

    /*
    func drawLine() {
        self.topLeftToBottomRightLayer.fillColor = textColor.cgColor
        self.topLeftToBottomRightLayer.lineWidth = 1
        self.topLeftToBottomRightLayer.strokeColor = textColor.cgColor
        self.topLeftToBottomRightLayer.path = self.topLeftToBottomRightLine.cgPath
        self.view.layer.addSublayer(self.topLeftToBottomRightLayer)
        self.view.setNeedsDisplay()
    }
    */

    /*
     * Rotate Button clicked, rotate
     */
    @objc func startRotate() {
        print("ImageEditViewController :: startRotate");

        self.navigationController?.navigationBar.isHidden = true

        self.rotateButtonActive = true;

        //self.rotateButton.backgroundColor = .green
        //self.rotateButton.tintColor = .white;

        self.rotateSlider.isHidden = false;
        self.rotateButtonNinety.isHidden = false;

        self.cropButton.isEnabled = false;
        self.filterButton.isEnabled = false;

        self.filterTempImage = self.originalImage
    }

    @objc func stopRotate() {
        print("ImageEditViewController :: stopRotate");

        self.navigationController?.navigationBar.isHidden = false

        self.rotateButtonActive = false;

        //self.rotateButton.backgroundColor = .white
        //self.rotateButton.tintColor = .black;

        self.rotateSlider.isHidden = true;
        self.rotateButtonNinety.isHidden = true;

        self.cropButton.isEnabled = true;
        self.filterButton.isEnabled = true;

        self.originalImage = self.filterTempImage
        self.filterTempImage = nil;

        self.filterButtonReset.isHidden = true
    }

    @objc func toggleRotate(sender: UIBarButtonItem) {
        print("ImageEditViewController :: toggleRotate");

        if self.rotateButtonActive {
            self.stopRotate()
        } else {
            self.startRotate();
        }
    }

    @objc func setRotateNinety(sender: UIButton) {
        print("ImageEditViewController :: setRotateNinety", self.rotateDegrees);

        if self.rotateDegrees < 90 {
            self.rotateDegrees = 90

            if #available(iOS 13.0, *) {
                self.rotateButton.setImage(nil, for: .normal)
            }
            self.rotateButton.setTitle("90°", for: .normal)

        } else if self.rotateDegrees >= 90 && self.rotateDegrees < 180 {
            self.rotateDegrees = 180

            if #available(iOS 13.0, *) {
                self.rotateButton.setImage(nil, for: .normal)
            }
            self.rotateButton.setTitle("180°", for: .normal)

        } else if self.rotateDegrees >= 180 && self.rotateDegrees < 270 {
            self.rotateDegrees = 270

            if #available(iOS 13.0, *) {
                self.rotateButton.setImage(nil, for: .normal)
            }
            self.rotateButton.setTitle("270°", for: .normal)

        } else {
            self.rotateDegrees = 0;

            if #available(iOS 13.0, *) {
                self.rotateButton.setTitle("", for: .normal)
                self.rotateButton.setImage(UIImage(systemName: "goforward"), for: .normal)
            } else {
                self.rotateButton.setTitle("Drehen", for: .normal)
            }
        }

        print("ImageEditViewController :: setRotateNinety", self.rotateDegrees);

        self.rotateSlider.setValue(Float(self.rotateDegrees), animated: true)

        let image = self.originalImage

        let rotatedImage = image!.imageRotatedByDegrees(degrees: CGFloat(self.rotateDegrees), flip: false)

        self.filterTempImage = rotatedImage
        imageView.image = rotatedImage

        //self.filterButtonReset.isHidden = false
    }

    @objc func setRotateSlider(sender: UISlider) {
        print("ImageEditViewController :: setRotate", sender.value);

        //imageView.transform = CGAffineTransform(rotationAngle: Int(sender.value).degreesToRadians)//

        if sender.value > 1 {
            if #available(iOS 13.0, *) {
                self.rotateButton.setImage(nil, for: .normal)
            }

            var title = String(Int(sender.value))
            title.append("°")
            self.rotateButton.setTitle(title, for: .normal)
        } else {
            if #available(iOS 13.0, *) {
                self.rotateButton.setTitle("", for: .normal)
                self.rotateButton.setImage(UIImage(systemName: "goforward"), for: .normal)
            } else {
                self.rotateButton.setTitle("Drehen", for: .normal)
            }
        }

        let image = self.originalImage

        let rotatedImage = image!.imageRotatedByDegrees(degrees: CGFloat(sender.value), flip: false)

        self.filterTempImage = rotatedImage
        imageView.image = rotatedImage

        //self.filterButtonReset.isHidden = false
    }

    /*
     * Back Button clicked, send abort signal
     */
    @objc func back(sender: UIBarButtonItem) {
        print("ImageEditViewController :: back");

        self.delegate?.imageEdited(resultCode: 101, resultString: "ABORTED", imagePath: self.filePath as NSString)

        self.dismiss(animated: true, completion: nil)
    }

    /*
     * BaSaveck Button clicked, send abort signal
     */
    @objc func save(sender: UIBarButtonItem) {
        print("ImageEditViewController :: save");

        self.showSpinner(onView: self.view)

        let image:UIImage = imageView.image!;

        var withName:String = UUID().uuidString

        if self.destType == "png" {
            withName.append(".png")

            if let data = image.pngData() {
                let dirPath = getDocumentDirectoryPath()
                let imageFileUrl = URL(fileURLWithPath: dirPath.appendingPathComponent(withName) as String)
                do {
                    try data.write(to: imageFileUrl)
                    print("Successfully saved image at path: \(imageFileUrl)")
                    print("Successfully saved image at path: \(imageFileUrl.absoluteString)")

                    self.delegate?.imageEdited(resultCode: 201, resultString: "SUCCESS", imagePath: imageFileUrl.absoluteString as NSString)

                    self.dismiss(animated: true, completion: {
                        self.removeSpinner()
                    })


                } catch {
                    print("Error saving image: \(error)")
                }
            }
        } else {
            withName.append(".jpg")

            if let data = image.jpegData(compressionQuality: 1) {
                let dirPath = getDocumentDirectoryPath()
                let imageFileUrl = URL(fileURLWithPath: dirPath.appendingPathComponent(withName) as String)
                do {
                    try data.write(to: imageFileUrl)
                    print("Successfully saved image at path: \(imageFileUrl)")
                    print("Successfully saved image at path: \(imageFileUrl.absoluteString)")

                    self.delegate?.imageEdited(resultCode: 201, resultString: "SUCCESS", imagePath: imageFileUrl.absoluteString as NSString)

                    self.dismiss(animated: true, completion: {
                        self.removeSpinner()
                    })


                } catch {
                    print("Error saving image: \(error)")
                }
            }
        }
    }

    func getDocumentDirectoryPath() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }

    func addImageView(name:String = "default") {
        //let image = UIImage(named: name)
        //imageView.image = image

        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height

        let url = NSURL(string: filePath)

        if let data = try? NSData(contentsOf: url! as URL) {
            let givenImage = UIImage(data: data as Data)!;

            // fix orientation if image was retrived from camera (to upright)
            self.originalImage = givenImage.correctlyOrientedImage()

            imageView.image = self.originalImage

            imageView.contentMode = .scaleAspectFit
            //imageView.contentMode = .top;
            imageView.clipsToBounds = true

            imageView.backgroundColor = UIColor.white
            imageView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)

            view.addSubview(imageView)
        } else { // image could not be read
            self.delegate?.imageEdited(resultCode: 401, resultString: "ERROR_OPTION_INPUTDATA_NOTEXISTS", imagePath: self.filePath as NSString)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

// https://stackoverflow.com/questions/27092354/rotating-uiimage-in-swift
extension UIImage {

    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        let radiansToDegrees: (CGFloat) -> CGFloat = {
            return $0 * (180.0 / CGFloat.pi)
        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat.pi
        }

        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: .zero, size: size))
        let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size

        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap?.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)

        //   // Rotate the image context
        bitmap?.rotate(by: degreesToRadians(degrees))

        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat

        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }

        bitmap?.scaleBy(x: yFlip, y: -1.0)
        let rect = CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)

        bitmap?.draw(cgImage!, in: rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
}

extension UIImage {
    struct RotationOptions: OptionSet {
        let rawValue: Int

        static let flipOnVerticalAxis = RotationOptions(rawValue: 1)
        static let flipOnHorizontalAxis = RotationOptions(rawValue: 2)
    }

    func rotated(by rotationAngle: Measurement<UnitAngle>, options: RotationOptions = []) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let rotationInRadians = CGFloat(rotationAngle.converted(to: .radians).value)
        let transform = CGAffineTransform(rotationAngle: rotationInRadians)
        var rect = CGRect(origin: .zero, size: self.size).applying(transform)
        rect.origin = .zero

        let renderer = UIGraphicsImageRenderer(size: rect.size)
        return renderer.image { renderContext in
            renderContext.cgContext.translateBy(x: rect.midX, y: rect.midY)
            renderContext.cgContext.rotate(by: rotationInRadians)

            let x = options.contains(.flipOnVerticalAxis) ? -1.0 : 1.0
            let y = options.contains(.flipOnHorizontalAxis) ? 1.0 : -1.0
            renderContext.cgContext.scaleBy(x: CGFloat(x), y: CGFloat(y))

            let drawRect = CGRect(origin: CGPoint(x: -self.size.width/2, y: -self.size.height/2), size: self.size)
            renderContext.cgContext.draw(cgImage, in: drawRect)
        }
    }
}

extension UIImage {

    public convenience init?(_ systemItem: UIBarButtonItem.SystemItem) {

        guard let sysImage = UIImage.imageFrom(systemItem: systemItem)?.cgImage else {
            return nil
        }

        self.init(cgImage: sysImage)
    }

    private class func imageFrom(systemItem: UIBarButtonItem.SystemItem) -> UIImage? {

        let sysBarButtonItem = UIBarButtonItem(barButtonSystemItem: systemItem, target: nil, action: nil)

        //MARK:- Adding barButton into tool bar and rendering it.
        let toolBar = UIToolbar()
        toolBar.setItems([sysBarButtonItem], animated: false)
        toolBar.snapshotView(afterScreenUpdates: true)

        if  let buttonView = sysBarButtonItem.value(forKey: "view") as? UIView{
            for subView in buttonView.subviews {
                if subView is UIButton {
                    let button = subView as! UIButton
                    let image = button.imageView!.image!
                    return image
                }
            }
        }
        return nil
    }
}

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

extension BinaryInteger {
    var degreesToRadians: CGFloat { CGFloat(self) * .pi / 180 }
}

// https://stackoverflow.com/questions/29179692/how-can-i-convert-from-degrees-to-radians
extension FloatingPoint {
    var degreesToRadians: Self { self * .pi / 180 }
    var radiansToDegrees: Self { self * 180 / .pi }
}

// https://stackoverflow.com/questions/4401567/getting-a-black-and-white-uiimage-not-grayscale
extension UIImage {
    func toBlackAndWhite() -> UIImage? {

        let imgBrightness = self.brightness

        guard let ciImage = CIImage(image: self) else {
            return nil
        }

        guard let grayImage = CIFilter(name: "CIPhotoEffectNoir", parameters: [kCIInputImageKey: ciImage])?.outputImage else {
            return nil
        }

        // brightness
        var brightnessLevel:Double = 0;
        if(imgBrightness.isLess(than: Double(48))) { // sehr dunkel
            brightnessLevel = 0.272
        } else if(Double(100).isLess(than: imgBrightness)) { // könnte heller sein
            brightnessLevel = 0.125
        }

        guard let brightnessImage = CIFilter(name: "CIColorControls", parameters: [kCIInputImageKey: grayImage, kCIInputBrightnessKey: brightnessLevel])?.outputImage else {
            return nil
        }

        let bAndWParams: [String: Any] = [kCIInputImageKey: brightnessImage,
                                          kCIInputContrastKey: 50.0,
                                          kCIInputBrightnessKey: 10.0]
        guard let bAndWImage = CIFilter(name: "CIColorControls", parameters: bAndWParams)?.outputImage else {
            return nil
        }
        guard let cgImage = CIContext(options: nil).createCGImage(bAndWImage, from: bAndWImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

// https://gist.github.com/adamcichy/2d00c7a54009b4a9751ba513749c485e
extension CGImage {
    var brightness: Double {
        get {
            let imageData = self.dataProvider?.data
            let ptr = CFDataGetBytePtr(imageData)
            var x = 0
            var result: Double = 0
            for _ in 0..<self.height {
                for _ in 0..<self.width {
                    let r = ptr![0]
                    let g = ptr![1]
                    let b = ptr![2]
                    result += (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))
                    x += 1
                }
            }
            let bright = result / Double (x)
            return bright
        }
    }
}

extension UIImage {
    var brightness: Double {
        get {
            return (self.cgImage?.brightness)!
        }
    }
}

extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}


// Cropping
extension UIImageView {

    // MARK: - Methods
    func realImageRect() -> CGRect {
        let imageViewSize = self.frame.size
        let imgSize = self.image?.size

        guard let imageSize = imgSize else {
            return CGRect.zero
        }

        let scaleWidth = imageViewSize.width / imageSize.width
        let scaleHeight = imageViewSize.height / imageSize.height
        let aspect = fmin(scaleWidth, scaleHeight)

        var imageRect = CGRect(x: 0, y: 0, width: imageSize.width * aspect, height: imageSize.height * aspect)

        // Center image
        imageRect.origin.x = (imageViewSize.width - imageRect.size.width) / 2
        imageRect.origin.y = (imageViewSize.height - imageRect.size.height) / 2

        // Add imageView offset
        imageRect.origin.x += self.frame.origin.x
        imageRect.origin.y += self.frame.origin.y

        return imageRect
    }
}

extension UIImage {
    func correctlyOrientedImage() -> UIImage {
        if self.imageOrientation == .up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        return normalizedImage ?? self;
    }
}

// https://raw.githubusercontent.com/nubbel/UIImageView-GeometryConversion/master/UIImageView-GeometryConvesion.swift
extension UIImageView {

    func convertPoint(fromImagePoint imagePoint: CGPoint) -> CGPoint {
        guard let imageSize = image?.size else { return CGPoint.zero }

        var viewPoint = imagePoint
        let viewSize = bounds.size

        let ratioX = viewSize.width / imageSize.width
        let ratioY = viewSize.height / imageSize.height

        switch contentMode {
        case .scaleAspectFit: fallthrough
        case .scaleAspectFill:
            var scale : CGFloat = 0

            if contentMode == .scaleAspectFit {
                scale = min(ratioX, ratioY)
            }
            else {
                scale = max(ratioX, ratioY)
            }

            viewPoint.x *= scale
            viewPoint.y *= scale

            viewPoint.x += (viewSize.width  - imageSize.width  * scale) / 2.0
            viewPoint.y += (viewSize.height - imageSize.height * scale) / 2.0

        case .scaleToFill: fallthrough
        case .redraw:
            viewPoint.x *= ratioX
            viewPoint.y *= ratioY
        case .center:
            viewPoint.x += viewSize.width / 2.0  - imageSize.width  / 2.0
            viewPoint.y += viewSize.height / 2.0 - imageSize.height / 2.0
        case .top:
            viewPoint.x += viewSize.width / 2.0 - imageSize.width / 2.0
        case .bottom:
            viewPoint.x += viewSize.width / 2.0 - imageSize.width / 2.0
            viewPoint.y += viewSize.height - imageSize.height
        case .left:
            viewPoint.y += viewSize.height / 2.0 - imageSize.height / 2.0
        case .right:
            viewPoint.x += viewSize.width - imageSize.width
            viewPoint.y += viewSize.height / 2.0 - imageSize.height / 2.0
        case .topRight:
            viewPoint.x += viewSize.width - imageSize.width
        case .bottomLeft:
            viewPoint.y += viewSize.height - imageSize.height
        case .bottomRight:
            viewPoint.x += viewSize.width  - imageSize.width
            viewPoint.y += viewSize.height - imageSize.height
        case.topLeft: fallthrough
        default:
            break
        }

         return viewPoint
    }

    func convertRect(fromImageRect imageRect: CGRect) -> CGRect {
        let imageTopLeft = imageRect.origin
        let imageBottomRight = CGPoint(x: imageRect.maxX, y: imageRect.maxY)

        let viewTopLeft = convertPoint(fromImagePoint: imageTopLeft)
        let viewBottomRight = convertPoint(fromImagePoint: imageBottomRight)

        var viewRect : CGRect = .zero
        viewRect.origin = viewTopLeft
        viewRect.size = CGSize(width: abs(viewBottomRight.x - viewTopLeft.x), height: abs(viewBottomRight.y - viewTopLeft.y))
        return viewRect
    }

    func convertPoint(fromViewPoint viewPoint: CGPoint) -> CGPoint {
        guard let imageSize = image?.size else { return CGPoint.zero }

        var imagePoint = viewPoint
        let viewSize = bounds.size

        let ratioX = viewSize.width / imageSize.width
        let ratioY = viewSize.height / imageSize.height

        switch contentMode {
        case .scaleAspectFit: fallthrough
        case .scaleAspectFill:
            var scale : CGFloat = 0

            if contentMode == .scaleAspectFit {
                scale = min(ratioX, ratioY)
            }
            else {
                scale = max(ratioX, ratioY)
            }

            // Remove the x or y margin added in FitMode
            imagePoint.x -= (viewSize.width  - imageSize.width  * scale) / 2.0
            imagePoint.y -= (viewSize.height - imageSize.height * scale) / 2.0

            imagePoint.x /= scale;
            imagePoint.y /= scale;

        case .scaleToFill: fallthrough
        case .redraw:
            imagePoint.x /= ratioX
            imagePoint.y /= ratioY
        case .center:
            imagePoint.x -= (viewSize.width - imageSize.width)  / 2.0
            imagePoint.y -= (viewSize.height - imageSize.height) / 2.0
        case .top:
            imagePoint.x -= (viewSize.width - imageSize.width)  / 2.0
        case .bottom:
            imagePoint.x -= (viewSize.width - imageSize.width)  / 2.0
            imagePoint.y -= (viewSize.height - imageSize.height);
        case .left:
            imagePoint.y -= (viewSize.height - imageSize.height) / 2.0
        case .right:
            imagePoint.x -= (viewSize.width - imageSize.width);
            imagePoint.y -= (viewSize.height - imageSize.height) / 2.0
        case .topRight:
            imagePoint.x -= (viewSize.width - imageSize.width);
        case .bottomLeft:
            imagePoint.y -= (viewSize.height - imageSize.height);
        case .bottomRight:
            imagePoint.x -= (viewSize.width - imageSize.width)
            imagePoint.y -= (viewSize.height - imageSize.height)
        case.topLeft: fallthrough
        default:
            break
        }

        return imagePoint
    }

    func convertRect(fromViewRect viewRect : CGRect) -> CGRect {
        let viewTopLeft = viewRect.origin
        let viewBottomRight = CGPoint(x: viewRect.maxX, y: viewRect.maxY)

        let imageTopLeft = convertPoint(fromImagePoint: viewTopLeft)
        let imageBottomRight = convertPoint(fromImagePoint: viewBottomRight)

        var imageRect : CGRect = .zero
        imageRect.origin = imageTopLeft
        imageRect.size = CGSize(width: abs(imageBottomRight.x - imageTopLeft.x), height: abs(imageBottomRight.y - imageTopLeft.y))
        return imageRect
    }

}

var vSpinner : UIView?
extension UIViewController {
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center

        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }

        vSpinner = spinnerView
    }

    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}
