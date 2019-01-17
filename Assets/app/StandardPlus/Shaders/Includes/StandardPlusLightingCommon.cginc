// This is an extension of a Unity built-in shader source.
//
// Everywhere except the regions noted by "Standard Plus Code" is under
// Copyright (c) 2016 Unity Technologies. MIT license (see license.txt).
//
// Standard Plus code by Paulo Cunha.

#ifndef STANDARD_PLUS_LIGHTING_COMMON_INCLUDED //Standard Plus Code
#define STANDARD_PLUS_LIGHTING_COMMON_INCLUDED //Standard Plus Code

fixed4 _LightColor0;
fixed4 _SpecColor;

struct UnityLight
{
    half3 color;
    half3 dir;
    half  ndotl; // Deprecated: Ndotl is now calculated on the fly and is no longer stored. Do not used it.
};

struct UnityIndirect
{
    half3 diffuse;
    half3 specular;
};

struct UnityGI
{
    UnityLight light;
    UnityIndirect indirect;
};

struct UnityGIInput
{
    UnityLight light; // pixel light, sent from the engine

    float3 worldPos;
    half3 worldViewDir;
    half atten;
    half3 ambient;

    //Standard Plus Code
    #if defined(SHADER_API_GLES)
	    uniform sampler2D lightTex;
	    uniform sampler2D lightTex2;
	    uniform sampler2D lightTex3;
	    uniform sampler2D lightTex4;
	    uniform sampler2D lightTex5;
    #else
	    sampler2D lightTex;
	    sampler2D lightTex2;
	    sampler2D lightTex3;
	    sampler2D lightTex4;
	    sampler2D lightTex5;
    #endif

    half3 lightTint;
    half3 lightTint2;
    half3 lightTint3;
    half3 lightTint4;
    half3 lightTint5;
    //End of Standard Plus Code

    // interpolated lightmap UVs are passed as full float precision data to fragment shaders
    // so lightmapUV (which is used as a tmp inside of lightmap fragment shaders) should
    // also be full float precision to avoid data loss before sampling a texture.
    float4 lightmapUV; // .xy = static lightmap UV, .zw = dynamic lightmap UV

    #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
    float4 boxMin[2];
    #endif
    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
    float4 boxMax[2];
    float4 probePosition[2];
    #endif
    // HDR cubemap properties, use to decompress HDR texture
    float4 probeHDR[2];
};

#endif
