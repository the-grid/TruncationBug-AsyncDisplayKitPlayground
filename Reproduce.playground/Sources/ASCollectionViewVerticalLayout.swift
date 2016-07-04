import UIKit
public class ASCollectionViewVerticalLayout: UICollectionViewLayout, ASCollectionViewSize {
    
    let horizontalItemCount: Int
    let horizontalGap: CGFloat
    let verticalGap: CGFloat
    var horizontalGapTotalWidth: CGFloat = 0
    var targetCellIndexPath: NSIndexPath?
    public var itemSize = CGSizeZero
    var rowHeight: Int = 0
    
    required public init(horizontalItemCount hic: Int, horizontalGap hg: CGFloat, verticalGap vg: CGFloat, collectionBounds: CGRect) {
        horizontalItemCount = hic
        horizontalGap = hg
        verticalGap = vg
        itemSize = ASCollectionViewVerticalLayout.itemSizeForBounds(collectionBounds, horizontalGap: horizontalGap, horizontalItemCount: hic)
        super.init()
    }
    
    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func prepareLayout() {
        
        guard let collectionView = self.collectionView else { return }
        
        itemSize = ASCollectionViewVerticalLayout.itemSizeForBounds(collectionView.bounds, horizontalGap: horizontalGap, horizontalItemCount: horizontalItemCount)
        
        rowHeight = Int(ceil(itemSize.height + verticalGap))
        horizontalGapTotalWidth = horizontalGap * CGFloat(horizontalItemCount - 1)
        
        super.prepareLayout()
    }
    
    private static func itemSizeForBounds(
        bounds: CGRect,
        horizontalGap: CGFloat,
        horizontalItemCount: Int
        ) -> CGSize {
        let horizontalInsetTotal = horizontalGap * 2
        let availWidth = bounds.width - CGFloat(horizontalGap * CGFloat(horizontalItemCount - 1)) - horizontalInsetTotal
        let maxItemWidth = max(availWidth / CGFloat(horizontalItemCount), 0)
        return CGSize(width: maxItemWidth, height: maxItemWidth)
    }
    
    private func rangeInView(rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        
        let startRow = Int(floor(rect.origin.y / CGFloat(rowHeight)))
        let rowCount = Int(ceil(rect.size.height / CGFloat(rowHeight)))+1
        
        var cachePath = LayoutAttributes(
            startRow: startRow,
            rowCount: rowCount,
            rowHeight: rowHeight,
            hItemCount: horizontalItemCount,
            atts: []
        )
        
        if let cacheIndex = LayoutAttributes.cache.indexOf(cachePath) {
            return LayoutAttributes.cache[cacheIndex].atts
        }
        
        let loadedCount = loadedItemCount()
        
        let location = max(startRow * horizontalItemCount, 0)
        let length = max(rowCount * horizontalItemCount, 0)
        
        let range = NSRange(location: location, length: length)
        let set = NSIndexSet(indexesInRange: range)
        
        let paths = set.map { NSIndexPath(forItem: $0, inSection: 0) }
        
        let atts = paths.flatMap { indexPath in
            return indexPath.item < loadedItemCount() ? layoutAttributesForItemAtIndexPath(indexPath) : .None
        }
        
        // dont cache if
        if location + length < loadedCount {
            cachePath.atts = atts
            LayoutAttributes.cache.insert(cachePath)
        }
        
        return atts
    }
    
    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let atts = rangeInView(rect)
        return atts
    }
    
    override public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let att = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        att.frame = frameForIndexPath(indexPath)
        return att
    }
    
    internal func frameForIndexPath(indexPath: NSIndexPath) -> CGRect {
        
        let col = indexPath.item % horizontalItemCount
        let row = indexPath.item / horizontalItemCount
        
        var x = CGFloat(col) * itemSize.width
        let y = Int(row) * rowHeight
        
        // mind the gaps
        x += CGFloat(col) * horizontalGap
        
        // mind the final horizonal centering
        x += horizontalGap
        
        return CGRect(x: x, y: CGFloat(y), width: itemSize.width, height: itemSize.height)
    }
    
    private func frameForIndexPath(index: Int) -> CGRect {
        let indexPath = NSIndexPath(forItem: index, inSection: 0)
        return frameForIndexPath(indexPath)
    }
    
    override public func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return self.collectionView?.bounds.size != newBounds.size
    }
    
    override public func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
        
        guard let collectionView = self.collectionView else { return proposedContentOffset }
        guard let indexPath = targetCellIndexPath else { return proposedContentOffset }
        guard let cellAttribute = layoutAttributesForItemAtIndexPath(indexPath) else { return proposedContentOffset }
        
        // must use default scroll destination if content doesnt need to scroll
        let totalContentSize = collectionViewContentSize()
        let visibleFrameSize = collectionView.bounds
        
        var optimal = cellAttribute.center.y - (visibleFrameSize.height / 2)
        
        if optimal < 0 {
            optimal = 0
        }
        if optimal > totalContentSize.height - visibleFrameSize.height {
            optimal = totalContentSize.height - visibleFrameSize.height
        }
        
        let pt = CGPoint(x: proposedContentOffset.x, y: optimal)
        
        return pt
    }
    
    override public func collectionViewContentSize() -> CGSize {
        guard let bounds = self.collectionView?.bounds else { return CGSizeZero }
        let lic = loadedItemCount() - 1
        let index = lic > 0 ? lic: 0
        let frm = frameForIndexPath(index)
        return CGSize(width: bounds.width, height: frm.maxY + verticalGap)
    }
    
    func zoomedItemCount() -> Int {
        guard let collectionView = self.collectionView else { return 0 }
        let viewHeight = collectionView.bounds.height
        let approxCount = ceil((viewHeight / (itemSize.height + CGFloat(verticalGap))) * CGFloat(horizontalItemCount))
        return Int(approxCount)
    }
    
    func loadedItemCount() -> Int {
        guard collectionView?.numberOfSections() > 0 else { return 0 }
        guard let count = collectionView?.numberOfItemsInSection(0) else { return 0 }
        return count
    }
}


struct LayoutAttributes {
    let startRow: Int
    let rowCount: Int
    let rowHeight: Int
    let hItemCount: Int
    var atts: [UICollectionViewLayoutAttributes]
    static var cache = Set<LayoutAttributes>()
}

// Mark: - Equatable
extension LayoutAttributes: Equatable {}

func == (lhs: LayoutAttributes, rhs: LayoutAttributes) -> Bool {
    return lhs.startRow == rhs.startRow
        && lhs.rowCount == rhs.rowCount
        && lhs.rowHeight == rhs.rowHeight
        && lhs.hItemCount == rhs.hItemCount
}


// Mark: - Hashable
extension LayoutAttributes: Hashable {}

extension LayoutAttributes {
    var hashValue: Int {
        return "\(startRow)\(rowCount)\(rowHeight)\(hItemCount)".hashValue
    }
}