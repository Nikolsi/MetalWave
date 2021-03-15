//
//  Plane.swift
//  MetalApp
//
//  Created by Nikolai Arsenov on 3/13/21.
//

import Metal
import MetalKit

import simd

class Plane {
    let device: MTLDevice
    public let mesh: MTKMesh
    
    init(device: MTLDevice, vertexDescriptor: MTLVertexDescriptor) throws {
        
        let mdlMesh = MDLMesh.newPlane(withDimensions: SIMD2<Float>(4, 8), segments: SIMD2<UInt32>(1, 1), geometryType: MDLGeometryType.triangles, allocator: MTKMeshBufferAllocator(device: device))
        
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
        
        guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
            throw RendererError.badVertexDescriptor
        }
        
        attributes[VertexAttribute.position.rawValue].name = MDLVertexAttributePosition
        attributes[VertexAttribute.texcoord.rawValue].name = MDLVertexAttributeTextureCoordinate
        
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
        self.device = device
        self.mesh = try MTKMesh(mesh:mdlMesh, device:device)
    }
}
