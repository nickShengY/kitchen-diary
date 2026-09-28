import SwiftUI
import UIKit

enum KitchenTheme {
    static let cream = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red:0.078,green:0.059,blue:0.051,alpha:1) : UIColor(red:1,green:0.973,blue:0.949,alpha:1) })
    static let card = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red:0.137,green:0.106,blue:0.094,alpha:1) : .white })
    static let ink = Color.primary
    static let coral = Color(red:0.91,green:0.30,blue:0.18)
    static let peach = Color(red:1,green:0.88,blue:0.81)
    static let sage = Color(red:0.10,green:0.46,blue:0.40)
    static let butter = Color(red:1,green:0.80,blue:0.47)
    static func display(_ size: CGFloat) -> Font { .custom("Georgia-Bold",size:size,relativeTo:size >= 30 ? .largeTitle:.title2) }
}
struct KitchenButton: ButtonStyle {
    var secondary = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.body,design:.rounded,weight:.bold)).frame(maxWidth:.infinity).padding(.vertical,16).padding(.horizontal,18)
            .background(secondary ? KitchenTheme.card : KitchenTheme.coral,in:RoundedRectangle(cornerRadius:20))
            .foregroundStyle(secondary ? KitchenTheme.coral : .white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response:0.28,dampingFraction:0.65),value:configuration.isPressed)
    }
}
struct PaperCard<Content: View>: View {
    var color: Color = KitchenTheme.card
    @ViewBuilder var content: Content
    var body: some View { VStack(alignment:.leading,spacing:12) { content }.padding(20).frame(maxWidth:.infinity,alignment:.leading).background(color,in:RoundedRectangle(cornerRadius:26)).overlay(RoundedRectangle(cornerRadius:26).stroke(.primary.opacity(0.05))).shadow(color:.black.opacity(0.035),radius:15,y:6) }
}
struct Eyebrow: View { var title:String; var body:some View { Text(title.uppercased()).font(.system(.caption2,design:.rounded,weight:.heavy)).tracking(2).foregroundStyle(KitchenTheme.sage).dynamicTypeSize(...DynamicTypeSize.xxxLarge) } }
struct SectionTitle: View {
    var title: String; var subtitle: String = ""
    var body: some View { VStack(alignment:.leading,spacing:7) { Text(title).font(KitchenTheme.display(32)); if !subtitle.isEmpty { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) } }.frame(maxWidth:.infinity,alignment:.leading) }
}
struct FoodArt: View {
    var id: String; var emoji: String; var size: CGFloat = 70
    var body: some View {
        Group { if UIImage(named:"ingredient_"+id) != nil { Image("ingredient_"+id).resizable().scaledToFit() } else { Text(emoji).font(.system(size:size*0.7)) } }.frame(width:size,height:size).accessibilityHidden(true)
    }
}
struct RecipeArtwork: View {
    var recipe: Recipe; var height: CGFloat = 170
    var body: some View {
        ZStack {
            LinearGradient(colors:[KitchenTheme.peach,KitchenTheme.butter.opacity(0.5)],startPoint:.topLeading,endPoint:.bottomTrailing)
            if let address = recipe.imageUrl, let url = URL(string:address), url.scheme == "https" {
                AsyncImage(url:url) { image in image.resizable().scaledToFill() } placeholder: { fallback }
            } else { fallback }
        }.frame(height:height).clipped().clipShape(RoundedRectangle(cornerRadius:22)).accessibilityHidden(true)
    }
    var fallback: some View {
        ZStack {
            Circle().fill(.white.opacity(0.7)).frame(width:height*0.8,height:height*0.8).shadow(color:.brown.opacity(0.08),radius:10,y:5)
            Circle().stroke(.white.opacity(0.8),lineWidth:2).frame(width:height*0.68,height:height*0.68)
            if let ingredient = recipe.steps.first?.ingredients.first, let item = Catalog.shared.ingredient(ingredient.id) { FoodArt(id:item.id,emoji:item.emoji,size:height*0.63) }
            else { Text(recipe.authorAvatar).font(.system(size:height*0.43)) }
            Text("✦").font(.title).foregroundStyle(KitchenTheme.coral.opacity(0.6)).offset(x:height*0.65,y:-height*0.25)
        }
    }
}
struct Chip: View {
    var text:String; var selected = false; var action: ()->Void
    var body:some View { Button(action:action) { Text(text).font(.system(.subheadline,design:.rounded,weight:.semibold)).padding(.horizontal,17).padding(.vertical,12).background(selected ? KitchenTheme.sage : KitchenTheme.card,in:Capsule()).foregroundStyle(selected ? .white : .primary) }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : []) }
}
extension View { func kitchenBackground() -> some View { background(KitchenTheme.cream.ignoresSafeArea()).scrollDismissesKeyboard(.interactively) } }
