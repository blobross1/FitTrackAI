import SwiftUI
import UIKit

enum ScreenLayout {
    static let horizontalPadding: CGFloat = 20
    static let bottomScrollPadding: CGFloat = 24
    static let photoMaxHeightFraction: CGFloat = 0.36

    static var screenSize: CGSize {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.size
            ?? CGSize(width: 390, height: 844)
    }

    static var photoCardSize: CGSize {
        let width = screenSize.width - horizontalPadding * 2
        let height = photoHeight(forWidth: width)
        return CGSize(width: width, height: height)
    }

    static func photoHeight(forWidth width: CGFloat) -> CGFloat {
        let fromAspect = width * 4 / 3
        let maxH = screenSize.height * photoMaxHeightFraction
        return min(fromAspect, maxH)
    }
}

struct TabScreenScroll<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, ScreenLayout.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, ScreenLayout.bottomScrollPadding)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.clear)
    }
}

struct PhotoPreviewCard<Placeholder: View, Overlay: View>: View {
    let uiImage: UIImage?
    @ViewBuilder var placeholder: () -> Placeholder
    @ViewBuilder var overlay: () -> Overlay

    private var size: CGSize { ScreenLayout.photoCardSize }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.card)

            Group {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                } else {
                    placeholder()
                        .frame(width: size.width, height: size.height)
                }
            }

            overlay()
                .frame(width: size.width, height: size.height)
                .clipped()
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.glassStroke, lineWidth: 1)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
