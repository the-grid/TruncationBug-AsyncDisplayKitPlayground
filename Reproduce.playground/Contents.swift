//: ## Please build the scheme 'AsyncDisplayKitPlayground' first
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

import AsyncDisplayKit

//: ## Press the Zoom button then scroll until you see the improperly truncated textfield

class ASCollectionViewVerticalTransitionLayout: UICollectionViewTransitionLayout, ASCollectionViewSize {
    
    let currentSize:CGSize
    let newSize:CGSize
    
    override init(currentLayout: UICollectionViewLayout, nextLayout newLayout: UICollectionViewLayout) {
        currentSize = (currentLayout as! ASCollectionViewSize).itemSize
        newSize = (newLayout as! ASCollectionViewSize).itemSize
        super.init(currentLayout: currentLayout, nextLayout: newLayout)
    }
    
    var itemSize: CGSize {
        let newWidth = ((newSize.width - currentSize.width) * transitionProgress) + currentSize.width
        let newHeight = ((newSize.height - currentSize.height) * transitionProgress) + currentSize.height
        return CGSize(width: newWidth, height: newHeight)
    }
    
    override func invalidateLayout() {
        guard let nodes = (self.collectionView as? ASCollectionView)?.visibleNodes() else {
            super.invalidateLayout()
            return
        }
        let sizeRange = ASSizeRange(min: itemSize, max: itemSize)
        nodes.forEach { node in
            let frameSize = node.measureWithSizeRange(sizeRange).size
            node.frame = CGRect(origin: node.frame.origin, size: frameSize)
        }
        super.invalidateLayout()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CardInfoOverlayNode: ASDisplayNode {
    let contentTextNode = ASTextNode()
    override init() {
        contentTextNode.attributedString = getStyledContent()
        super.init()
        backgroundColor = UIColor.grayColor()
        usesImplicitHierarchyManagement = true
    }
    override func layoutSpecThatFits(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        // not sure why we need this, but an empty node to go full width
        let stretchWidthNode = ASDisplayNode()
        stretchWidthNode.preferredFrameSize = CGSize(width: constrainedSize.max.width, height: 0)
        
        let insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let insetSpec = ASInsetLayoutSpec(insets: insets, child: contentTextNode)
        
        let minHeight = ASRelativeDimensionMakeWithPercent(0)
        let maxHeight = ASRelativeDimensionMakeWithPercent(0.8)
        let width = ASRelativeDimensionMakeWithPercent(1)
        
        let minSize = ASRelativeSizeMake(width, minHeight)
        let maxSize = ASRelativeSizeMake(width, maxHeight)
        insetSpec.sizeRange = ASRelativeSizeRange(min: minSize, max: maxSize)
        
        let staticSpec = ASStaticLayoutSpec(children: [stretchWidthNode, insetSpec])
        
        return staticSpec
    }
}

class PostCellNode: ASCellNode {
    let backgroundNode = ASDisplayNode()
    let cardInfoOverlayNode: CardInfoOverlayNode
    override init() {
        cardInfoOverlayNode = CardInfoOverlayNode()
        super.init()
        backgroundColor = UIColor.lightGrayColor()
        usesImplicitHierarchyManagement = true
    }
    override func layoutSpecThatFits(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        backgroundNode.preferredFrameSize = constrainedSize.max
        
        let insets = UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8)
        let insetSpec = ASInsetLayoutSpec(insets: insets, child: cardInfoOverlayNode)
        
        let relativeSpec = ASRelativeLayoutSpec()
        relativeSpec.verticalPosition = .End
        relativeSpec.setChild(insetSpec)
        
        let overlayLayoutSpec = ASOverlayLayoutSpec(child: backgroundNode, overlay: relativeSpec)
        
        return overlayLayoutSpec
    }
}

class Root: ASDisplayNode, ASCollectionDelegate, ASCollectionDataSource {
    let collection: ASCollectionNode
    let zoomButton: ASButtonNode
    
    override init() {
        let bounds = CGRect(origin: CGPointZero, size: CGSize(width: 375, height: 667))
        
        let layout = ASCollectionViewVerticalLayout(horizontalItemCount: 2, horizontalGap: 8, verticalGap: 8, collectionBounds: bounds)
        
        collection = ASCollectionNode(collectionViewLayout: layout)
        collection.backgroundColor = UIColor.blackColor()
        
        zoomButton = ASButtonNode()
        zoomButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 32, bottom: 8, right: 32)
        zoomButton.setTitle("ZOOM", withFont: .None, withColor: UIColor.whiteColor(), forState: .Normal)
        zoomButton.backgroundColor = UIColor.purpleColor()
        
        super.init()
        
        zoomButton.addTarget(self, action: #selector(handleZoomTouch), forControlEvents: .TouchUpInside)
        
        collection.delegate = self
        collection.dataSource = self

        usesImplicitHierarchyManagement = true
    }
    
    override func layoutSpecThatFits(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let insetSpec = ASInsetLayoutSpec(insets: insets, child: zoomButton)
        
        collection.preferredFrameSize = constrainedSize.max
        
        let vertSpec = ASStackLayoutSpec.verticalStackLayoutSpec()
        vertSpec.horizontalAlignment = .HorizontalAlignmentMiddle
        vertSpec.setChildren([insetSpec, collection])

        return vertSpec
    }
    
    func handleZoomTouch() {
        zoomButton.userInteractionEnabled = false
        zoomButton.alpha = 0.5
        let layout = ASCollectionViewVerticalLayout(horizontalItemCount: 1, horizontalGap: 8, verticalGap: 8, collectionBounds: collection.bounds)
        
        collection.view.startInteractiveTransitionToCollectionViewLayout(layout) {
            completion in
            self.collection.view.relayoutItems()
        }
        collection.view.finishInteractiveTransition()
    }

// MARK: --- Our custom transition layout to make cell resizing work
    func collectionView(collectionView: UICollectionView, transitionLayoutForOldLayout fromLayout: UICollectionViewLayout, newLayout toLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout {
        return ASCollectionViewVerticalTransitionLayout(currentLayout: fromLayout, nextLayout: toLayout)
    }

    
    // MARK: --------- BEGIN ASCollectionDataSource delegate methods ---------
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 50
    }

    func collectionView(collectionView: ASCollectionView, constrainedSizeForNodeAtIndexPath indexPath: NSIndexPath) -> ASSizeRange {
        let layout = collectionView.collectionViewLayout as! ASCollectionViewSize
        let size = layout.itemSize
        return ASSizeRange(min: size, max: size)
    }
    
    func collectionView(collectionView: ASCollectionView, nodeBlockForItemAtIndexPath indexPath: NSIndexPath) -> ASCellNodeBlock {
        return {
            return PostCellNode()
        }
    }
    // --------- END ASCollectionDataSource delegate methods ---------
    
}

let vc = ASViewController(node: Root())

XCPlaygroundPage.currentPage.liveView = vc
