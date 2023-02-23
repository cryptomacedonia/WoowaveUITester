//
//  UIImageColors.swift
//  IgorTemplateApp
//
//  Created by Igor Jovcevski on 26.12.22.
//

//import Foundation
//
//  UIImageColors.swift
//  https://github.com/jathu/UIImageColors
//
//  Created by Jathu Satkunarajah (@jathu) on 2015-06-11 - Toronto
//  Based on Cocoa version by Panic Inc. - Portland
//

#if os(OSX)
    import AppKit
    public typealias UIImage = NSImage
    public typealias UIColor = NSColor
#else
    import UIKit
#endif

public struct UIImageColors {
    public var background: UIColor!
    public var primary: UIColor!
    public var secondary: UIColor!
    public var detail: UIColor!
  
    public init(background: UIColor, primary: UIColor, secondary: UIColor, detail: UIColor) {
      self.background = background
      self.primary = primary
      self.secondary = secondary
      self.detail = detail
    }
}

public enum UIImageColorsQuality: CGFloat {
    case lowest = 50 // 50px
    case low = 100 // 100px
    case high = 250 // 250px
    case highest = 0 // No scale
}

fileprivate struct UIImageColorsCounter {
    let color: Double
    let count: Int
    init(color: Double, count: Int) {
        self.color = color
        self.count = count
    }
}

/*
    Extension on double that replicates UIColor methods. We DO NOT want these
    exposed outside of the library because they don't make sense outside of the
    context of UIImageColors.
*/
fileprivate extension Double {
    
    private var r: Double {
        return fmod(floor(self/1000000),1000000)
    }
    
    private var g: Double {
        return fmod(floor(self/1000),1000)
    }
    
    private var b: Double {
        return fmod(self,1000)
    }
    
    var isDarkColor: Bool {
        return (r*0.2126) + (g*0.7152) + (b*0.0722) < 127.5
    }
    
    var isBlackOrWhite: Bool {
        return (r > 232 && g > 232 && b > 232) || (r < 23 && g < 23 && b < 23)
    }
    
    func isDistinct(_ other: Double) -> Bool {
        let _r = self.r
        let _g = self.g
        let _b = self.b
        let o_r = other.r
        let o_g = other.g
        let o_b = other.b

        return (fabs(_r-o_r) > 63.75 || fabs(_g-o_g) > 63.75 || fabs(_b-o_b) > 63.75)
            && !(fabs(_r-_g) < 7.65 && fabs(_r-_b) < 7.65 && fabs(o_r-o_g) < 7.65 && fabs(o_r-o_b) < 7.65)
    }
    
    func with(minSaturation: Double) -> Double {
        // Ref: https://en.wikipedia.org/wiki/HSL_and_HSV
        
        // Convert RGB to HSV

        let _r = r/255
        let _g = g/255
        let _b = b/255
        var H, S, V: Double
        let M = fmax(_r,fmax(_g, _b))
        var C = M-fmin(_r,fmin(_g, _b))
        
        V = M
        S = V == 0 ? 0:C/V
        
        if minSaturation <= S {
            return self
        }
        
        if C == 0 {
            H = 0
        } else if _r == M {
            H = fmod((_g-_b)/C, 6)
        } else if _g == M {
            H = 2+((_b-_r)/C)
        } else {
            H = 4+((_r-_g)/C)
        }
        
        if H < 0 {
            H += 6
        }
        
        // Back to RGB
        
        C = V*minSaturation
        let X = C*(1-fabs(fmod(H,2)-1))
        var R, G, B: Double
        
        switch H {
        case 0...1:
            R = C
            G = X
            B = 0
        case 1...2:
            R = X
            G = C
            B = 0
        case 2...3:
            R = 0
            G = C
            B = X
        case 3...4:
            R = 0
            G = X
            B = C
        case 4...5:
            R = X
            G = 0
            B = C
        case 5..<6:
            R = C
            G = 0
            B = X
        default:
            R = 0
            G = 0
            B = 0
        }
        
        let m = V-C
        
        return (floor((R + m)*255)*1000000)+(floor((G + m)*255)*1000)+floor((B + m)*255)
    }
    
    func isContrasting(_ color: Double) -> Bool {
        let bgLum = (0.2126*r)+(0.7152*g)+(0.0722*b)+12.75
        let fgLum = (0.2126*color.r)+(0.7152*color.g)+(0.0722*color.b)+12.75
        if bgLum > fgLum {
            return 1.6 < bgLum/fgLum
        } else {
            return 1.6 < fgLum/bgLum
        }
    }
    
    var uicolor: UIColor {
        return UIColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
    }
    
    var pretty: String {
        return "\(Int(self.r)), \(Int(self.g)), \(Int(self.b))"
    }
}

extension UIImage {
    #if os(OSX)
        private func resizeForUIImageColors(newSize: CGSize) -> UIImage? {
                let frame = CGRect(origin: .zero, size: newSize)
                guard let representation = bestRepresentation(for: frame, context: nil, hints: nil) else {
                    return nil
                }
                let result = NSImage(size: newSize, flipped: false, drawingHandler: { (_) -> Bool in
                    return representation.draw(in: frame)
                })

                return result
        }
    #else
        private func resizeForUIImageColors(newSize: CGSize) -> UIImage? {
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
                defer {
                    UIGraphicsEndImageContext()
                }
                self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
                guard let result = UIGraphicsGetImageFromCurrentImageContext() else {
                    fatalError("UIImageColors.resizeForUIImageColors failed: UIGraphicsGetImageFromCurrentImageContext returned nil.")
                }

                return result
        }
    #endif

