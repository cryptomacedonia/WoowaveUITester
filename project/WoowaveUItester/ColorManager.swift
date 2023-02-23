//
//  ColorManager.swift
//  SwiftColorGen
//
//  Created by Fernando Del Rio (fernandomdr@gmail.com) on 19/11/17.
//

import Foundation
import UIKit

public struct ColorManager {

    
    public static func getClosestColorName(color: UIColor) -> String {
        let cd = ColorData.init()
        cd.red = Double((color.RGBA[0]))
        cd.green = Double((color.RGBA[1]))
        cd.blue = Double((color.RGBA[2]))
        cd.alpha = Double((color.RGBA[3]))
        return getClosestColorName(colorData: cd)?.outputName ?? "NOT DETECTED"
    }
    
    
    private static func getClosestColorName(colorData: ColorData) -> (assetName: String, outputName: String)? {
        guard let webColors = getWebColors() else {
            return nil
        }
        let initial = (name: "", distance: Double.greatestFiniteMagnitude)
        let name = webColors
            .map { (name: $0.name,
                    distance: getColorDistance(from: colorData,
                                               to: $0.colorData))
            }
            .reduce(initial) { $0.distance < $1.distance ? $0 : $1 }
            .name
        let assetName = name.prefix(1).uppercased() + name.dropFirst()
        if colorData.alpha < 1.0 {
            return (assetName: assetName + " (alpha \(Int(round(255*colorData.alpha))))",
                outputName: name + "Alpha\(Int(round(255*colorData.alpha)))")
        } else {
            return (assetName: assetName, outputName: name)
        }
    }
    
    // Parse the WebColors json
    private static func getWebColors() -> [(name: String, colorData: ColorData)]? {
        guard let data = WebColor.values.data(using: .utf8) else {
            return nil
        }
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []),
            let colors = array as? [[String:Any]] else {
                return nil
        }
        return colors.map { color in
            let rgb = color["rgb"] as? Dictionary<String, Double> ?? [:]
            let name = color["name"] as? String ?? ""
            let r = rgb["r"] ?? 0
            let g = rgb["g"] ?? 0
            let b = rgb["b"] ?? 0
            let colorData = ColorData()
            colorData.red = r/255
            colorData.green = g/255
            colorData.blue = b/255
            return (name:name, colorData: colorData)
        }
    }
    
    // Calculate the distance between two Colors. This helps to find the closest match
    //   to a webcolor name
    private static func getColorDistance(from color1: ColorData, to color2: ColorData) -> Double {
        let rDistance = fabs(color1.red - color2.red)
        let gDistance = fabs(color1.green - color2.green)
        let bDistance = fabs(color1.blue - color2.blue)
        return rDistance + gDistance + bDistance
    }
    
    // Update the storyboard color from a raw value
  
}
