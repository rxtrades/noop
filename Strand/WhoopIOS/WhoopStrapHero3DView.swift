#if os(iOS)
import SwiftUI
import SceneKit
import StrandDesign

/// Procedural SceneKit strap + sensor pod for Device Settings (Mobbin 119 / PowerPack states).
/// Slow turntable rotation, LED charging pulse, optional PowerPack sibling node.
/// Own geometry — not WHOOP marketing assets.
struct WhoopStrapHero3DView: View {
    var charging: Bool
    var packAttached: Bool
    var batteryFraction: Double // 0…1 for LED tint
    var reduceMotion: Bool = false

    var body: some View {
        WhoopStrapSCNView(
            charging: charging,
            packAttached: packAttached,
            batteryFraction: batteryFraction,
            reduceMotion: reduceMotion
        )
        .frame(width: 168, height: 168)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(WhoopIOSDesign.surfaceList)
        )
        .accessibilityLabel(charging ? "Strap charging" : (packAttached ? "Strap with PowerPack" : "Strap"))
    }
}

private struct WhoopStrapSCNView: UIViewRepresentable {
    var charging: Bool
    var packAttached: Bool
    var batteryFraction: Double
    var reduceMotion: Bool

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.autoenablesDefaultLighting = false
        view.allowsCameraControl = false
        view.isPlaying = true
        view.scene = WhoopStrapSceneBuilder.makeScene()
        context.coordinator.attach(to: view)
        context.coordinator.apply(
            charging: charging,
            packAttached: packAttached,
            batteryFraction: batteryFraction,
            reduceMotion: reduceMotion
        )
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.apply(
            charging: charging,
            packAttached: packAttached,
            batteryFraction: batteryFraction,
            reduceMotion: reduceMotion
        )
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private weak var view: SCNView?
        private var rotating = false

        func attach(to view: SCNView) {
            self.view = view
        }

        func apply(charging: Bool, packAttached: Bool, batteryFraction: Double, reduceMotion: Bool) {
            guard let scene = view?.scene else { return }
            guard let root = scene.rootNode.childNode(withName: "strapRoot", recursively: false) else { return }

            if let pack = root.childNode(withName: "powerPack", recursively: true) {
                pack.isHidden = !packAttached
            }
            if let led = root.childNode(withName: "led", recursively: true) {
                let mat = led.geometry?.firstMaterial
                if charging {
                    let pulse = SCNAction.sequence([
                        .customAction(duration: 0.7) { node, t in
                            let k = Float(sin(Double(t) * .pi))
                            mat?.emission.contents = UIColor(red: 0.1, green: 0.95, blue: 0.35, alpha: CGFloat(0.35 + 0.65 * Double(k)))
                            mat?.diffuse.contents = UIColor(red: 0.2, green: 1.0, blue: 0.45, alpha: 1)
                        },
                        .customAction(duration: 0.7) { node, t in
                            let k = Float(sin(Double(t) * .pi))
                            mat?.emission.contents = UIColor(red: 0.1, green: 0.95, blue: 0.35, alpha: CGFloat(1.0 - 0.55 * Double(k)))
                        }
                    ])
                    led.removeAllActions()
                    if !reduceMotion {
                        led.runAction(.repeatForever(pulse), forKey: "chargePulse")
                    } else {
                        mat?.emission.contents = UIColor(red: 0.15, green: 0.95, blue: 0.4, alpha: 0.9)
                    }
                } else {
                    led.removeAction(forKey: "chargePulse")
                    let g: CGFloat = batteryFraction > 0.5 ? 0.85 : (batteryFraction > 0.2 ? 0.7 : 0.25)
                    let r: CGFloat = batteryFraction > 0.5 ? 0.15 : (batteryFraction > 0.2 ? 0.85 : 0.9)
                    let b: CGFloat = batteryFraction > 0.5 ? 0.35 : 0.1
                    mat?.emission.contents = UIColor(red: r, green: g, blue: b, alpha: 0.55)
                    mat?.diffuse.contents = UIColor(red: r, green: g, blue: b, alpha: 1)
                }
            }

            if reduceMotion {
                root.removeAction(forKey: "spin")
                rotating = false
                root.eulerAngles.y = 0.35
            } else if !rotating {
                rotating = true
                let spin = SCNAction.repeatForever(.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 14))
                root.runAction(spin, forKey: "spin")
            }
        }
    }
}

enum WhoopStrapSceneBuilder {
    static func makeScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let root = SCNNode()
        root.name = "strapRoot"
        scene.rootNode.addChildNode(root)

        // Soft key + fill + rim so the matte black catches light like WHOOP's product turntable.
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 1100
        key.light?.color = UIColor(white: 0.95, alpha: 1)
        key.eulerAngles = SCNVector3(-0.7, 0.55, 0)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .omni
        fill.light?.intensity = 520
        fill.light?.color = UIColor(red: 0.55, green: 0.65, blue: 0.9, alpha: 1)
        fill.position = SCNVector3(-1.2, 0.8, 1.6)
        scene.rootNode.addChildNode(fill)

        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.intensity = 380
        rim.light?.color = UIColor(red: 0.4, green: 0.5, blue: 0.75, alpha: 1)
        rim.eulerAngles = SCNVector3(0.2, -2.4, 0)
        scene.rootNode.addChildNode(rim)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 220
        ambient.light?.color = UIColor(white: 0.35, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        // Camera
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.camera?.fieldOfView = 42
        cam.position = SCNVector3(0.1, 0.42, 2.15)
        cam.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cam)