    public func getColors(quality: UIImageColorsQuality = .high, _ completion: @escaping (UIImageColors?) -> Void) {
        DispatchQueue.global().async {
            let result = self.getColors(quality: quality)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    public func getColors(quality: UIImageColorsQuality = .highest) -> UIImageColors? {
        var scaleDownSize: CGSize = self.size
        if quality != .highest {
            if self.size.width < self.size.height {
                let ratio = self.size.height/self.size.width
                scaleDownSize = CGSize(width: quality.rawValue/ratio, height: quality.rawValue)
            } else {
                let ratio = self.size.width/self.size.height
                scaleDownSize = CGSize(width: quality.rawValue, height: quality.rawValue/ratio)
            }
        }
        
        guard let resizedImage = self.resizeForUIImageColors(newSize: scaleDownSize) else { return nil }

        #if os(OSX)
            guard let cgImage = resizedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        #else
            guard let cgImage = resizedImage.cgImage else { return nil }
        #endif
        
        let width: Int = cgImage.width
        let height: Int = cgImage.height
        
        let threshold = Int(CGFloat(height)*0.01)
        var proposed: [Double] = [-1,-1,-1,-1]
        
        guard let data = CFDataGetBytePtr(cgImage.dataProvider!.data) else {
            fatalError("UIImageColors.getColors failed: could not get cgImage data.")
        }
        
        let imageColors = NSCountedSet(capacity: width*height)
        for x in 0..<width {
            for y in 0..<height {
                let pixel: Int = (y * cgImage.bytesPerRow) + (x * 4)
                if 127 <= data[pixel+3] {
                    imageColors.add((Double(data[pixel+2])*1000000)+(Double(data[pixel+1])*1000)+(Double(data[pixel])))
                }
            }
        }

        let sortedColorComparator: Comparator = { (main, other) -> ComparisonResult in
            let m = main as! UIImageColorsCounter, o = other as! UIImageColorsCounter
            if m.count < o.count {
                return .orderedDescending
            } else if m.count == o.count {
                return .orderedSame
            } else {
                return .orderedAscending
            }
        }
        
        var enumerator = imageColors.objectEnumerator()
        var sortedColors = NSMutableArray(capacity: imageColors.count)
        while let K = enumerator.nextObject() as? Double {
            let C = imageColors.count(for: K)
            if threshold < C {
                sortedColors.add(UIImageColorsCounter(color: K, count: C))
            }
        }
        sortedColors.sort(comparator: sortedColorComparator)

        var proposedEdgeColor: UIImageColorsCounter
        if 0 < sortedColors.count {
            proposedEdgeColor = sortedColors.object(at: 0) as! UIImageColorsCounter
        } else {
            proposedEdgeColor = UIImageColorsCounter(color: 0, count: 1)
        }
        
        if proposedEdgeColor.color.isBlackOrWhite && 0 < sortedColors.count {
            for i in 1..<sortedColors.count {
                let nextProposedEdgeColor = sortedColors.object(at: i) as! UIImageColorsCounter
                if Double(nextProposedEdgeColor.count)/Double(proposedEdgeColor.count) > 0.3 {
                    if !nextProposedEdgeColor.color.isBlackOrWhite {
                        proposedEdgeColor = nextProposedEdgeColor
                        break
                    }
                } else {
                    break
                }
            }
        }
        proposed[0] = proposedEdgeColor.color

        enumerator = imageColors.objectEnumerator()
        sortedColors.removeAllObjects()
        sortedColors = NSMutableArray(capacity: imageColors.count)
        let findDarkTextColor = !proposed[0].isDarkColor
        
        while var K = enumerator.nextObject() as? Double {
            K = K.with(minSaturation: 0.15)
            if K.isDarkColor == findDarkTextColor {
                let C = imageColors.count(for: K)
                sortedColors.add(UIImageColorsCounter(color: K, count: C))
            }
        }
        sortedColors.sort(comparator: sortedColorComparator)
        
        for color in sortedColors {
            let color = (color as! UIImageColorsCounter).color
            
            if proposed[1] == -1 {
                if color.isContrasting(proposed[0]) {
                    proposed[1] = color
                }
            } else if proposed[2] == -1 {
                if !color.isContrasting(proposed[0]) || !proposed[1].isDistinct(color) {
                    continue
                }
                proposed[2] = color
            } else if proposed[3] == -1 {
                if !color.isContrasting(proposed[0]) || !proposed[2].isDistinct(color) || !proposed[1].isDistinct(color) {
                    continue
                }
                proposed[3] = color
                break
            }
        }
        
        let isDarkBackground = proposed[0].isDarkColor
        for i in 1...3 {
            if proposed[i] == -1 {
                proposed[i] = isDarkBackground ? 255255255:0
            }
        }
        
        return UIImageColors(
            background: proposed[0].uicolor,
            primary: proposed[1].uicolor,
            secondary: proposed[2].uicolor,
            detail: proposed[3].uicolor
        )
    }
    
    public func getColorsArray(quality: UIImageColorsQuality = .highest) -> [UIColor] {
        var rez:[UIColor] = []
        var scaleDownSize: CGSize = self.size
        if quality != .highest {
            if self.size.width < self.size.height {
                let ratio = self.size.height/self.size.width
                scaleDownSize = CGSize(width: quality.rawValue/ratio, height: quality.rawValue)
            } else {
                let ratio = self.size.width/self.size.height
                scaleDownSize = CGSize(width: quality.rawValue, height: quality.rawValue/ratio)
            }
        }
        
        guard let resizedImage = self.resizeForUIImageColors(newSize: scaleDownSize) else { return [] }

        #if os(OSX)
            guard let cgImage = resizedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return [] }
        #else
            guard let cgImage = resizedImage.cgImage else { return [] }
        #endif
        
        let width: Int = cgImage.width
        let height: Int = cgImage.height
        
        let threshold = Int(CGFloat(height)*0.01)
        var proposed: [Double] = [-1,-1,-1,-1]
        
        guard let data = CFDataGetBytePtr(cgImage.dataProvider!.data) else {
            fatalError("UIImageColors.getColors failed: could not get cgImage data.")
        }
        
        let imageColors = NSCountedSet(capacity: width*height)
        for x in 0..<width {
            for y in 0..<height {
                let pixel: Int = (y * cgImage.bytesPerRow) + (x * 4)
                if 127 <= data[pixel+3] {
                    imageColors.add((Double(data[pixel+2])*1000000)+(Double(data[pixel+1])*1000)+(Double(data[pixel])))
                }
            }
        }

        let sortedColorComparator: Comparator = { (main, other) -> ComparisonResult in
            let m = main as! UIImageColorsCounter, o = other as! UIImageColorsCounter
            if m.count < o.count {
                return .orderedDescending
            } else if m.count == o.count {
                return .orderedSame
            } else {
                return .orderedAscending
            }
        }
        
        var enumerator = imageColors.objectEnumerator()
        var sortedColors = NSMutableArray(capacity: imageColors.count)
        while let K = enumerator.nextObject() as? Double {
            let C = imageColors.count(for: K)
            if threshold < C {
                sortedColors.add(UIImageColorsCounter(color: K, count: C))
            }
        }
        sortedColors.sort(comparator: sortedColorComparator)

        var proposedEdgeColor: UIImageColorsCounter
        if 0 < sortedColors.count {
            proposedEdgeColor = sortedColors.object(at: 0) as! UIImageColorsCounter
        } else {
            proposedEdgeColor = UIImageColorsCounter(color: 0, count: 1)
        }
        
        if proposedEdgeColor.color.isBlackOrWhite && 0 < sortedColors.count {
            for i in 1..<sortedColors.count {
                let nextProposedEdgeColor = sortedColors.object(at: i) as! UIImageColorsCounter
                if Double(nextProposedEdgeColor.count)/Double(proposedEdgeColor.count) > 0.3 {
                    if !nextProposedEdgeColor.color.isBlackOrWhite {
                        proposedEdgeColor = nextProposedEdgeColor
                        break
                    }
                } else {
                    break
                }
            }
        }
        proposed[0] = proposedEdgeColor.color

        enumerator = imageColors.objectEnumerator()
        sortedColors.removeAllObjects()
        sortedColors = NSMutableArray(capacity: imageColors.count)
        let findDarkTextColor = !proposed[0].isDarkColor
        
        while var K = enumerator.nextObject() as? Double {
            K = K.with(minSaturation: 0.15)
            if K.isDarkColor == findDarkTextColor {
                let C = imageColors.count(for: K)
                sortedColors.add(UIImageColorsCounter(color: K, count: C))
            }
        }
        sortedColors.sort(comparator: sortedColorComparator)
        
        for color in sortedColors {
            let color = (color as! UIImageColorsCounter).color
            
            if proposed[1] == -1 {
//               if color.isContrasting(proposed[0]) {
                if color.uicolor.isContrastingIgor(with: proposed[0].uicolor) {
                    proposed[1] = color
               }
            } else if proposed[2] == -1 {
                //  if !color.isContrasting(proposed[0]) || !proposed[1].isDistinct(color) {
                if !color.uicolor.isContrastingIgor(with:proposed[0].uicolor) {
                    continue
                }
                proposed[2] = color
            } else if proposed[3] == -1 {
//                if !color.isContrasting(proposed[0]) || !proposed[2].isDistinct(color) || !proposed[1].isDistinct(color) {
                if !color.uicolor.isContrastingIgor(with:proposed[0].uicolor) {
                    continue
                }
                proposed[3] = color
                break
            }
        }
        
        let isDarkBackground = proposed[0].isDarkColor
        for i in 1...3 {
            if proposed[i] == -1 {
                proposed[i] = isDarkBackground ? 255255255:0
            }
        }
        
//        var colors = sortedColors.map { ($0 as! UIImageColorsCounter).color.uicolor  }
//        var colors2:[UIColor] = []
//        for clr in colors  {
//
//            for secondColor in colors {
//
//                if clr != secondColor && clr.contrastRatio(with: secondColor) > 1.1 {
//                    colors2.append( clr)
//                    colors2.append(secondColor)
//                }
//
//            }
//
//        }
//
//        colors2 = Array(Set(colors2))
        
//        if sortedColors.count > 3 {
//
//
//
//
//        rez = [
//            (sortedColors[0] as! UIImageColorsCounter).color.uicolor,
//            (sortedColors[1] as! UIImageColorsCounter).color.uicolor,
//            (sortedColors[2] as! UIImageColorsCounter).color.uicolor,
//            (sortedColors[3] as! UIImageColorsCounter).color.uicolor,
//
//
//        ]
//        }
        
//        return colors2
        
        
        if proposed[0] != 0 {
            rez.append(proposed[0].uicolor)
        }
        if proposed[1] != 0 {
            rez.append(proposed[1].uicolor)
        }
        if proposed[2] != 0 {
            rez.append(proposed[2].uicolor)
        }
        if proposed[3] != 0 {
            rez.append(proposed[3].uicolor)
        }
        
//        var newRez:[UIColor] = []
//        for cl in rez {
//            var amIinContrastWithOthers = true
//            for cl2 in rez {
//                if cl.isContrasting(with: cl2) == false  {
//                    amIinContrastWithOthers = false
//                }
//            }
//            if amIinContrastWithOthers {
//                newRez.append(cl)
//            }
//        }
        
        
        
        return rez
//        return UIImageColors(
//            background: proposed[0].uicolor,
//            primary: proposed[1].uicolor,
//            secondary: proposed[2].uicolor,
//            detail: proposed[3].uicolor
//        )
    }
    
    
    
    
}

//extension UIColor {

//  `  static func contrastRatio(between color1: UIColor, and color2: UIColor) -> CGFloat {
//        // https://www.w3.org/TR/WCAG20-TECHS/G18.html#G18-tests
//
//        let luminance1 = color1.luminance()
//        let luminance2 = color2.luminance()
//
//        let luminanceDarker = min(luminance1, luminance2)
//        let luminanceLighter = max(luminance1, luminance2)
//
//        return (luminanceLighter + 0.05) / (luminanceDarker + 0.05)
//    }`
//
//    func contrastRatio(with color: UIColor) -> CGFloat {
//        return UIColor.contrastRatio(between: self, and: color)
//    }
//
//    func luminance() -> CGFloat {
//        // https://www.w3.org/TR/WCAG20-TECHS/G18.html#G18-tests
//
//        let ciColor = CIColor(color: self)
//
//        func adjust(colorComponent: CGFloat) -> CGFloat {
//            return (colorComponent < 0.04045) ? (colorComponent / 12.92) : pow((colorComponent + 0.055) / 1.055, 2.4)
//        }
//
//        return 0.2126 * adjust(colorComponent: ciColor.red) + 0.7152 * adjust(colorComponent: ciColor.green) + 0.0722 * adjust(colorComponent: ciColor.blue)
//    }
//}
extension UILabel {
    var isTruncated: Bool {
        var width  = calculatedWidth()
        return frame.width < intrinsicContentSize.width || width > (superview?.frame.width)!
    }

