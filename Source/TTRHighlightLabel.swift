//
//  TTRHighlightLabel.swift
//  Pods-TTRHighlightLabel_Example
//
//  Created by TotersMacbookPro on 21/11/2021.
//

import UIKit

class TTRHighlightLabel: UILabel {

    fileprivate struct AssociatedObjectKeys {
        static var highlightedTapGestureRecognizer = "MediaViewerAssociatedObjectKey_mediaViewer"
    }
    fileprivate typealias Action = ((Int, String) -> ())?
    fileprivate var highlightedTapGestureRecognizerAction: Action? {
        set {
            if let newValue = newValue {
                // Computed properties get stored as associated objects
                objc_setAssociatedObject(self, &AssociatedObjectKeys.highlightedTapGestureRecognizer, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
        }
        get {
            let tapGestureRecognizerActionInstance = objc_getAssociatedObject(self, &AssociatedObjectKeys.highlightedTapGestureRecognizer) as? Action
            return tapGestureRecognizerActionInstance
        }
    }
    private var ranges: [AttributeObject] = [AttributeObject]()
    private var mainText: String = ""

    
    public func setAttributedHighlightedText(_ mainText: String, mainAttribute: NSMutableAttributedString, ranges: [AttributeObject]){
        self.ranges = ranges
        self.mainText = mainText
        for item in ranges {
            mainAttribute.addAttributes([NSAttributedString.Key.foregroundColor : item.color ?? UIColor.black,
                                                   NSAttributedString.Key.font: item.font ?? UIFont()], range: (mainText as NSString).range(of: item.text ?? ""))
        }
        self.attributedText = mainAttribute
    }
    
    public func addHighlightedTapGestureRecognizer(sender: UIGestureRecognizerDelegate? = nil,cancelsTouchesInView: Bool? = true, action: ((Int, String) -> ())?) {
        self.isUserInteractionEnabled = true
        self.highlightedTapGestureRecognizerAction = action
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture))
        tapGestureRecognizer.cancelsTouchesInView = cancelsTouchesInView ?? true
        if sender != nil {
            tapGestureRecognizer.delegate = sender
        }
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    
    @objc fileprivate func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        if let action = self.highlightedTapGestureRecognizerAction {
            var count = 0
            var range = NSRange()
            for item in self.ranges {
                range = (self.mainText as NSString).range(of: item.text ?? "")
                if gesture.didTapAttributedTextInLabel(label: self, inRange: range) {
                    action?(count, item.text ?? "")
                   return
                }
                count += 1
            }
        } else {
            print("no action")
        }
        
    }
     
}

public struct AttributeObject {
    public let text: String?
    public let color: UIColor?
    public let font: UIFont?
    
    init(text: String?, color: UIColor?, font: UIFont? = nil){
        self.text = text
        self.color = color
        self.font = font
    }
}

extension UITapGestureRecognizer {

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

        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)

        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }

}
