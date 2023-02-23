//
//  WoowaveUITest.swift
//  WoowaveUItester
//
//  Created by Igor Jovcevski on 1.2.23.
//

import Foundation
import UIKit



public class WoowaveUI {
    public init() {

        }
public struct ElementData {
    var fontSize: CGFloat = 0.0
    var img: UIImage?
    var type: String
    var contrast: (String, String, Double) = ("", "", 0)
    var text: String?
    var truncated: Bool = false
    var cutoff: Bool = false
    var colors: [UIColor] = []
}

    
    public  func testVC(sut:UIViewController, window:UIWindow)->[ElementData] {
        FileManager.removeAllFilesInDocumentsDirectory()
     let reports1 = self.tryWithFont(sut: sut, fontScaleFactor: 1.0)
       // return reports1
        let reports2 = self.tryWithFont(sut: sut, fontScaleFactor: 2.0)
        let reports3 =   self.tryWithFont(sut: sut, fontScaleFactor: 3.0)
        return reports1 + reports2 + reports3
}

public  func tryWithFont(sut:UIViewController,fontScaleFactor: Double) -> [ElementData] {
    var elements: [ElementData] = []
    
    let allButtons: [UIButton] = self.getSubviewsOfView(view: sut.view)
    let allLabels: [UILabel] = self.getSubviewsOfView(view: sut.view) + allButtons.map {$0.titleLabel!}
    allLabels.forEach { label in
        if label.adjustsFontForContentSizeCategory {
            label.font = label.font.withSize(label.font.pointSize * fontScaleFactor)
            label.sizeToFit()
            sut.view?.setNeedsLayout()
        }
    }
    allButtons.forEach { button in
        guard let btnTitleLabel = button.titleLabel else { return }
        if btnTitleLabel.adjustsFontForContentSizeCategory {
            btnTitleLabel.font = btnTitleLabel.font.withSize(btnTitleLabel.font.pointSize * fontScaleFactor)
            btnTitleLabel.sizeToFit()
            sut.view?.setNeedsLayout()
        }
    }

    let screenshot = self.fullScreenShot(sut: sut)

    self.writeImageToCameraRoll(screenshot, name: "SCALE:\(fontScaleFactor)" + UUID().uuidString+".png")

    

    allLabels.forEach { label in
        //label.backgroundColor = .yellow
//        if #available(iOS 15.0, *) {
//            guard  ((label.superview as? UIButton) != nil), (label.superview as? UIButton)?.configuration == .none else  {
//                return
//
//            }
//        } else {
//            // Fallback on earlier versions
//        }
        
        
        
        
        let parentButton = label.superview as? UIButton
        var isParentButtonNewTypeOfButton = false
        if #available(iOS 15.0, *) {
            isParentButtonNewTypeOfButton = parentButton?.configuration != .none
        } else {
            // Fallback on earlier versions
        }
        
        var lblFrejm = parentButton != nil ? label.globalFrameForButtonTitle : label.globalFrame
        if isParentButtonNewTypeOfButton {
            lblFrejm = label.globalFrameOfTitleLabelForNewTypeOfButton
        }
        assert (lblFrejm?.size.height != .zero)
        var labelScreenshot = self.cutOff(from: screenshot, frame: lblFrejm!)!
      //  var labelScreenshot = self.cutOff(from: screenshot, frame:label.globalFrame!)!
        //  let colors = Vibrant.from(labelScreenshot).getPalette()
      //  let colors = labelScreenshot.getColorsArray(quality: .highest)
        let clrs = getColorsFromImage(img: labelScreenshot)
        // [label.textColor.coreImageColor.toUIColor ]
        let str = label.text

        let contrast2 = clrs[0].color.contrastRatio(with: clrs.count > 1 ? clrs[1].color : clrs[0].color)
      //  let contrast = getLowestContrast(colors: clrs)

        elements.append(ElementData(fontSize: label.font.pointSize, img: labelScreenshot, type: label.superview is UIButton ? "button label" : "label", contrast: (clrs[0].name, clrs[clrs.count > 1 ? 1 : 0].name, contrast2), text: label.text, truncated: label.isTruncated, cutoff: label.isClipped))

        let str3 = clrs.map { $0.name }
        
        let str5 = label.superview is UIButton ? "\(lblFrejm!)-SCALE:\(fontScaleFactor)-LBL-IN-BTN" : "\(lblFrejm!)-SCALE:\(fontScaleFactor)-LBL"
        writeImageToCameraRoll(labelScreenshot, name: "\(str5)-\(String(describing: label.text ?? "")) \(str3)-\(label.font.pointSize)-\(Double(contrast2).roundTo(places: 2))--\(label.isTruncated ? "TRUNCATED" : "") - \(label.isClipped ? "CLIPPED" : "").png")
    }