    var isClipped: Bool {
        var height  = calculatedHeight()
      return  frame.height < intrinsicContentSize.height || height > (superview?.frame.height)!
    }
}


extension UIColor {
    private struct Best {
        var color: (color: UIColor, name: String)
        var distance: CGFloat
    }
    
    func nearest() -> (color: UIColor, name: String) {
        let colors: [(color: UIColor, name: String)] = [
            (.black, "black"),
            (.blue, "blue"),
            (.brown, "brown"),
            (.cyan, "cyan"),
            (.gray, "gray"),
            (.green, "green"),
            (.magenta, "magenta"),
            (.orange, "orange"),
            (.purple, "purple"),
            (.red, "red"),
            (.white, "white"),
            (.yellow, "yellow")
        ]
        
        var best = Best(color: colors.first!, distance: CGFloat.greatestFiniteMagnitude)
        for color in colors {
            let distance = self.distance(from: color.color)
            if distance < best.distance {
                best = Best(color: color, distance: distance)
            }
        }
        return best.color
    }
    
    private func distance(from color: UIColor) -> CGFloat {
        

        
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        guard getRed(&r1, green: &g1, blue: &b1, alpha: &a1) && color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else {
            preconditionFailure("that didn't work")
        }

        let redDistance = (r1 - r2) * 0.299
        let greenDistance = (g1 - g2) * 0.587
        let blueDistance = (b1 - b2) * 0.114
        return (redDistance * redDistance) + (greenDistance * greenDistance) + (blueDistance * blueDistance)
    }
}

extension Double {
// Rounds the double to 'places' significant digits
  func roundTo(places:Int) -> Double {
    guard self != 0.0 else {
        return 0
    }
    let divisor = pow(10.0, Double(places) - ceil(log10(fabs(self))))
    return (self * divisor).rounded() / divisor
  }
}

extension UIView {
    
    class func image(view: UIView, subview: UIView? = nil) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0)
    
        view.drawHierarchy(in: view.frame, afterScreenUpdates: true)
        
        var image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()
        