        // Knit band — open horseshoe (WHOOP product hero is a partial loop, not a full ring)
        let bandMat = SCNMaterial()
        bandMat.diffuse.contents = UIColor(red: 0.18, green: 0.19, blue: 0.20, alpha: 1)
        bandMat.roughness.contents = 0.88
        bandMat.metalness.contents = 0.04

        // Build band from capsule segments along an arc
        let arcRoot = SCNNode()
        arcRoot.name = "band"
        let segments = 18
        let radius: Float = 0.78
        let startA: Float = -0.55
        let endA: Float = Float.pi + 0.55
        for i in 0..<segments {
            let t0 = startA + (endA - startA) * Float(i) / Float(segments)
            let t1 = startA + (endA - startA) * Float(i + 1) / Float(segments)
            let x0 = radius * sin(t0), z0 = radius * cos(t0)
            let x1 = radius * sin(t1), z1 = radius * cos(t1)
            let dx = x1 - x0, dz = z1 - z0
            let len = sqrt(dx * dx + dz * dz)
            let tube = SCNCapsule(capRadius: 0.078, height: CGFloat(len))
            tube.firstMaterial = bandMat
            let n = SCNNode(geometry: tube)
            n.position = SCNVector3((x0 + x1) / 2, 0, (z0 + z1) / 2)
            n.eulerAngles.x = .pi / 2
            n.eulerAngles.y = atan2(dx, dz)
            // flatten slightly for fabric ribbon look
            n.scale = SCNVector3(1.15, 1.0, 0.55)
            arcRoot.addChildNode(n)
        }
        root.addChildNode(arcRoot)

        // Sensor pod — rounded box, matte black with soft specular
        let pod = SCNBox(width: 0.48, height: 0.15, length: 0.62, chamferRadius: 0.05)
        let podMat = SCNMaterial()
        podMat.diffuse.contents = UIColor(red: 0.12, green: 0.125, blue: 0.13, alpha: 1)
        podMat.metalness.contents = 0.48
        podMat.roughness.contents = 0.32
        podMat.specular.contents = UIColor(white: 0.65, alpha: 1)
        pod.firstMaterial = podMat
        let podNode = SCNNode(geometry: pod)
        podNode.position = SCNVector3(0, 0.04, 0.72)
        podNode.name = "pod"
        root.addChildNode(podNode)

        // Soft underside shadow disc
        let shadow = SCNPlane(width: 1.1, height: 0.9)
        let shadowMat = SCNMaterial()
        shadowMat.diffuse.contents = UIColor(white: 0, alpha: 0.35)
        shadowMat.transparencyMode = .aOne
        shadowMat.writesToDepthBuffer = false
        shadow.firstMaterial = shadowMat
        let shadowNode = SCNNode(geometry: shadow)
        shadowNode.eulerAngles.x = -.pi / 2
        shadowNode.position = SCNVector3(0, -0.12, 0.35)
        root.addChildNode(shadowNode)

        // Engraved W — chevron bars
        let wMat = SCNMaterial()
        wMat.diffuse.contents = UIColor(white: 0.58, alpha: 1)
        wMat.metalness.contents = 0.85
        wMat.roughness.contents = 0.18
        let barL = SCNBox(width: 0.032, height: 0.01, length: 0.16, chamferRadius: 0.003)
        barL.firstMaterial = wMat
        let barLN = SCNNode(geometry: barL)
        barLN.eulerAngles.y = 0.38
        barLN.position = SCNVector3(-0.045, 0.12, 0.72)
        root.addChildNode(barLN)
        let barR = SCNBox(width: 0.032, height: 0.01, length: 0.16, chamferRadius: 0.003)
        barR.firstMaterial = wMat
        let barRN = SCNNode(geometry: barR)
        barRN.eulerAngles.y = -0.38
        barRN.position = SCNVector3(0.045, 0.12, 0.72)
        root.addChildNode(barRN)

        // LED slit
        let ledGeo = SCNBox(width: 0.06, height: 0.01, length: 0.012, chamferRadius: 0.002)
        let ledMat = SCNMaterial()
        ledMat.diffuse.contents = UIColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 1)
        ledMat.emission.contents = UIColor(red: 0.15, green: 0.85, blue: 0.35, alpha: 0.6)
        ledMat.lightingModel = .constant
        ledGeo.firstMaterial = ledMat
        let led = SCNNode(geometry: ledGeo)
        led.name = "led"
        led.position = SCNVector3(0.16, 0.12, 0.95)
        root.addChildNode(led)

        // PowerPack sibling (clips onto pod when attached)
        let pack = SCNBox(width: 0.44, height: 0.11, length: 0.55, chamferRadius: 0.04)
        let packMat = SCNMaterial()
        packMat.diffuse.contents = UIColor(red: 0.06, green: 0.065, blue: 0.07, alpha: 1)
        packMat.metalness.contents = 0.42
        packMat.roughness.contents = 0.34
        pack.firstMaterial = packMat
        let packNode = SCNNode(geometry: pack)
        packNode.name = "powerPack"
        packNode.position = SCNVector3(0, 0.16, 0.72)
        packNode.isHidden = true
        root.addChildNode(packNode)

        let packW = SCNBox(width: 0.1, height: 0.008, length: 0.1, chamferRadius: 0.002)
        packW.firstMaterial = wMat
        let packWN = SCNNode(geometry: packW)
        packWN.position = SCNVector3(0, 0.06, 0)
        packNode.addChildNode(packWN)

        root.eulerAngles.y = 0.4
        root.eulerAngles.x = -0.15
        return scene
    }
}

#endif
