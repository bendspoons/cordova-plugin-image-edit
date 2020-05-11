import UIKit

protocol ImageEditDelegate: class {
    func imageEdited(resultCode: NSInteger, resultString: NSString, imagePath: NSString)
}

class ImageEditViewController: UIViewController {
    var imageView:UIImageView = UIImageView.init()
    
    var filePath:String = "";
    
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
    var cropRectangleLayer = CAShapeLayer();
    var cropRectangle = CGRect();
    
    var topLeftHandle = UIButton(type: .roundedRect)
    var topRightHandle = UIButton(type: .roundedRect)
    var bottomRightHandle = UIButton(type: .roundedRect)
    var bottomLeftHandle = UIButton(type: .roundedRect)

    
    var topLeftToBottomRightLayer = CAShapeLayer()
    var topRoghtToBottomLeftLayer = CAShapeLayer()

    var cropStartX:Int = 0;
    var cropStartY:Int = 0;
    
    var cropWidth:Int = 0;
    var cropHeight:Int = 0;

    var cropMinWidth:Int = 20;
    var cropMinHeight:Int = 20;
    
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

    // Zuschnitt execute
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
     
    @objc func stopCropping() {
    print("ImageEditViewController :: stopCropping");

        self.cropButtonActive = false;

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

        self.cropButtonActive = true;
        
        self.filterButton.isEnabled = false
        self.rotateButton.isEnabled = false
        
        imageView.isUserInteractionEnabled = true

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
            options: [CIDetectorAccuracy : CIDetectorAccuracyHigh]
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
        
        self.cropRectangleLayer.path = path.cgPath;
        */
        
        //self.filterTempImage = self.originalImage
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /*if let touch = touches.first {
            self.lastLocation = touch.location(in: self.view)
        }*/
        
        let touch:UITouch = touches.first!
        if touch.view == imageView && self.cropButtonActive {
            print("image touched")
        
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
            
            // top left handle
            self.topLeftHandle.frame = CGRect(x: self.cropStartX - 10, y: self.cropStartY - 10, width: 20, height: 20)
            self.topLeftHandle.setTitle(" ", for: .normal)
            self.topLeftHandle.backgroundColor = textColor
            self.topLeftHandle.layer.cornerRadius = 10
            self.topLeftHandle.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8.0, bottom: 0, right: 8.0)
            self.view.addSubview(self.topLeftHandle)
            
            // topRightHandle
            self.topRightHandle.frame = CGRect(x: (self.cropStartX + self.cropMinWidth) - 10, y: self.cropStartY - 10, width: 20, height: 20)
            self.topRightHandle.setTitle(" ", for: .normal)
            self.topRightHandle.backgroundColor = textColor
            self.topRightHandle.layer.cornerRadius = 10
            self.topRightHandle.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8.0, bottom: 0, right: 8.0)
            self.view.addSubview(self.topRightHandle)
            
            // bottomLeftHandle
            self.bottomLeftHandle.frame = CGRect(x: self.cropStartX - 10, y: (self.cropStartY + self.cropMinHeight) - 10, width: 20, height: 20)
            self.bottomLeftHandle.setTitle(" ", for: .normal)
            self.bottomLeftHandle.backgroundColor = textColor
            self.bottomLeftHandle.layer.cornerRadius = 10
            self.bottomLeftHandle.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8.0, bottom: 0, right: 8.0)
            self.view.addSubview(self.bottomLeftHandle)
            
            // bottomRightHandle
            self.bottomRightHandle.frame = CGRect(x: (self.cropStartX + self.cropMinWidth) - 10, y: (self.cropStartY + self.cropMinHeight) - 10, width: 20, height: 20)
            self.bottomRightHandle.setTitle(" ", for: .normal)
            self.bottomRightHandle.backgroundColor = textColor
            self.bottomRightHandle.layer.cornerRadius = 10
            self.bottomRightHandle.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8.0, bottom: 0, right: 8.0)
            self.view.addSubview(self.bottomRightHandle)
        }
    }
    
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
        
        if touch.view == imageView {
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
            
            // topRightHandle
            self.topRightHandle.frame = CGRect(x: (self.cropStartX + self.cropWidth) - 10, y: self.cropStartY - 10, width: 20, height: 20)
            
            // bottomRightHandle
            self.bottomRightHandle.frame = CGRect(x: (self.cropStartX + self.cropWidth) - 10, y: (self.cropStartY + self.cropHeight) - 10, width: 20, height: 20)
            
            // bottomLeftHandle
            self.bottomLeftHandle.frame = CGRect(x: self.cropStartX - 10, y: (self.cropStartY + self.cropHeight) - 10, width: 20, height: 20)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first!
            if touch.view == imageView {
            print("image released")
            
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
        
        self.delegate?.imageEdited(resultCode: 0, resultString: "ABORTED", imagePath: self.filePath as NSString)
        
        self.dismiss(animated: true, completion: nil)
    }

    /*
     * BaSaveck Button clicked, send abort signal
     */
    @objc func save(sender: UIBarButtonItem) {
        print("ImageEditViewController :: save");
        
        let image:UIImage = imageView.image!;
        
        var withName:String = UUID().uuidString
        withName.append(".jpg")
        
        if let data = image.jpegData(compressionQuality: 100) {
            let dirPath = getDocumentDirectoryPath()
            let imageFileUrl = URL(fileURLWithPath: dirPath.appendingPathComponent(withName) as String)
            do {
                try data.write(to: imageFileUrl)
                print("Successfully saved image at path: \(imageFileUrl)")
                print("Successfully saved image at path: \(imageFileUrl.absoluteString)")
                
                self.delegate?.imageEdited(resultCode: 2, resultString: imageFileUrl.absoluteString as NSString, imagePath: imageFileUrl.absoluteString as NSString)
                
                self.dismiss(animated: true, completion: nil)
                
            } catch {
                print("Error saving image: \(error)")
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
            self.originalImage = UIImage(data: data as Data)!;

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
