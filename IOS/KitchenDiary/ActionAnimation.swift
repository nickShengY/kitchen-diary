import SwiftUI
import ImageIO

/// Plays the React app's original action frames with UIKit, without a web view.
struct ActionAnimation:UIViewRepresentable {
    var action:String
    var reducedMotion:Bool
    func makeUIView(context:Context)->UIImageView {let view=UIImageView();view.contentMode = .scaleAspectFit;view.setContentCompressionResistancePriority(.defaultLow,for:.horizontal);view.setContentCompressionResistancePriority(.defaultLow,for:.vertical);return view}
    func updateUIView(_ view:UIImageView,context:Context) {
        guard context.coordinator.action != action || context.coordinator.reduced != reducedMotion else {return}
        context.coordinator.action=action;context.coordinator.reduced=reducedMotion
        view.stopAnimating();view.animationImages=nil
        guard let url=Bundle.main.url(forResource:"action_"+action,withExtension:"png",subdirectory:"Motion"),let source=CGImageSourceCreateWithURL(url as CFURL,nil) else {view.image=UIImage(named:"mascot");return}
        let count=CGImageSourceGetCount(source)
        var frames:[UIImage]=[];var duration=0.0
        for i in 0..<(reducedMotion ? min(1,count):count) {
            if let image=CGImageSourceCreateImageAtIndex(source,i,nil) {frames.append(UIImage(cgImage:image))}
            let properties=CGImageSourceCopyPropertiesAtIndex(source,i,nil) as? [CFString:Any]
            let animation=properties?[kCGImagePropertyPNGDictionary] as? [CFString:Any]
            duration += animation?[kCGImagePropertyAPNGUnclampedDelayTime] as? Double ?? animation?[kCGImagePropertyAPNGDelayTime] as? Double ?? 0.08
        }
        view.image=frames.first
        if !reducedMotion,frames.count>1 {view.animationImages=frames;view.animationDuration=duration;view.animationRepeatCount=0;view.startAnimating()}
    }
    func makeCoordinator()->Coordinator {Coordinator()}
    final class Coordinator {var action="";var reduced=false}
}