        if(subview != nil){
            var rect = (subview?.frame)!
            rect.size.height *= image.scale  //MOST IMPORTANT
            rect.size.width *= image.scale    //TOOK ME DAYS TO FIGURE THIS OUT
            let imageRef = image.cgImage!.cropping(to: rect)
            image = UIImage(cgImage: imageRef!, scale: image.scale, orientation: image.imageOrientation)
        }
        
        return image
    }
    
    func image() -> UIImage? {
        return UIView.image(view: self)
    }
    
    func image(withSubview: UIView) -> UIImage? {
        return UIView.image(view: self, subview: withSubview)
    }
}


extension UIColor {
    func CIEDE2000(compare color: UIColor) -> CGFloat {
        // CIEDE2000, Sharma 2004 -> http://www.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf
        
        func rad2deg(r: CGFloat) -> CGFloat {
            return r * CGFloat(180/Double.pi)
        }
        
        func deg2rad(d: CGFloat) -> CGFloat {
            return d * CGFloat(Double.pi/180)
        }
        
        let k_l = CGFloat(1), k_c = CGFloat(1), k_h = CGFloat(1)
        
        let LAB1 = self.LAB
        let L_1 = LAB1[0], a_1 = LAB1[1], b_1 = LAB1[2]
        
        let LAB2 = color.LAB
        let L_2 = LAB2[0], a_2 = LAB2[1], b_2 = LAB2[2]
        
        let C_1ab = sqrt(pow(a_1, 2) + pow(b_1, 2))
        let C_2ab = sqrt(pow(a_2, 2) + pow(b_2, 2))
        let C_ab  = (C_1ab + C_2ab)/2
        
        let G = 0.5 * (1 - sqrt(pow(C_ab, 7)/(pow(C_ab, 7) + pow(25, 7))))
        let a_1_p = (1 + G) * a_1
        let a_2_p = (1 + G) * a_2
        
        let C_1_p = sqrt(pow(a_1_p, 2) + pow(b_1, 2))
        let C_2_p = sqrt(pow(a_2_p, 2) + pow(b_2, 2))
        
        // Read note 1 (page 23) for clarification on radians to hue degrees
        let h_1_p = (b_1 == 0 && a_1_p == 0) ? 0 : (atan2(b_1, a_1_p) + CGFloat(2 * Double.pi)) * CGFloat(180/Double.pi)
        let h_2_p = (b_2 == 0 && a_2_p == 0) ? 0 : (atan2(b_2, a_2_p) + CGFloat(2 * Double.pi)) * CGFloat(180/Double.pi)
        
        let deltaL_p = L_2 - L_1
        let deltaC_p = C_2_p - C_1_p
        
        var h_p: CGFloat = 0
        if (C_1_p * C_2_p) == 0 {
            h_p = 0
        } else if fabs(h_2_p - h_1_p) <= 180 {
            h_p = h_2_p - h_1_p
        } else if (h_2_p - h_1_p) > 180 {
            h_p = h_2_p - h_1_p - 360
        } else if (h_2_p - h_1_p) < -180 {
            h_p = h_2_p - h_1_p + 360
        }
        
        let deltaH_p = 2 * sqrt(C_1_p * C_2_p) * sin(deg2rad(d: h_p/2))
        
        let L_p = (L_1 + L_2)/2
        let C_p = (C_1_p + C_2_p)/2
        
        var h_p_bar: CGFloat = 0
        if (h_1_p * h_2_p) == 0 {
            h_p_bar = h_1_p + h_2_p
        } else if fabs(h_1_p - h_2_p) <= 180 {
            h_p_bar = (h_1_p + h_2_p)/2
        } else if fabs(h_1_p - h_2_p) > 180 && (h_1_p + h_2_p) < 360 {
            h_p_bar = (h_1_p + h_2_p + 360)/2
        } else if fabs(h_1_p - h_2_p) > 180 && (h_1_p + h_2_p) >= 360 {
            h_p_bar = (h_1_p + h_2_p - 360)/2
        }
        
        let T1 = cos(deg2rad(d: h_p_bar - 30))
        let T2 = cos(deg2rad(d: 2 * h_p_bar))
        let T3 = cos(deg2rad(d: (3 * h_p_bar) + 6))
        let T4 = cos(deg2rad(d: (4 * h_p_bar) - 63))
        let T = 1 - rad2deg(r: 0.17 * T1) + rad2deg(r: 0.24 * T2) - rad2deg(r: 0.32 * T3) + rad2deg(r: 0.20 * T4)
        
        let deltaTheta = 30 * exp(-pow((h_p_bar - 275)/25, 2))
        let R_c = 2 * sqrt(pow(C_p, 7)/(pow(C_p, 7) + pow(25, 7)))
        let S_l =  1 + ((0.015 * pow(L_p - 50, 2))/sqrt(20 + pow(L_p - 50, 2)))
        let S_c = 1 + (0.045 * C_p)
        let S_h = 1 + (0.015 * C_p * T)
        let R_t = -sin(deg2rad(d: 2 * deltaTheta)) * R_c
        
        // Calculate total
        
        let P1 = deltaL_p/(k_l * S_l)
        let P2 = deltaC_p/(k_c * S_c)
        let P3 = deltaH_p/(k_h * S_h)
        let deltaE = sqrt(pow(P1, 2) + pow(P2, 2) + pow(P3, 2) + (R_t * P2 * P3))
        
        return deltaE
    }
    var LAB: [CGFloat] {
        // http://www.easyrgb.com/index.php?X=MATH&H=07#text7
        
        let XYZ = self.XYZ
        
        func LAB_helper(c: CGFloat) -> CGFloat {
            return 0.008856 < c ? pow(c, 1/3) : ((7.787 * c) + (16/116))
        }
        
        let X: CGFloat = LAB_helper(c: XYZ[0]/95.047)
        let Y: CGFloat = LAB_helper(c: XYZ[1]/100.0)
        let Z: CGFloat = LAB_helper(c: XYZ[2]/108.883)
        
        let L: CGFloat = (116 * Y) - 16
        let A: CGFloat = 500 * (X - Y)
        let B: CGFloat = 200 * (Y - Z)
        
        return [L, A, B]
    }
}


extension UIColor {
    
