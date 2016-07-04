import UIKit

/* Used to abstract away type checking between an ASCollectionViewVerticalTransitionLayout
 and an ASCollectionViewVerticalLayout for size related updates
 */

public protocol ASCollectionViewSize {
    var itemSize: CGSize { get }
}