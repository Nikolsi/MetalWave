//
//  GameViewController.swift
//  MetalApp macOS
//
//  Created by Nikolai Arsenov on 3/13/21.
//

import Cocoa
import MetalKit

// Our macOS specific view controller
class GameViewController: NSViewController {

    var renderer: TextureRenderer!
    var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MTKView else {
            print("View attached to GameViewController is not an MTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }

        mtkView.device = defaultDevice

        guard let newRenderer = TextureRenderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
    }
    
    override func mouseDown(with event: NSEvent) {
//        var location = view.convert(event.locationInWindow, from: nil)
//                location.y = view.bounds.height - location.y // Flip from AppKit default window coordinates to Metal viewport coordinates
//        self.renderer.handleInteraction(at: location)
    }
}