    /**
        Create a UIColor with a string hex value.
     
        - parameter hex:     The hex color, i.e. "FF0072" or "#FF0072".
        - parameter alpha:   The opacity of the color, value between [0,1]. Optional. Default: 1
    */
    convenience init(hex: String, alpha: CGFloat = 1) {
        var hex = hex.replacingOccurrences(of: "#", with: "")
        
        guard hex.count == 3 || hex.count == 6 else {
            fatalError("fatalError(Sweetercolor): Hex characters must be either 3 or 6 characters.")
        }
        
        if hex.count == 3 {
            let tmp = hex
            hex = ""
            for c in tmp {
                hex += String([c,c])
            }
        }
        
        let scanner = Scanner(string: hex)
        var rgb: UInt32 = 0
        scanner.scanHexInt32(&rgb)
        
        let R = CGFloat((rgb >> 16) & 0xFF)/255
        let G = CGFloat((rgb >> 8) & 0xFF)/255
        let B = CGFloat(rgb & 0xFF)/255
        self.init(red: R, green: G, blue: B, alpha: alpha)
    }
    
    
    /**
        Create a UIColor with a RGB(A) values. The RGB values must *ALL*
        either be between [0, 1] OR [0, 255], do not interchange between either one.
     
        - parameter r:   Red value between [0, 1] OR [0, 255].
        - parameter g:   Green value between [0, 1] OR [0, 255].
        - parameter b:   Blue value between [0, 1] OR [0, 255].
        - parameter a:   The opacity of the color, value between [0, 1]. Optional. Default: 1
    */
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        if (1 < r) || (1 < g) || (1 < b) {
            self.init(red: r/255, green: g/255, blue: b/255, alpha: a)
        } else {
            self.init(red: r, green: g, blue: b, alpha: a)
        }
    }
    
    
    
    /**
        Create a UIColor with a HSB(A) values.
     
        - parameter h:   Hue value between [0, 1] OR [0, 360].
        - parameter s:   Saturation value between [0, 1] OR [0, 100].
        - parameter b:   Brightness value between [0, 1] OR [0, 100].
        - parameter a:   The opacity of the color, value between [0,1]. Optional. Default: 1
    */
    convenience init(h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat = 1) {
        if (1 < h) || (1 < s) || (1 < b) {
            self.init(hue: h/360, saturation: s/100, brightness: b/100, alpha: a)
        } else {
            self.init(hue: h, saturation: s, brightness: b, alpha: a)
        }
    }
    
    /**
        Return a *true* black color
    */
    class func black() -> UIColor {
        return UIColor(r: 0, g: 0, b: 0, a: 1)
    }
    
    /**
     Return a white color
    */
    class func white() -> UIColor {
        return UIColor(r: 1, g: 1, b: 1, a: 1)
    }
    
    
    /**
        Create a random color.
    */
    class func random() -> UIColor {
        // Random hue
        let H = CGFloat(arc4random_uniform(360))
        // Limit saturation to [70, 100]
        let S = CGFloat(arc4random_uniform(30) + 70)
        // Limit brightness to [30, 80]
        let B = CGFloat(arc4random_uniform(50) + 30)
        
        return UIColor(h: H, s: S, b: B, a: 1)
    }
    
    
    /**
        Comapre if two colors are equal.
        
        - parameter color:      A UIColor to compare.
        - parameter strict:     Should the colors have a 1% difference in the values
     
        - returns: A boolean, true if same (or very similar for strict) and false otherwize
     
     */
    func isEqual(to color: UIColor, strict: Bool = true) -> Bool {
        if strict {
            return self.isEqual(color)
        } else {
            let RGBA = self.RGBA
            let other = color.RGBA
            let margin = CGFloat(0.01)
            
            func comp(a: CGFloat, b: CGFloat) -> Bool {
                return abs(b-a) <= (a*margin)
            }
            
            return comp(a: RGBA[0], b: other[0]) && comp(a: RGBA[1], b: other[1]) && comp(a: RGBA[2], b: other[2]) && comp(a: RGBA[3], b: other[3])
        }
    }
    
    
    /**
        Get the red, green, blue and alpha values.
     
        - returns: An array of four CGFloat numbers from [0, 1] representing RGBA respectively.
    */
    var RGBA: [CGFloat] {
        var R: CGFloat = 0
        var G: CGFloat = 0
        var B: CGFloat = 0
        var A: CGFloat = 0
        self.getRed(&R, green: &G, blue: &B, alpha: &A)
        return [R,G,B,A]
    }
    
    
    
    /**
        Get the 8 bit red, green, blue and alpha values.
     
        - returns: An array of four CGFloat numbers from [0, 255] representing RGBA respectively.
    */
    var RGBA_8Bit: [CGFloat] {
        let RGBA = self.RGBA
        return [round(RGBA[0] * 255), round(RGBA[1] * 255), round(RGBA[2] * 255), RGBA[3]]
    }
    
    
    
    /**
        Get the hue, saturation, brightness and alpha values.
     
        - returns: An array of four CGFloat numbers from [0, 255] representing HSBA respectively.
    */
    var HSBA: [CGFloat] {
        var H: CGFloat = 0
        var S: CGFloat = 0
        var B: CGFloat = 0
        var A: CGFloat = 0
        self.getHue(&H, saturation: &S, brightness: &B, alpha: &A)
        return [H,S,B,A]
    }
    
    
    
    /**
        Get the 8 bit hue, saturation, brightness and alpha values.
     
        - returns: An array of four CGFloat numbers representing HSBA respectively. Ranges: H[0,360], S[0,100], B[0,100], A[0,1]
    */
    var HSBA_8Bit: [CGFloat] {
        let HSBA = self.HSBA
        return [round(HSBA[0] * 360), round(HSBA[1] * 100), round(HSBA[2] * 100), HSBA[3]]
    }
    
    
    
    /**
        Get the CIE XYZ values.
     
        - returns: An array of three CGFloat numbers representing XYZ respectively.
    */
    var XYZ: [CGFloat] {
        // http://www.easyrgb.com/index.php?X=MATH&H=02#text2
        
        let RGBA = self.RGBA
        
        func XYZ_helper(c: CGFloat) -> CGFloat {
            return (0.04045 < c ? pow((c + 0.055)/1.055, 2.4) : c/12.92) * 100
        }
        
        let R = XYZ_helper(c: RGBA[0])
        let G = XYZ_helper(c: RGBA[1])
        let B = XYZ_helper(c: RGBA[2])
        
        let X: CGFloat = (R * 0.4124) + (G * 0.3576) + (B * 0.1805)
        let Y: CGFloat = (R * 0.2126) + (G * 0.7152) + (B * 0.0722)
        let Z: CGFloat = (R * 0.0193) + (G * 0.1192) + (B * 0.9505)
        
        return [X, Y, Z]
    }
    
    
    
    /**
        Get the CIE L*ab values.
     
        - returns: An array of three CGFloat numbers representing LAB respectively.
    */