    allButtons.forEach { button in

        
//        if #available(iOS 15.0, *) {
//            guard  button.configuration == .none else  {
//                return
//                
//            }
//        } else {
//            // Fallback on earlier versions
//        }
        
        
        
        let buttonScreenshot = cutOff(from: screenshot, frame: button.globalFrame!)!

        let colors = buttonScreenshot.getColors(quality: .lowest)

        let str = button.titleLabel?.text
        let clrStrings = [ColorManager.getClosestColorName(color: (colors?.primary.coreImageColor.toUIColor)!), ColorManager.getClosestColorName(color: (colors?.secondary!.coreImageColor.toUIColor)!), ColorManager.getClosestColorName(color: (colors?.detail!.coreImageColor.toUIColor)!), ColorManager.getClosestColorName(color: (colors?.background!.coreImageColor.toUIColor)!)]

        var btnBackground: UIColor = button.backgroundColor ?? .clear
        var btnTitleColor: UIColor = button.titleLabel!.textColor!

        if (btnBackground.cgColor.components!.count) < 4 {
            var red, green, blue, alpha: CGFloat!
            (red: red, green: green, blue: blue, alpha: alpha) = btnBackground.components

            btnBackground = UIColor(r: red, g: green, b: blue, a: alpha)
        }

        if (button.titleLabel?.textColor?.cgColor.components!.count)! < 4 {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0

            // note here:
            button.titleLabel?.textColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            //   button.titleLabel?.textColor?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            btnTitleColor = UIColor(r: red, g: green, b: blue, a: alpha)
        }

        let clrs = [buttonScreenshot.pixelColor(x: 2, y: 2), buttonScreenshot.pixelColor(x: 10, y: 10)]

        let contrast = getLowestContrast(colors: clrs.compactMap({ $0 as! UIColor }))

        elements.append(ElementData(fontSize: button.titleLabel?.font.pointSize ?? 0, img: buttonScreenshot, type: "button", contrast: contrast, text: button.titleLabel?.text, truncated: button.titleLabel?.isTruncated ?? false, cutoff: button.titleLabel?.isClipped ?? false))

        let MutedString = " *primary \(ColorManager.getClosestColorName(color: (colors!.primary)!))"
        let LightMutedString = " *secondary \(ColorManager.getClosestColorName(color: colors!.secondary!))"
        let DarkVibrantString = " *detail \(ColorManager.getClosestColorName(color: colors!.detail!))"
        let VibrantString = " *background \(ColorManager.getClosestColorName(color: colors!.background!))"
//
        let allStrings = MutedString + LightMutedString + DarkVibrantString + VibrantString

        let clr4 = clrs.map { ColorManager.getClosestColorName(color: $0) }

        writeImageToCameraRoll(buttonScreenshot, name: "\(String(describing: button.globalFrame ?? .zero) )-SCALE:\(fontScaleFactor)-BTN-\(String(describing: button.titleLabel?.text ?? ""))-\(clr4)-\(button.titleLabel?.font.pointSize ?? 0.0)-\(contrast.0)-\(contrast.1)\(contrast.2.roundTo(places: 2))-\(button.titleLabel?.isTruncated ?? false ? "TRUNCATED" : "") - \(button.titleLabel?.isClipped ?? false ? "CLIPPED" : "").png" )
    }
    
    var reports:[String] = []
    
    elements.map {
        if $0.cutoff {
            reports.append("\($0.type) with text: \($0.text ?? "") is CLIPPED!")
        }
        if $0.truncated {
            reports.append("\($0.type) with text: \($0.text ?? "") is TRUNCATED!")
        }
        if $0.contrast.2 < 3.0 {
            reports.append("\($0.type) with text: \($0.text ?? "") has low contrast!")
        }
    }
    
