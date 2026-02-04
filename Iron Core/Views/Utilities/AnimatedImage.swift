import SwiftUI
import UIKit

struct AnimatedImage: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        Task {
            await loadAnimatedImage(into: imageView)
        }
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
    }
    
    private func loadAnimatedImage(into imageView: UIImageView) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            await MainActor.run {
                if let source = CGImageSourceCreateWithData(data as CFData, nil) {
                    let count = CGImageSourceGetCount(source)
                    var images: [UIImage] = []
                    var totalDuration: TimeInterval = 0
                    
                    for i in 0..<count {
                        if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                            images.append(UIImage(cgImage: cgImage))
                            
                            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                               let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                               let delay = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                                totalDuration += delay
                            } else {
                                totalDuration += 0.1
                            }
                        }
                    }
                    
                    if !images.isEmpty {
                        imageView.animationImages = images
                        imageView.animationDuration = totalDuration
                        imageView.animationRepeatCount = 0
                        imageView.startAnimating()
                    }
                }
            }
        } catch {
            print("❌ Failed to load animated image: \(error)")
        }
    }
}
