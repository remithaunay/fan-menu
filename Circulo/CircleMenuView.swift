import Foundation
import Macaw

class CircleMenuView: MacawView {
    
    var duration = 0.35 {
        didSet {
            updateNode()
        }
    }

    var distance = 95.0 {
        didSet {
            updateNode()
        }
    }
    
    var radius = 30.0 {
        didSet {
            updateNode()
        }
    }

    var centerButton: CircleMenuButton? {
        didSet {
            updateNode()
        }
    }
    
    var buttons: [CircleMenuButton] = [] {
        didSet {
            updateNode()
        }
    }
    
    var halfMode: Bool = false {
        didSet {
            updateNode()
        }
    }
    
     var onButtonPressed: ((_ button: CircleMenuButton) -> ())?
    
    func updateNode() {
        let viewSize = Size(
            w: Double(UIScreen.main.bounds.width),
            h: Double(UIScreen.main.bounds.height)
        )
        
        guard let centerButton = centerButton else {
            self.node = Group()
            return
        }
        
        let node = CircleMenu(centerButton: centerButton, menuView: self)
        node.place = Transform.move(dx: viewSize.w / 2, dy: viewSize.h/2)
        self.node = node
    }
}

struct CircleMenuButton {
    let id: String
    let image: String
    let color: Color
}

class CircleMenu: Group {
    
    let menuView: CircleMenuView
    
    let buttonGroup: Group
    let buttonsGroup: Group
    let menuIcon: Image
    let backgroundCircle: Node
    
    init(centerButton: CircleMenuButton, menuView: CircleMenuView) {
        self.menuView = menuView
        
        let mainCircle = Shape(
            form: Circle(r: menuView.radius),
            fill: centerButton.color
        )
        
        let uiImage = UIImage(named: centerButton.image)!
        menuIcon = Image(
            src: centerButton.image,
            place: Transform.move(
                dx: -Double(uiImage.size.width) / 2,
                dy:  -Double(uiImage.size.height) / 2
            )
        )
        
        buttonGroup = [mainCircle, menuIcon].group()
        buttonsGroup = menuView.buttons.map {
            CircleMenuButtonNode(
                button: $0,
                menuView: menuView
            )
        }.group()
        
        backgroundCircle = Shape(
            form: Circle(r: menuView.radius),
            fill: centerButton.color.with(a: 0.2)
        )
        
        super.init(contents: [backgroundCircle, buttonsGroup, buttonGroup])
        
        buttonGroup.onTouchPressed { _ in
            self.toggle()
        }
    }
    
    var animation: Animation?
    
    func toggle() {
        if let animationVal = self.animation {
            animationVal.reverse().play()
            self.animation = nil
            return
        }
        
        let scale = menuView.distance / menuView.radius
        let backgroundAnimation = self.backgroundCircle.placeVar.animation(
            to: Transform.scale(sx: scale, sy: scale),
            during: menuView.duration
        )
        
        let expandAnimation = self.buttonsGroup.contents.enumerated().map { (index, node) in
            return [
                node.opacityVar.animation(to: 1.0, during: menuView.duration),
                node.placeVar.animation(
                    to: self.expandPlace(index: index),
                    during: menuView.duration
                ).easing(Easing.easeOut)
            ].combine().delay(menuView.duration / 7 * Double(index))
        }.combine()
        
        // workaround
         let imageAnimation = self.buttonGroup.opacityVar.animation(
            to:  1.0,
            during: menuView.duration
         )
        
        self.animation = [backgroundAnimation, expandAnimation, imageAnimation].combine()
        self.animation?.play()
    }
    
    func expandPlace(index: Int) -> Transform {
        let size = Double(buttonsGroup.contents.count)
        let alpha = 2 * M_PI / (menuView.halfMode ? (size - 1) * 2 : size) * Double(index) + M_PI
        return Transform.move(
            dx: cos(alpha) * menuView.distance,
            dy: sin(alpha) * menuView.distance
        )
    }
}

class CircleMenuButtonNode: Group {

    init(button: CircleMenuButton, menuView: CircleMenuView) {
        let circle = Shape(
            form: Circle(r: menuView.radius),
            fill: button.color
        )

        let uiImage = UIImage(named: button.image)!
        let image = Image(
            src: button.image,
            place: Transform.move(
                dx: -Double(uiImage.size.width) / 2,
                dy:  -Double(uiImage.size.height) / 2
            )
        )
        super.init(contents: [circle, image], opacity: 0.0)
        
        self.onTouchPressed { _ in
            menuView.onButtonPressed?(button)
        }
    }
}