   return elements

    
}
    func getLowestContrast(colors: [UIColor]) -> (String, String, Double) {
        var lowestContrast = 1000.0
        var color1: String = ""
        var color2: String = ""
        for color in colors {
            for secondColor in colors {
                if color != secondColor && color.contrastRatio(with: secondColor) < lowestContrast && color.contrastRatio(with: secondColor) > 1.2 {
                    lowestContrast = color.contrastRatio(with: secondColor)

                    color1 = ColorManager.getClosestColorName(color: color.coreImageColor.toUIColor)
                    color2 = ColorManager.getClosestColorName(color: secondColor.coreImageColor.toUIColor)
                }
            }
        }
        return (color1, color2, lowestContrast)
    }


    func cutOff(from image: UIImage, frame: CGRect) -> UIImage? {
        var fr = frame
        var org = fr.origin
        fr.origin = CGPoint(x: org.x, y: org.y)
        let cgImage = image.cgImage?.cropping(to: fr)
        return UIImage(cgImage: cgImage!)
    }


    func fullScreenShot(sut:UIViewController) -> UIImage {
//       return  UIScreen.screenshot()
    //        let snapview = UIScreen.main.snapshotView(afterScreenUpdates: true)
    //        sut.view.addSubview(snapview)
    //                let renderer = UIGraphicsImageRenderer(size: sut.view.bounds.size)
    //                let img = renderer.image { _ in
    //
    //                    sut.view.drawHierarchy(in: sut.view.bounds, afterScreenUpdates: true)
    ////                    snapview.removeFromSuperview()
    //                }
    //              return img
    var screenshotImage: UIImage?
        let layer = sut.view.layer
   // let layer = UIApplication.shared.keyWindow!.layer
    let scale = UIScreen.main.scale
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale)
    let context = UIGraphicsGetCurrentContext()!
    layer.render(in: context)
    screenshotImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return screenshotImage!
}

 func screenshot(_ view: UIView) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
    view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

 func cgImage(from ciImage: CIImage) -> CGImage? {
    let context = CIContext(options: nil)
    return context.createCGImage(ciImage, from: ciImage.extent)
}

    
    func deleteTempFiles() {
        func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }

       
        
    }
    
 func writeImageToCameraRoll(_ image: UIImage, name: String?) {
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    if let data = image.pngData() {
        let filename = getDocumentsDirectory().appendingPathComponent(name ?? (UUID().uuidString + ".png"))
        print(filename)
        try? data.write(to: filename)
    }
}




 func getSubviewsOfView<T: UIView>(view: UIView) -> [T] {
var subviewArray = [T]()
if view.subviews.count == 0 {
    return subviewArray
}
for subview in view.subviews {
    subviewArray += getSubviewsOfView(view: subview) as [T]
    if let subview = subview as? T {
        subviewArray.append(subview)
    }
}
return subviewArray
}
    
}

// extension UIApplication {
//    func topMostViewController() -> UIViewController? {
//        return self.windows[0].rootViewController?.topMostViewController()
//    }
// }

extension UIScreen {
class func screenshot() -> UIImage {
    let view = main.snapshotView(afterScreenUpdates: false)

    UIGraphicsBeginImageContext(view.bounds.size)
    view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)

    let screenshot = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return screenshot!
}
}

struct SimpleColor {
let name: String
let color: UIColor
}

func getColorsFromImage(img: UIImage) -> [(name: String, color: UIColor, counted: Int)] {
var rez: [UIColor] = []

    let colors: [SimpleColor] = (0 ... 300).map { _ in
    let color = img.pixelColor(x: generateRandomNumber(min: 1, max: img.pixelWidth - 1), y: generateRandomNumber(min: 1, max: img.pixelHeight - 1))
    return SimpleColor(name: ColorManager.getClosestColorName(color: color), color: color)
}
var newDict = Dictionary(grouping: colors, by: { $0.name })
var firstColor: Dictionary<String, Array<UIColor>>
var testArr2: [(name: String, color: UIColor, counted: Int)] = []
for (key, value) in newDict {
    testArr2.append((name: value[0].name, color: value[0].color, counted: value.count))
}
testArr2.sort { $0.counted > $1.counted }
var rez2 = testArr2.prefix(2)

return Array(rez2)
}

func generateRandomNumber(min: Int, max: Int) -> Int {
let randomNum = Int(arc4random_uniform(UInt32(max) - UInt32(min)) + UInt32(min))
return randomNum
}


extension UIView{
var globalPoint :CGPoint? {
    return self.superview?.convert(self.frame.origin, to: nil)
}
    