//    var LAB: [CGFloat] {
//        // http://www.easyrgb.com/index.php?X=MATH&H=07#text7
//
//        let XYZ = self.XYZ
//
//        func LAB_helper(c: CGFloat) -> CGFloat {
//            return 0.008856 < c ? pow(c, 1/3) : ((7.787 * c) + (16/116))
//        }
//
//        let X: CGFloat = LAB_helper(c: XYZ[0]/95.047)
//        let Y: CGFloat = LAB_helper(c: XYZ[1]/100.0)
//        let Z: CGFloat = LAB_helper(c: XYZ[2]/108.883)
//
//        let L: CGFloat = (116 * Y) - 16
//        let A: CGFloat = 500 * (X - Y)
//        let B: CGFloat = 200 * (Y - Z)
//
//        return [L, A, B]
//    }
    
    
    
    /**
        Get the relative luminosity value of the color. This follows the W3 specs of luminosity
        to give weight to colors which humans perceive more of.
     
        - returns: A CGFloat representing the relative luminosity.
    */
    var luminance: CGFloat {
        // http://www.w3.org/WAI/GL/WCAG20-TECHS/G18.html
        
        let RGBA = self.RGBA
        
        func lumHelper(c: CGFloat) -> CGFloat {
            return (c < 0.03928) ? (c/12.92): pow((c+0.055)/1.055, 2.4)
        }
        
        return 0.2126 * lumHelper(c: RGBA[0]) + 0.7152 * lumHelper(c: RGBA[1]) + 0.0722 * lumHelper(c: RGBA[2])
    }
    
    
    
    /**
        Determine if the color is dark based on the relative luminosity of the color.
     
        - returns: A boolean: true if it is dark and false if it is not dark.
    */
    var isDark: Bool {
        return self.luminance < 0.5
    }
    
    
    
    /**
        Determine if the color is light based on the relative luminosity of the color.
     
        - returns: A boolean: true if it is light and false if it is not light.
    */
    var isLight: Bool {
        return !self.isDark
    }
    
    
    
    /**
        Determine if this colors is darker than the compared color based on the relative luminosity of both colors.
     
        - parameter than color: A UIColor to compare.
     
        - returns: A boolean: true if this colors is darker than the compared color and false if otherwise.
    */
    func isDarker(than color: UIColor) -> Bool {
        return self.luminance < color.luminance
    }
    
    
    
    /**
        Determine if this colors is lighter than the compared color based on the relative luminosity of both colors.
     
        - parameter than color: A UIColor to compare.
     
        - returns: A boolean: true if this colors is lighter than the compared color and false if otherwise.
    */
    func isLighter(than color: UIColor) -> Bool {
        return !self.isDarker(than: color)
    }
    
    
    
    /**
        Determine if this color is either black or white.
     
        - returns: A boolean: true if this color is black or white and false otherwise.
    */
    var isBlackOrWhite: Bool {
        let RGBA = self.RGBA
        let isBlack = RGBA[0] < 0.09 && RGBA[1] < 0.09 && RGBA[2] < 0.09
        let isWhite = RGBA[0] > 0.91 && RGBA[1] > 0.91 && RGBA[2] > 0.91
        
        return isBlack || isWhite
    }
    
    
    
    /**
        Detemine the distance between two colors based on the way humans perceive them.
     
        - parameter compare color: A UIColor to compare.
     
        - returns: A CGFloat representing the deltaE
    */
    func CIE94(compare color: UIColor) -> CGFloat {
        // https://en.wikipedia.org/wiki/Color_difference#CIE94
        
        let k_L:CGFloat = 1
        let k_C:CGFloat = 1
        let k_H:CGFloat = 1
        let k_1:CGFloat = 0.045
        let k_2:CGFloat = 0.015
        
        let LAB1 = self.LAB
        let L_1 = LAB1[0], a_1 = LAB1[1], b_1 = LAB1[2]
        
        let LAB2 = color.LAB
        let L_2 = LAB2[0], a_2 = LAB2[1], b_2 = LAB2[2]
        
        let deltaL:CGFloat = L_1 - L_2
        let deltaA:CGFloat = a_1 - a_2
        let deltaB:CGFloat = b_1 - b_2
        
        let C_1:CGFloat = sqrt(pow(a_1, 2) + pow(b_1, 2))
        let C_2:CGFloat = sqrt(pow(a_2, 2) + pow(b_2, 2))
        let deltaC_ab:CGFloat = C_1 - C_2
        
        let deltaH_ab:CGFloat = sqrt(pow(deltaA, 2) + pow(deltaB, 2) - pow(deltaC_ab, 2))
        
        let s_L:CGFloat = 1
        let s_C:CGFloat = 1 + (k_1 * C_1)
        let s_H:CGFloat = 1 + (k_2 * C_1)
        
        // Calculate
        
        let P1:CGFloat = pow(deltaL/(k_L * s_L), 2)
        let P2:CGFloat = pow(deltaC_ab/(k_C * s_C), 2)
        let P3:CGFloat = pow(deltaH_ab/(k_H * s_H), 2)
        
        return sqrt((P1.isNaN ? 0:P1) + (P2.isNaN ? 0:P2) + (P3.isNaN ? 0:P3))
    }
    
    
    
    /**
        Detemine the distance between two colors based on the way humans perceive them.
        Uses the Sharma 2004 alteration of the CIEDE2000 algorithm.
     
        - parameter compare color: A UIColor to compare.
     
        - returns: A CGFloat representing the deltaE
    */
