//
//  UITapGestureRecognizer+didTapInsideWrappedText.swift
//  AltRant
//
//  Created by Omer Shamai on 1/14/21.
//

import Foundation
import UIKit

extension UITapGestureRecognizer {
    func didTapInsideWrappedTextInLabel(label: UILabel, range: NSRange) -> Bool {
        //let range = NSRange(location: link.start!, length: link.end! - link.start!)
        
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: label.bounds.size)
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        
        var glyphRange: NSRange? = NSRange(location: 0, length: 1)
        
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange!)
        
        var characterRangeInSingleLine = [0]
        var lastPosition = layoutManager.boundingRect(forGlyphRange: NSRange(location: range.location, length: 1), in: textContainer)
        
        
        let rangeStart = label.attributedText!.string.index(label.attributedText!.string.startIndex, offsetBy: range.location != 0 ? range.location - 2 * (label.attributedText!.string.components(separatedBy: "\n").count - 1) : 0)
        let rangeEnd = label.attributedText!.string.index(label.attributedText!.string.startIndex, offsetBy: range.location != 0 ? range.location + range.length - 1 - 2 * (label.attributedText!.string.components(separatedBy: "\n").count - 1) : range.location + range.length - 1)
        
        for (idx, _) in label.attributedText!.string[rangeStart...rangeEnd].enumerated() {
            let boundingRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: range.location + idx, length: 1), in: textContainer)
            
            if boundingRect.minY > lastPosition.minY || characterRangeInSingleLine.isEmpty {
                characterRangeInSingleLine.append(1)
                
                lastPosition = boundingRect
            } else {
                characterRangeInSingleLine[characterRangeInSingleLine.endIndex - 1] += 1
                
                lastPosition = boundingRect
            }
        }
        
        var result = [CGRect]()
        
        var currentOffsetInRange = 0
        
        for (idx, singleLineRange) in characterRangeInSingleLine.enumerated() {
            if idx == 0 {
                result.append(layoutManager.boundingRect(forGlyphRange: NSRange(location: range.location, length: singleLineRange), in: textContainer))
                currentOffsetInRange += singleLineRange
            } else {
                result.append(layoutManager.boundingRect(forGlyphRange: NSRange(location: range.location + currentOffsetInRange, length: singleLineRange), in: textContainer))
                currentOffsetInRange += singleLineRange
            }
        }
        
        let location = self.location(in: label)
        
        for res in result {
            if res.contains(location) {
                return true
            }
        }
        
        return false
    }
    
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y);
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        return NSLocationInRange(indexOfCharacter, targetRange)
    }

}
