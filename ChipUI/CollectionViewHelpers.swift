//
//  CollectionViewHelpers.swift
//  ChipUI
//
//  Created by Nikhil Dhavale on 26/05/26.
//

import UIKit

final class IntrinsicCollectionView: UICollectionView {

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: collectionViewLayout.collectionViewContentSize.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
}

final class LeadingAlignedFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }

        let copiedAttributes = attributes.map { $0.copy() as! UICollectionViewLayoutAttributes }
        var leadingX = sectionInset.left
        var currentRowMaxY: CGFloat = -1

        for attribute in copiedAttributes where attribute.representedElementCategory == .cell {
            if attribute.frame.minY >= currentRowMaxY {
                leadingX = sectionInset.left
            }

            attribute.frame.origin.x = leadingX
            leadingX = attribute.frame.maxX + minimumInteritemSpacing
            currentRowMaxY = max(currentRowMaxY, attribute.frame.maxY)
        }

        return copiedAttributes
    }
}

extension Array where Element: Hashable {

    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
