import SwiftUI

struct WheelSlice:Shape {
    var start:Double; var end:Double
    func path(in rect:CGRect)->Path {
        var p=Path();let center=CGPoint(x:rect.midX,y:rect.midY)
        p.move(to:center);p.addArc(center:center,radius:min(rect.width,rect.height)/2,startAngle:.degrees(start-90),endAngle:.degrees(end-90),clockwise:false);p.closeSubpath();return p
    }
}
struct FoodWheel:View {
    var labels:[String];var rotation:Double
    let colors:[Color]=[Color(red:1,green:0.72,blue:0.56),Color(red:1,green:0.86,blue:0.58),Color(red:0.69,green:0.84,blue:0.71),Color(red:0.98,green:0.79,blue:0.72),Color(red:0.85,green:0.82,blue:0.95),Color(red:0.65,green:0.83,blue:0.83)]
    var body:some View {
        GeometryReader {geo in
            let diameter=min(geo.size.width,geo.size.height)
            ZStack {
                ForEach(Array(labels.enumerated()),id:\.offset) {index,label in
                    let angle=Double(index)*360/Double(max(labels.count,1)),sweep=360/Double(max(labels.count,1))
                    WheelSlice(start:angle,end:angle+sweep).fill(colors[index%colors.count]).overlay(WheelSlice(start:angle,end:angle+sweep).stroke(.white.opacity(0.7),lineWidth:2))
                    Text(label).font(.system(size:labels.count>12 ? 9:labels.count>8 ? 11:13,weight:.bold,design:.rounded)).foregroundStyle(.black.opacity(0.75)).lineLimit(labels.count>12 ? 1:2).minimumScaleFactor(0.65).multilineTextAlignment(.center).frame(width:diameter*0.29).rotationEffect(.degrees(angle+sweep/2-90)).offset(x:sin((angle+sweep/2)*Double.pi/180)*diameter*0.33,y:-cos((angle+sweep/2)*Double.pi/180)*diameter*0.33)
                }
                Circle().fill(.white).frame(width:diameter*0.22).shadow(color:.black.opacity(0.08),radius:5)
                Text("✦").font(.system(size:diameter*0.11)).foregroundStyle(Color(red:0.91,green:0.30,blue:0.18))
            }.rotationEffect(.degrees(rotation)).overlay(alignment:.top) {Image(systemName:"arrowtriangle.down.fill").font(.system(size:diameter*0.065)).foregroundStyle(Color(red:0.45,green:0.21,blue:0.15)).offset(y:-8)}
        }.aspectRatio(1,contentMode:.fit).accessibilityLabel("Food decision wheel").accessibilityValue("\(labels.count) choices")
    }
}
enum WheelMath {
    static func targetRotation(current:Double,index:Int,count:Int,turns:Int=5)->Double {
        guard count>0 else {return current}
        let target=360-(Double(index)+0.5)*360/Double(count)
        let normalized=current.truncatingRemainder(dividingBy:360)
        return current+Double(turns)*360+(target-normalized+360).truncatingRemainder(dividingBy:360)
    }
    static func winner(rotation:Double,count:Int)->Int? {
        guard count>0 else {return nil}
        let normalized=(((-rotation).truncatingRemainder(dividingBy:360))+360).truncatingRemainder(dividingBy:360)
        return min(count-1,Int(normalized/(360/Double(count))))
    }
}
