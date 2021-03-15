//
//  Shaders.metal
//  MetalApp Shared
//
//  Created by Nikolai Arsenov on 3/13/21.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

vertex ColorInOut vertexShader(Vertex in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    ColorInOut out;

    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in.texCoord;

    return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
                               texture2d<half> colorMap     [[ texture(TextureIndexColor) ]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    half4 colorSample   = colorMap.sample(colorSampler, in.texCoord.xy);

    return float4(colorSample);// + uniforms.color;
}

// play with these parameters to custimize the effect
// ===================================================

// wave parameters
constant float strength = 0.02;
constant float frequency = 300.0;
constant float waveSpeed = 5.0;

// accent color to create a water effect
constant float4 sunlightColor = float4(1.0, 0.91, 0.75, 1.0);
constant float sunlightStrength = 5.0;
constant float centerLight = 2.;
constant float oblique = .25;

// water drop-point, default center of the Screen
// potentially can be moved into the compute shader parameter
// to come from outside as MouseEvent result
constant float2 dropPoint = float2(0.5, 0.5);

kernel void wave(texture2d<float, access::write> output [[texture(0)]],
                    texture2d<float, access::sample> input [[texture(1)]],
                    constant float &timer [[buffer(0)]],
                    constant float &speed [[buffer(1)]],
                    constant float &intense [[buffer(2)]],
                    uint2 gid [[thread_position_in_grid]])
{
    float time = timer * waveSpeed;
    
    int width = output.get_width();
    int height = output.get_height();
    float aspectRatio = width / height;
    float reversedAspectRatio = height/width;
    float2 uv = float2(gid) / float2(width, height);
    
    float2 distVec = uv - dropPoint;
    // keep waves equal dimensions
    distVec.x *= width > height ? aspectRatio : 1.0;
    distVec.y *= width < height ? reversedAspectRatio : 1.0;
    
    float distance = length(distVec);
    
    float multiplier = (distance < 1.0) ? ((distance - 1.0) * (distance - 1.0)) : 0.0;
    float addend = (sin(frequency * distance - time) + centerLight) * strength * multiplier;
    float2 newTexCoord = uv + addend * oblique;
    
    float4 colorToAdd = sunlightColor * sunlightStrength * addend;
    
    constexpr sampler textureSampler(coord::normalized,
                                     address::repeat,
                                     min_filter::linear,
                                     mag_filter::linear,
                                     mip_filter::linear );
    
    float4 color = input.sample(textureSampler,newTexCoord).rgba;
    output.write(color + colorToAdd, gid);
}