//    func CIEDE2000(compare color: UIColor) -> CGFloat {
//        // CIEDE2000, Sharma 2004 -> http://www.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf
//
//        func rad2deg(r: CGFloat) -> CGFloat {
//            return r * CGFloat(180/Double.pi)
//        }
//
//        func deg2rad(d: CGFloat) -> CGFloat {
//            return d * CGFloat(Double.pi/180)
//        }
//
//        let k_l = CGFloat(1), k_c = CGFloat(1), k_h = CGFloat(1)
//
//        let LAB1 = self.LAB
//        let L_1 = LAB1[0], a_1 = LAB1[1], b_1 = LAB1[2]
//
//        let LAB2 = color.LAB
//        let L_2 = LAB2[0], a_2 = LAB2[1], b_2 = LAB2[2]
//
//        let C_1ab = sqrt(pow(a_1, 2) + pow(b_1, 2))
//        let C_2ab = sqrt(pow(a_2, 2) + pow(b_2, 2))
//        let C_ab  = (C_1ab + C_2ab)/2
//
//        let G = 0.5 * (1 - sqrt(pow(C_ab, 7)/(pow(C_ab, 7) + pow(25, 7))))
//        let a_1_p = (1 + G) * a_1
//        let a_2_p = (1 + G) * a_2
//
//        let C_1_p = sqrt(pow(a_1_p, 2) + pow(b_1, 2))
//        let C_2_p = sqrt(pow(a_2_p, 2) + pow(b_2, 2))
//
//        // Read note 1 (page 23) for clarification on radians to hue degrees
//        let h_1_p = (b_1 == 0 && a_1_p == 0) ? 0 : (atan2(b_1, a_1_p) + CGFloat(2 * Double.pi)) * CGFloat(180/Double.pi)
//        let h_2_p = (b_2 == 0 && a_2_p == 0) ? 0 : (atan2(b_2, a_2_p) + CGFloat(2 * Double.pi)) * CGFloat(180/Double.pi)
//
//        let deltaL_p = L_2 - L_1
//        let deltaC_p = C_2_p - C_1_p
//
//        var h_p: CGFloat = 0
//        if (C_1_p * C_2_p) == 0 {
//            h_p = 0
//        } else if fabs(h_2_p - h_1_p) <= 180 {
//            h_p = h_2_p - h_1_p
//        } else if (h_2_p - h_1_p) > 180 {
//            h_p = h_2_p - h_1_p - 360
//        } else if (h_2_p - h_1_p) < -180 {
//            h_p = h_2_p - h_1_p + 360
//        }
//
//        let deltaH_p = 2 * sqrt(C_1_p * C_2_p) * sin(deg2rad(d: h_p/2))
//
//        let L_p = (L_1 + L_2)/2
//        let C_p = (C_1_p + C_2_p)/2
//
//        var h_p_bar: CGFloat = 0
//        if (h_1_p * h_2_p) == 0 {
//            h_p_bar = h_1_p + h_2_p
//        } else if fabs(h_1_p - h_2_p) <= 180 {
//            h_p_bar = (h_1_p + h_2_p)/2
//        } else if fabs(h_1_p - h_2_p) > 180 && (h_1_p + h_2_p) < 360 {
//            h_p_bar = (h_1_p + h_2_p + 360)/2
//        } else if fabs(h_1_p - h_2_p) > 180 && (h_1_p + h_2_p) >= 360 {
//            h_p_bar = (h_1_p + h_2_p - 360)/2
//        }
//
//        let T1 = cos(deg2rad(d: h_p_bar - 30))
//        let T2 = cos(deg2rad(d: 2 * h_p_bar))
//        let T3 = cos(deg2rad(d: (3 * h_p_bar) + 6))
//        let T4 = cos(deg2rad(d: (4 * h_p_bar) - 63))
//        let T = 1 - rad2deg(r: 0.17 * T1) + rad2deg(r: 0.24 * T2) - rad2deg(r: 0.32 * T3) + rad2deg(r: 0.20 * T4)
//
//        let deltaTheta = 30 * exp(-pow((h_p_bar - 275)/25, 2))
//        let R_c = 2 * sqrt(pow(C_p, 7)/(pow(C_p, 7) + pow(25, 7)))
//        let S_l =  1 + ((0.015 * pow(L_p - 50, 2))/sqrt(20 + pow(L_p - 50, 2)))
//        let S_c = 1 + (0.045 * C_p)
//        let S_h = 1 + (0.015 * C_p * T)
//        let R_t = -sin(deg2rad(d: 2 * deltaTheta)) * R_c
//
//        // Calculate total
//
//        let P1 = deltaL_p/(k_l * S_l)
//        let P2 = deltaC_p/(k_c * S_c)
//        let P3 = deltaH_p/(k_h * S_h)
//        let deltaE = sqrt(pow(P1, 2) + pow(P2, 2) + pow(P3, 2) + (R_t * P2 * P3))
//
//        return deltaE
//    }
    
    
    
    /**
        Determine the contrast ratio between two colors.
        A low ratio implies there is a smaller contrast between the two colors.
        A higher ratio implies there is a larger contrast between the two colors.
     
        - parameter with color: A UIColor to compare.
     
        - returns: A CGFloat representing the contrast ratio of the two colors.
    */
    func contrastRatio(with color: UIColor) -> CGFloat {
        // http://www.w3.org/WAI/GL/WCAG20-TECHS/G18.html
        
        let L1 = self.luminance
        let L2 = color.luminance
        
        if L1 < L2 {
            return (L2 + 0.05)/(L1 + 0.05)
        } else {
            return (L1 + 0.05)/(L2 + 0.05)
        }
    }
    
    
    
    /**
        Determine if two colors are contrasting or not based on the W3 standard.
     
        - parameter with color:      A UIColor to compare.
        - parameter strict:          A boolean, if true a stricter judgment of contrast ration will be used. Optional. Default: false
     
        - returns: a boolean, true of the two colors are contrasting, false otherwise.
     */
    func isContrasting(with color: UIColor, strict: Bool = false) -> Bool {
        // http://www.w3.org/TR/2008/REC-WCAG20-20081211/#visual-audio-contrast-contrast
        
        let ratio = self.contrastRatio(with: color)
        return strict ? (7 <= ratio) : (4.5 < ratio)
    }
    
    func isContrastingIgor(with color: UIColor, strict: Bool = false) -> Bool {
        // http://www.w3.org/TR/2008/REC-WCAG20-20081211/#visual-audio-contrast-contrast
        
        let ratio = self.contrastRatio(with: color)
        return strict ? (7 <= ratio) : (1.0 < ratio)
    }
    
    
    
    /**
        Get either black or white to contrast against a color.
     
        - returns: A UIColor, either black or white to contrast against this color.
    */
    var fullContrastColor: UIColor {
        let RGBA = self.RGBA
        let delta = (0.299*RGBA[0]) + (0.587*RGBA[1]) + (0.114*RGBA[2])
        
        return 0.5 < delta ? UIColor.black() : UIColor.white()
    }
    
    
    
    /**
        Get a clone of this color with a different alpha value.
     
        - parameter newAlpha: The opacity of the new color, value from [0, 1]
     
        - returns: A UIColor clone with the new alpha.
    */
    func with(alpha: CGFloat) -> UIColor {
        return self.withAlphaComponent(alpha)
    }
    
    
    
    /**
        Get a new color with a mask overlay blend mode on top of this color.
        This is similar to Photoshop's overlay blend mode.
     
        - parameter with color: A UIColor to apply as an overlay mask on top.
     
        - returns: A UIColor with the applied overlay.
    */
    func overlay(with color: UIColor) -> UIColor {
        let mainRGBA = self.RGBA
        let maskRGBA = color.RGBA
        
        func masker(a: CGFloat, b: CGFloat) -> CGFloat {
            if a < 0.5 {
                return 2 * a * b
            } else {
                return 1-(2*(1-a)*(1-b))
            }
        }
        
        return UIColor(
            r: masker(a: mainRGBA[0], b: maskRGBA[0]),
            g: masker(a: mainRGBA[1], b: maskRGBA[1]),
            b: masker(a: mainRGBA[2], b: maskRGBA[2]),
            a: masker(a: mainRGBA[3], b: maskRGBA[3])
        )
    }
    
    /**
        Get a new color if a black overlay was applied.
     
        - returns: A UIColor with a black overlay.
    */
    var overlayBlack: UIColor {
        return self.overlay(with: UIColor.black())
    }
    
    
    
    /**
        Get a new color if a white overlay was applied.
     
        - returns: A UIColor with a white overlay.
    */
    var overlayWhite: UIColor {
        return self.overlay(with: UIColor.white())
    }
    
    
    
    /**
        Get a new color with a mask multiply blend mode on top of this color.
        This is similar to Photoshop's multiply blend mode.
     
        - parameter with color: A UIColor to apply as a multiply mask on top.
     
        - returns: A UIColor with the applied multiply blend mode.
    */
    func multiply(with color: UIColor) -> UIColor {
        let mainRGBA = self.RGBA
        let maskRGBA = color.RGBA
        
        return UIColor(
            r: mainRGBA[0] * maskRGBA[0],
            g: mainRGBA[1] * maskRGBA[1],
            b: mainRGBA[2] * maskRGBA[2],
            a: mainRGBA[3] * maskRGBA[3]
        )
    }
    
    
    
    /**
        Get a new color with a mask screen blend mode on top of this color.
        This is similar to Photoshop's screen blend mode.
     
        - parameter with color: A UIColor to apply as a screen mask on top.
     
        - returns: A UIColor with the applied screen blend mode.
    */
    func screen(with color: UIColor) -> UIColor {
        let mainRGBA = self.RGBA
        let maskRGBA = color.RGBA
        
        func masker(a: CGFloat, b: CGFloat) -> CGFloat {
            return 1-((1-a)*(1-b))
        }
        
        return UIColor(
            r: masker(a: mainRGBA[0], b: maskRGBA[0]),
            g: masker(a: mainRGBA[1], b: maskRGBA[1]),
            b: masker(a: mainRGBA[2], b: maskRGBA[2]),
            a: masker(a: mainRGBA[3], b: maskRGBA[3])
        )
    }
    
    
    
    // Harmony helper method
    private func harmony(hueIncrement: CGFloat) -> UIColor {
        // http://www.tigercolor.com/color-lab/color-theory/color-harmonies.htm
        
        let HSBA = self.HSBA_8Bit
        let total = HSBA[0] + hueIncrement
        let newHue = abs(total.truncatingRemainder(dividingBy: 360.0))
        
        return UIColor(h: newHue, s: HSBA[1], b: HSBA[2], a: HSBA[3])
    }
    
    
    
    /**
        Get the complement of this color on the hue wheel.
     
        - returns: A complement UIColor.
    */
    var complement: UIColor {
        return self.harmony(hueIncrement: 180)
    }
    
}


