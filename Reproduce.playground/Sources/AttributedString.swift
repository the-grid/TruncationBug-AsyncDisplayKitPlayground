import Foundation
import UIKit

public func getStyledContent() -> NSMutableAttributedString {
    
    let paragraph = NSMutableParagraphStyle()
    
    paragraph.alignment = NSTextAlignment.Left
    //        paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
    paragraph.paragraphSpacing = 16 * 0.6
    
    let titleFont = UIFont.systemFontOfSize(24, weight: UIFontWeightRegular)
    let titleAttrs = [NSFontAttributeName: titleFont, NSForegroundColorAttributeName: UIColor.blackColor(), NSParagraphStyleAttributeName: paragraph]
    let bodyFont = UIFont.systemFontOfSize(16, weight: UIFontWeightThin)
    let bodyAttrs = [NSFontAttributeName: bodyFont, NSForegroundColorAttributeName: UIColor.darkTextColor(), NSParagraphStyleAttributeName: paragraph]
    let attributionNameAttrs = [NSFontAttributeName: bodyFont, NSForegroundColorAttributeName: UIColor.purpleColor(), NSParagraphStyleAttributeName: paragraph]
    let attributionAuthorAttrs = [NSFontAttributeName: bodyFont, NSForegroundColorAttributeName: UIColor.purpleColor(), NSParagraphStyleAttributeName: paragraph]
    let attributionMetaAttrs = [NSFontAttributeName: bodyFont, NSForegroundColorAttributeName: UIColor.lightTextColor(), NSParagraphStyleAttributeName: paragraph]

    let attrStringAuthorName = NSMutableAttributedString(string: "Nick Velloff", attributes : attributionNameAttrs)
    let attrStringFrom = NSMutableAttributedString(string: " from ", attributes : attributionMetaAttrs)
    let attrStringPublisherName = NSMutableAttributedString(string: "Apple\n", attributes : attributionAuthorAttrs)
    let attrStringTitle = NSMutableAttributedString(string: "Use Functional Swift Wisely\n", attributes : titleAttrs)
    let attrStringBody = NSAttributedString(string: "There is a little known secret about Swift functional programming. It get's absurd by overuse of custom operators and impossible to follow event streams. Then curry the cryptic operators and make a truly painful thing.", attributes : bodyAttrs)
    let content = NSMutableAttributedString()
    
    content.appendAttributedString(attrStringAuthorName)
    content.appendAttributedString(attrStringFrom)
    content.appendAttributedString(attrStringPublisherName)
    content.appendAttributedString(attrStringTitle)
    content.appendAttributedString(attrStringBody)
    
    return content
}