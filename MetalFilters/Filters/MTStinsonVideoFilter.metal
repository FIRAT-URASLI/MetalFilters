//
//  MTStinsonVideoFilter.metal
//  MetalFilters
//
//  Created by alexiscn on 2018/6/8.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
#include "IFShaderLib.h"
using namespace metalpetal;

fragment float4 MTStinsonVideoFragment(VertexOut vertexIn [[ stage_in ]], 
    texture2d<float, access::sample> inputTexture [[ texture(0) ]], 
    texture2d<float, access::sample> map [[ texture(1) ]], 
    constant float & strength [[ buffer(0)]], 
    sampler textureSampler [[ sampler(0) ]])
{
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    float4 texel = inputTexture.sample(s, vertexIn.textureCoordinate);
    float4 inputTexel = texel;
    // exposure adjust B'=B*2^(EV/2.2), EV = 0.3
    texel.rgb = min(texel.rgb * 1.099, float3(1.0));

    // apply curves
    texel.r = map.sample(s, float2(texel.r, 0.5)).r;
    texel.g = map.sample(s, float2(texel.g, 0.5)).g;
    texel.b = map.sample(s, float2(texel.b, 0.5)).b;

    // ranged saturation
    // slight decrease in highlights and midtones
    // slight increase in shadows
    float luma = dot(float3(0.309, 0.609, 0.082), texel.rgb);
    float mixCoeff = mix(0.1, -0.09, min(1.0 - luma * 2.0, 1.0));
    texel.rgb = mix(texel.rgb, float3(luma), mixCoeff);
    texel.rgb = mix(inputTexel.rgb, texel.rgb, strength);
    return texel;
}
