//
//  TextureRenderer.swift
//  MetalApp
//
//  Created by Nikolai Arsenov on 3/14/21.
//

import Metal
import MetalKit
import simd

class TextureRenderer: NSObject, MTKViewDelegate{
    
    weak var view: MTKView!
    
    
    let device: MTLDevice
    let queue: MTLCommandQueue
    let cps: MTLComputePipelineState
    var texture: MTLTexture
    
    var timer: Float = 0
    var timerBuffer: MTLBuffer
    var time = TimeInterval(0.0)
    
    
    var speed: Float = 0.0
    var speedBuffer: MTLBuffer
    var intense: Float = 700.0
    var intenseBuffer: MTLBuffer
    
    init?(metalKitView: MTKView){
        
        view = metalKitView
        view.framebufferOnly = false
        
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            device = defaultDevice
        } else {
            print("Metal is not supported")
            return nil
        }
        guard let commandQueue = self.device.makeCommandQueue() else { return nil }
        queue = commandQueue
        
        do {
            cps = try TextureRenderer   .buildComputePipelineState(device, view: metalKitView)
        }
        catch {
            print("Unable to compile render pipeline state")
            return nil
        }
        
        do {
            texture = try TextureRenderer.buildTexture(textureName: "Texture", device)
        }
        catch {
            print("Unable to load texture from main bundle")
            return nil
        }
        
        timerBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])!
        speedBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])!
        intenseBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])!

        
        super.init()
        
        view.delegate = self
        view.device = device
    }
    
    
    class func buildComputePipelineState(_ device:MTLDevice, view: MTKView) throws -> MTLComputePipelineState {
        
        let library = device.makeDefaultLibrary()!
        let kernal = library.makeFunction(name: "wave")!
        
        return try device.makeComputePipelineState(function: kernal)
    }
    
    class func buildTexture(textureName: String, _ device: MTLDevice) throws -> MTLTexture{
        
        let textureLoader = MTKTextureLoader(device: device)
        
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
        ]
        
        return try textureLoader.newTexture(name: textureName,
                                            scaleFactor: 1.0,
                                            bundle: nil,
                                            options: textureLoaderOptions)
    }
    
    func updateWithTimestep(_ timestep: TimeInterval) {
        time = time + timestep
        timer = Float(time)
        let bufferPointer = timerBuffer.contents()
        memcpy(bufferPointer, &timer, MemoryLayout<Float>.size)
    }
    
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in metalView: MTKView) {
        if let drawable = view.currentDrawable{
            
            let commandBuffer = queue.makeCommandBuffer()
            let commandEncoder = commandBuffer!.makeComputeCommandEncoder()
            commandEncoder!.setComputePipelineState(cps)
            metalView.framebufferOnly = false
            commandEncoder!.setTexture(drawable.texture, index: 0)
            commandEncoder!.setTexture(texture, index: 1)
            commandEncoder!.setBuffer(timerBuffer, offset: 0, index: 0)
            
            let timestep = 1.0 / TimeInterval(view.preferredFramesPerSecond)
            updateWithTimestep(timestep)
            
            commandEncoder!.setBuffer(speedBuffer, offset: 0, index: 1)
            commandEncoder!.setBytes(&speed, length: MemoryLayout<Float>.size, index: 1)
            
            commandEncoder!.setBuffer(intenseBuffer, offset: 0, index: 2)
            commandEncoder!.setBytes(&intense, length: MemoryLayout<Float>.size, index: 2)
            
            let threadGroupCount = MTLSizeMake(8, 8, 1)
            let threadGroups = MTLSizeMake(drawable.texture.width / threadGroupCount.width, drawable.texture.height / threadGroupCount.height, 1)
            commandEncoder!.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
            commandEncoder!.endEncoding()
            commandBuffer!.present(drawable)
            commandBuffer!.commit()
            
        }
        
    }
}
