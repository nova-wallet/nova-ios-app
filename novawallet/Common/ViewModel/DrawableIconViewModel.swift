import Foundation
import SubstrateSdk
import UIKit

final class DrawableIconViewModel {
    let icon: DrawableIcon
    let fillColor: UIColor

    private var image: UIImage?

    init(icon: DrawableIcon, fillColor: UIColor = .clear) {
        self.icon = icon
        self.fillColor = fillColor
    }
}

extension DrawableIconViewModel: ImageViewModelProtocol {
    func loadImage(on imageView: UIImageView, targetSize: CGSize, cornerRadius _: CGFloat, animated _: Bool) {
        if let image = image {
            imageView.image = image
            return
        }

        image = icon.imageWithFillColor(
            fillColor,
            size: targetSize,
            contentScale: UIScreen.main.scale
        )

        imageView.image = image
    }

    func cancel(on _: UIImageView) {}
}