public extension UIImage {
    var pixelWidth: Int {
        return cgImage?.width ?? 0
    }

    var pixelHeight: Int {
        return cgImage?.height ?? 0
    }

    func pixelColor(x: Int, y: Int) -> UIColor {
        assert(
            0 ..< pixelWidth ~= x && 0 ..< pixelHeight ~= y,
            "Pixel coordinates are out of bounds"
        )

        guard
            let cgImage = cgImage,
            let data = cgImage.dataProvider?.data,
            let dataPtr = CFDataGetBytePtr(data),
            let colorSpaceModel = cgImage.colorSpace?.model,
            let componentLayout = cgImage.bitmapInfo.componentLayout
        else {
            assertionFailure("Could not get a pixel of an image")
            return .clear
        }

        assert(
            colorSpaceModel == .rgb,
            "The only supported color space model is RGB"
        )
        assert(
            cgImage.bitsPerPixel == 32 || cgImage.bitsPerPixel == 24,
            "A pixel is expected to be either 4 or 3 bytes in size"
        )

        let bytesPerRow = cgImage.bytesPerRow
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let pixelOffset = y * bytesPerRow + x * bytesPerPixel

        if componentLayout.count == 4 {
            let components = (
                dataPtr[pixelOffset + 0],
                dataPtr[pixelOffset + 1],
                dataPtr[pixelOffset + 2],
                dataPtr[pixelOffset + 3]
            )

            var alpha: UInt8 = 0
            var red: UInt8 = 0
            var green: UInt8 = 0
            var blue: UInt8 = 0

            switch componentLayout {
            case .bgra:
                alpha = components.3
                red = components.2
                green = components.1
                blue = components.0
            case .abgr:
                alpha = components.0
                red = components.3
                green = components.2
                blue = components.1
            case .argb:
                alpha = components.0
                red = components.1
                green = components.2
                blue = components.3
            case .rgba:
                alpha = components.3
                red = components.0
                green = components.1
                blue = components.2
            default:
                return .clear
            }

            /// If chroma components are premultiplied by alpha and the alpha is `0`,
            /// keep the chroma components to their current values.
            if cgImage.bitmapInfo.chromaIsPremultipliedByAlpha, alpha != 0 {
                let invisibleUnitAlpha = 255 / CGFloat(alpha)
                red = UInt8((CGFloat(red) * invisibleUnitAlpha).rounded())
                green = UInt8((CGFloat(green) * invisibleUnitAlpha).rounded())
                blue = UInt8((CGFloat(blue) * invisibleUnitAlpha).rounded())
            }

            return .init(red: red, green: green, blue: blue, alpha: alpha)

        } else if componentLayout.count == 3 {
            let components = (
                dataPtr[pixelOffset + 0],
                dataPtr[pixelOffset + 1],
                dataPtr[pixelOffset + 2]
            )

            var red: UInt8 = 0
            var green: UInt8 = 0
            var blue: UInt8 = 0

            switch componentLayout {
            case .bgr:
                red = components.2
                green = components.1
                blue = components.0
            case .rgb:
                red = components.0
                green = components.1
                blue = components.2
            default:
                return .clear
            }

            return .init(red: red, green: green, blue: blue, alpha: UInt8(255))

        } else {
            assertionFailure("Unsupported number of pixel components")
            return .clear
        }
    }
}

public extension UIColor {
    convenience init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        self.init(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: CGFloat(alpha) / 255
        )
    }
}

public extension CGBitmapInfo {
    enum ComponentLayout {
        case bgra
        case abgr
        case argb
        case rgba
        case bgr
        case rgb

        var count: Int {
            switch self {
            case .bgr, .rgb: return 3
            default: return 4
            }
        }
    }

    var componentLayout: ComponentLayout? {
        guard let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue) else { return nil }
        let isLittleEndian = contains(.byteOrder32Little)

        if alphaInfo == .none {
            return isLittleEndian ? .bgr : .rgb
        }
        let alphaIsFirst = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst

        if isLittleEndian {
            return alphaIsFirst ? .bgra : .abgr
        } else {
            return alphaIsFirst ? .argb : .rgba
        }
    }

    var chromaIsPremultipliedByAlpha: Bool {
        let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue)
        return alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }
}

extension UIColor {
    var coreImageColor: CIColor {
        return CIColor(color: self)
    }
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let color = coreImageColor
        return (color.red, color.green, color.blue, color.alpha)
    }
    
}

extension CIColor {
    var toUIColor:UIColor {
        return UIColor.init(ciColor: self)
    }
}

extension UILabel {
func calculatedHeight() -> CGFloat {
    let constraintRect = CGSize(width: superview!.bounds.width, height: .greatestFiniteMagnitude)
    let boundingBox = self.text?.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font!], context: nil)
    return boundingBox?.height ?? 0.0
}
}

extension UILabel {
func calculatedWidth() -> CGFloat {
    let constraintRect = CGSize(width: superview!.bounds.width, height: self.bounds.height)
    let boundingBox = self.text?.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font!], context: nil)
    return boundingBox?.width ?? 0.0
}
}