    var globalFrameOfTitleLabelForNewTypeOfButton: CGRect? {
     
        self.sizeToFit()
        self.superview?.setNeedsLayout()
        var contentScale = self.contentScaleFactor
       // let mainView =  UIApplication.shared.keyWindow
        let mainView =  self.findViewController()?.view
        mainView?.setNeedsLayout()
        let btn = self.superview as? UIButton
        let titleLabelsInButton:[UILabel] = btn?.subviews.filter { $0 is UILabel } as! [UILabel]
        print(titleLabelsInButton)
        var frm = self.superview!.convert(self.frame, to: mainView)
        var btnfrm = btn!.superview!.convert(btn!.frame, to: mainView)
        
        
        let outfr = CGRect(origin: CGPoint(x: (btnfrm.origin.x + (((btnfrm.width) - frm.width) / 2 )) * contentScale, y: btnfrm.origin.y * contentScale), size: CGSize(width: self.bounds.width * contentScale, height: self.bounds.height * contentScale))
        return outfr
    }
    
var globalFrameForButtonTitle :CGRect? {
  //  let mainView =  UIApplication.shared.keyWindow
    let mainView = self.findViewController()?.view
   // var frm = mainView?.convert(self.frame, to: nil)
    var frm = self.convert(self.bounds, to: mainView)
    var frmOfparent = self.superview!.convert(self.superview!.bounds, to: mainView)
    var fr2 = frm
    frm.origin = CGPoint(x: ((fr2.origin.x ) * self.contentScaleFactor)  , y: ((max (fr2.origin.y, frmOfparent.origin.y) ) * self.contentScaleFactor )  )
    let siz = CGSize(width: frm.size.width ?? 0 , height: frm.size.height )
    frm.size = CGSize(width: siz.width * self.contentScaleFactor , height: min(siz.height * self.contentScaleFactor,self.contentScaleFactor  * (self.superview?.bounds.height)!))
//    assert(frm.size.width > 0.0)
    return frm
}
var globalFrame :CGRect? {
   // let mainView =  UIApplication.shared.keyWindow
    let mainView = self.findViewController()?.view
    let scale =  self is UIButton ? 3 : self.contentScaleFactor
 //   let scale = self.contentScaleFactor
    var frm = self.convert(self.bounds, to: mainView )
    var fr2 = frm
    frm.origin = CGPoint(x: ((fr2.origin.x)*scale ) - 10 , y: ((fr2.origin.y*scale )) - 10)
    let siz = CGSize(width: frm.size.width ?? 0 , height: frm.size.height )
    frm.size = CGSize(width: siz.width * scale + 20, height: siz.height * scale + 20 )
    
    if self is UIButton {
        print(self.frame)
    }
    assert(frm.size.width > 0.0)
    return frm
}
var globalFrameForLabel :CGRect? {
  // let mainView =  UIApplication.shared.keyWindow
    let mainView = self.findViewController()?.view
  //  let scale = self is UIButton ? 3 : self.contentScaleFactor
    let scale = self.contentScaleFactor
    var frm = self.convert(self.bounds, to: mainView )
    var fr2 = frm
    frm.origin = CGPoint(x: ((fr2.origin.x)*scale )  , y: ((fr2.origin.y*scale )) )
    let siz = CGSize(width: frm.size.width ?? 0 , height: frm.size.height )
    frm.size = CGSize(width: siz.width * scale , height: siz.height * scale  )
    if self is UIButton {
        print(self.frame)
    }
    assert(frm.size.width > 0.0)
    return frm
}
}

extension UIApplication {
var topViewController: UIViewController? {
    var topViewController: UIViewController? = nil
    if #available(iOS 13, *) {
        topViewController = connectedScenes.compactMap {
            return ($0 as? UIWindowScene)?.windows.filter { $0.isKeyWindow  }.first?.rootViewController
        }.first
    } else {
        topViewController = keyWindow?.rootViewController
    }
    if let presented = topViewController?.presentedViewController {
        topViewController = presented
    } else if let navController = topViewController as? UINavigationController {
        topViewController = navController.topViewController
    } else if let tabBarController = topViewController as? UITabBarController {
        topViewController = tabBarController.selectedViewController
    }
    return topViewController
}


}



extension UIImage {
func resized(to size: CGSize) -> UIImage {
    return UIGraphicsImageRenderer(size: size).image { _ in
        draw(in: CGRect(origin: .zero, size: size))
    }
}
}

extension UIView {
func findViewController() -> UIViewController? {
    if let nextResponder = self.next as? UIViewController {
        return nextResponder
    } else if let nextResponder = self.next as? UIView {
        return nextResponder.findViewController()
    } else {
        return nil
    }
}
}



extension FileManager {
    
    /// Remove all files and caches from directory.
    public static func removeAllFilesInDocumentsDirectory() {
        let fileManager = FileManager()
        let mainPaths = [
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)[0],
           
        ]
        mainPaths.forEach { mainPath in
            do {
                let content = try fileManager.contentsOfDirectory(atPath: mainPath)
                content.forEach { file in
                    do {
                        try fileManager.removeItem(atPath: URL(fileURLWithPath: mainPath).appendingPathComponent(file).path)
                    } catch {
                        // Crashlytics.crashlytics().record(error: error)
                    }
                }
            } catch {
                // Crashlytics.crashlytics().record(error: error)
            }
        }
    }
}
