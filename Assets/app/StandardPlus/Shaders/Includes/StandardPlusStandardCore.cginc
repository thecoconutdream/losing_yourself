// This is an extension of a Unity built-in shader source.
//
// Everywhere except the regions noted by "Standard Plus Code" is under
// Copyright (c) 2016 Unity Technologies. MIT license (see license.txt).
//
// Standard Plus code by Paulo Cunha.

#ifndef STANDARD_PLUS_STANDARD_CORE_INCLUDED //Standard Plus Code
#define STANDARD_PLUS_STANDARD_CORE_INCLUDED //Standard Plus Code

#include "UnityCG.cginc"
#include "UnityStandardConfig.cginc"

#include "StandardPlusStandardInput.cginc" //Standard Plus Code
#include "StandardPlusPBSLighting.cginc"   //Standard Plus Code

#include "UnityStandardUtils.cginc"
#include "UnityGBuffer.cginc"

#include "StandardPlusStandardBRDF.cginc" //Standard Plus Code
#include "StandardPlusAutoLight.cginc"    //Standard Plus Code
//-------------------------------------------------------------------------------------
// counterpart for NormalizePerPixelNormal
// skips normalization per-vertex and expects normalization to happen per-pixel
half3 NormalizePerVertexNormal (float3 n) // takes float to avoid overflow
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return normalize(n);
    #else
        return n; // will normalize per-pixel instead
    #endif
}

half3 NormalizePerPixelNormal (half3 n)
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return n;
    #else
        return normalize(n);
    #endif
}

//-------------------------------------------------------------------------------------
UnityLight MainLight ()
{
    UnityLight l;

    l.color = _LightColor0.rgb;
    l.dir = _WorldSpaceLightPos0.xyz;
    return l;
}

UnityLight AdditiveLight (half3 lightDir, half atten)
{
    UnityLight l;

    l.color = _LightColor0.rgb;
    l.dir = lightDir;
    #ifndef USING_DIRECTIONAL_LIGHT
        l.dir = NormalizePerPixelNormal(l.dir);
    #endif

    // shadow the light
    l.color *= atten;
    return l;
}

UnityLight DummyLight ()
{
    UnityLight l;
    l.color = 0;
    l.dir = half3 (0,1,0);
    return l;
}

UnityIndirect ZeroIndirect ()
{
    UnityIndirect ind;
    ind.diffuse = 0;
    ind.specular = 0;
    return ind;
}

UnityIndirect SmallIndirect ()
{
    UnityIndirect ind;
    ind.diffuse = 0.01;
    ind.specular = 0;
    return ind;
}


//-------------------------------------------------------------------------------------
// Common fragment setup

// deprecated
half3 WorldNormal(half4 tan2world[3])
{
    return normalize(tan2world[2].xyz);
}

// deprecated
#ifdef _TANGENT_TO_WORLD
    half3x3 ExtractTangentToWorldPerPixel(half4 tan2world[3])
    {
        half3 t = tan2world[0].xyz;
        half3 b = tan2world[1].xyz;
        half3 n = tan2world[2].xyz;

    #if UNITY_TANGENT_ORTHONORMALIZE
        n = NormalizePerPixelNormal(n);

        // ortho-normalize Tangent
        t = normalize (t - n * dot(t, n));

        // recalculate Binormal
        half3 newB = cross(n, t);
        b = newB * sign (dot (newB, b));
    #endif

        return half3x3(t, b, n);
    }
#else
    half3x3 ExtractTangentToWorldPerPixel(half4 tan2world[3])
    {
        return half3x3(0,0,0,0,0,0,0,0,0);
    }
#endif

half3 PerPixelWorldNormal(float4 i_tex, half4 tangentToWorld[3])
{
#ifdef _NORMALMAP
    half3 tangent = tangentToWorld[0].xyz;
    half3 binormal = tangentToWorld[1].xyz;
    half3 normal = tangentToWorld[2].xyz;

    #if UNITY_TANGENT_ORTHONORMALIZE
        normal = NormalizePerPixelNormal(normal);

        // ortho-normalize Tangent
        tangent = normalize (tangent - normal * dot(tangent, normal));

        // recalculate Binormal
        half3 newB = cross(normal, tangent);
        binormal = newB * sign (dot (newB, binormal));
    #endif

    half3 normalTangent = NormalInTangentSpace(i_tex);
    half3 normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
#else
    half3 normalWorld = normalize(tangentToWorld[2].xyz);
#endif
    return normalWorld;
}

#ifdef _PARALLAXMAP
    #define IN_VIEWDIR4PARALLAX(i) NormalizePerPixelNormal(half3(i.tangentToWorldAndPackedData[0].w,i.tangentToWorldAndPackedData[1].w,i.tangentToWorldAndPackedData[2].w))
    #define IN_VIEWDIR4PARALLAX_FWDADD(i) NormalizePerPixelNormal(i.viewDirForParallax.xyz)
#else
    #define IN_VIEWDIR4PARALLAX(i) half3(0,0,0)
    #define IN_VIEWDIR4PARALLAX_FWDADD(i) half3(0,0,0)
#endif

#if UNITY_REQUIRE_FRAG_WORLDPOS
    #if UNITY_PACK_WORLDPOS_WITH_TANGENT
        #define IN_WORLDPOS(i) half3(i.tangentToWorldAndPackedData[0].w,i.tangentToWorldAndPackedData[1].w,i.tangentToWorldAndPackedData[2].w)
    #else
        #define IN_WORLDPOS(i) i.posWorld
    #endif
    #define IN_WORLDPOS_FWDADD(i) i.posWorld
#else
    #define IN_WORLDPOS(i) half3(0,0,0)
    #define IN_WORLDPOS_FWDADD(i) half3(0,0,0)
#endif

#define IN_LIGHTDIR_FWDADD(i) half3(i.tangentToWorldAndLightDir[0].w, i.tangentToWorldAndLightDir[1].w, i.tangentToWorldAndLightDir[2].w)

#define FRAGMENT_SETUP(x) FragmentCommonData x = \
    FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndPackedData, IN_WORLDPOS(i));

#define FRAGMENT_SETUP_FWDADD(x) FragmentCommonData x = \
    FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX_FWDADD(i), i.tangentToWorldAndLightDir, IN_WORLDPOS_FWDADD(i));

struct FragmentCommonData
{
    half3 diffColor, specColor;
    // Note: smoothness & oneMinusReflectivity for optimization purposes, mostly for DX9 SM2.0 level.
    // Most of the math is being done on these (1-x) values, and that saves a few precious ALU slots.
    half oneMinusReflectivity, smoothness;
    half3 normalWorld, eyeVec, posWorld;
    half alpha;
    half3 albedo;

#if UNITY_STANDARD_SIMPLE
    half3 reflUVW;
#endif

#if UNITY_STANDARD_SIMPLE
    half3 tangentSpaceNormal;
#endif
};

#ifndef UNITY_SETUP_BRDF_INPUT
    #define UNITY_SETUP_BRDF_INPUT SpecularSetup
#endif

inline FragmentCommonData SpecularSetup (float4 i_tex)
{
    half4 specGloss = SpecularGloss(i_tex.xy);
    half3 specColor = specGloss.rgb;
    half smoothness = specGloss.a;

    half oneMinusReflectivity;
    half3 diffColor = EnergyConservationBetweenDiffuseAndSpecular (Albedo(i_tex), specColor, /*out*/ oneMinusReflectivity);

    FragmentCommonData o = (FragmentCommonData)0;
    o.albedo = Albedo(i_tex);
    o.diffColor = diffColor;
    o.specColor = specColor;
    o.oneMinusReflectivity = oneMinusReflectivity;
    o.smoothness = smoothness;
    return o;
}

inline FragmentCommonData MetallicSetup (float4 i_tex)
{
    half2 metallicGloss = MetallicGloss(i_tex.xy);
    half metallic = metallicGloss.x;
    half smoothness = metallicGloss.y; // this is 1 minus the square root of real roughness m.

    half oneMinusReflectivity;
    half3 specColor;
    half3 diffColor = DiffuseAndSpecularFromMetallic (Albedo(i_tex), metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

    FragmentCommonData o = (FragmentCommonData)0;
    o.albedo = Albedo(i_tex);
    o.diffColor = diffColor;
    o.specColor = specColor;
    o.oneMinusReflectivity = oneMinusReflectivity;
    o.smoothness = smoothness;
    return o;
}

inline FragmentCommonData FragmentSetup (float4 i_tex, half3 i_eyeVec, half3 i_viewDirForParallax, half4 tangentToWorld[3], half3 i_posWorld)
{
    i_tex = Parallax(i_tex, i_viewDirForParallax);

    half alpha = Alpha(i_tex.xy);
    #if defined(_ALPHATEST_ON)
        clip (alpha - _Cutoff);
    #endif

    FragmentCommonData o = UNITY_SETUP_BRDF_INPUT (i_tex);
    o.normalWorld = PerPixelWorldNormal(i_tex, tangentToWorld);
    o.eyeVec = NormalizePerPixelNormal(i_eyeVec);
    o.posWorld = i_posWorld;

    // NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
    o.diffColor = PreMultiplyAlpha (o.diffColor, alpha, o.oneMinusReflectivity, /*out*/ o.alpha);
    return o;
}


inline UnityGI FragmentGI (FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light, bool reflections)
{
    UnityGIInput d;
    d.light = light;
    d.worldPos = s.posWorld;
    d.worldViewDir = -s.eyeVec;
    d.atten = atten;

    //Standard Plus Code
    d.lightTex = _CustomLightmap;
    d.lightTex2 = _CustomLightmap2;
    d.lightTex3 = _CustomLightmap3;
    d.lightTex4 = _CustomLightmap4;
    d.lightTex5 = _CustomLightmap5;

    d.lightTint = _LightmapTint;
    d.lightTint2 = _LightmapTint2;
    d.lightTint3 = _LightmapTint3;
    d.lightTint4 = _LightmapTint4;
    d.lightTint5 = _LightmapTint5;
    //End of Standard Plus Code

    #if defined(_CUSTOM_LIGHTMAP) || defined(DYNAMICLIGHTMAP_ON)
        d.ambient = 0;
        d.lightmapUV = i_ambientOrLightmapUV;
    #else
        d.ambient = i_ambientOrLightmapUV.rgb;
        d.lightmapUV = 0;
    #endif

    d.probeHDR[0] = unity_SpecCube0_HDR;
    d.probeHDR[1] = unity_SpecCube1_HDR;
    #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
      d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
    #endif
    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
      d.boxMax[0] = unity_SpecCube0_BoxMax;
      d.probePosition[0] = unity_SpecCube0_ProbePosition;
      d.boxMax[1] = unity_SpecCube1_BoxMax;
      d.boxMin[1] = unity_SpecCube1_BoxMin;
      d.probePosition[1] = unity_SpecCube1_ProbePosition;
    #endif

    if(reflections)
    {
        Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.smoothness, -s.eyeVec, s.normalWorld, s.specColor);
        // Replace the reflUVW if it has been compute in Vertex shader. Note: the compiler will optimize the calcul in UnityGlossyEnvironmentSetup itself
        #if UNITY_STANDARD_SIMPLE
            g.reflUVW = s.reflUVW;
        #endif

        return UnityGlobalIllumination (d, occlusion, s.normalWorld, g);
    }
    else
    {
        return UnityGlobalIllumination (d, occlusion, s.normalWorld);
    }
}

inline UnityGI FragmentGI (FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light)
{
    return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, true);
}


//-------------------------------------------------------------------------------------
half4 OutputForward (half4 output, half alphaFromSurface)
{
    #if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
        output.a = alphaFromSurface;
    #else
        UNITY_OPAQUE_ALPHA(output.a);
    #endif
    return output;
}

inline half4 VertexGIForward(VertexInput v, float3 posWorld, half3 normalWorld)
{
    half4 ambientOrLightmapUV = 0;
    // Static lightmaps
    #if defined(_CUSTOM_LIGHTMAP) //Standard Plus Code
    	ambientOrLightmapUV.xy = (v.uv1.xy - float2(_uvLmZ, _uvLmW)) / float2(_uvLmX, _uvLmY);
    	ambientOrLightmapUV.zw = 0;
    // Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
    #elif UNITY_SHOULD_SAMPLE_SH
        #ifdef VERTEXLIGHT_ON
            // Approximated illumination from non-important point lights
            ambientOrLightmapUV.rgb = Shade4PointLights (
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, posWorld, normalWorld);
        #endif

        ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, ambientOrLightmapUV.rgb);
    #endif

    #if defined (DYNAMICLIGHTMAP_ON)
        ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif

    return ambientOrLightmapUV;
}

// ------------------------------------------------------------------
//  Base forward pass (directional light, emission, lightmaps, ...)

struct VertexOutputForwardBase
{
    float4 pos                              : SV_POSITION;
    float4 tex                              : TEXCOORD0;
    half3 eyeVec                            : TEXCOORD1;
    half4 tangentToWorldAndPackedData[3]    : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]

    //for refraction, fit only into SM3.0
    half4 screenPos 				    	 : TEXCOORD9; //Standard Plus Code

    half4 ambientOrLightmapUV               : TEXCOORD5;    // SH or Lightmap UV
    UNITY_SHADOW_COORDS(6)
    UNITY_FOG_COORDS(7)

    // next ones would not fit into SM2.0 limits, but they are always for SM3.0+
    #if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
        float3 posWorld                 : TEXCOORD8;
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

VertexOutputForwardBase vertForwardBase (VertexInput v)
{
    UNITY_SETUP_INSTANCE_ID(v);
    VertexOutputForwardBase o;
    UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBase, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
    #if UNITY_REQUIRE_FRAG_WORLDPOS
        #if UNITY_PACK_WORLDPOS_WITH_TANGENT
            o.tangentToWorldAndPackedData[0].w = posWorld.x;
            o.tangentToWorldAndPackedData[1].w = posWorld.y;
            o.tangentToWorldAndPackedData[2].w = posWorld.z;
        #else
            o.posWorld = posWorld.xyz;
        #endif
    #endif
    o.pos = UnityObjectToClipPos(v.vertex);

    //refraction
	o.screenPos = o.pos; //Standard Plus Code

    o.tex = TexCoords(v);
    o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    #ifdef _TANGENT_TO_WORLD
        float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

        float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
        o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
        o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
        o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
    #else
        o.tangentToWorldAndPackedData[0].xyz = 0;
        o.tangentToWorldAndPackedData[1].xyz = 0;
        o.tangentToWorldAndPackedData[2].xyz = normalWorld;
    #endif

    //We need this for shadow receving
    UNITY_TRANSFER_SHADOW(o, v.uv1);

    o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);

    #ifdef _PARALLAXMAP
        TANGENT_SPACE_ROTATION;
        half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
        o.tangentToWorldAndPackedData[0].w = viewDirForParallax.x;
        o.tangentToWorldAndPackedData[1].w = viewDirForParallax.y;
        o.tangentToWorldAndPackedData[2].w = viewDirForParallax.z;
    #endif

    UNITY_TRANSFER_FOG(o,o.pos);
    return o;
}

//Standard Plus Code

#if defined(_TRANSLUCENCY)
	half3 Translucency(FragmentCommonData s, UnityLight light, fixed atten, half4 thickness) {

		half4 translucencyColor = _TranslucencyColor;

		half3 LTLight = light.dir + s.normalWorld * _Distortion;															
		half LTDot = pow(saturate(dot(-s.eyeVec, -LTLight)), _Power) * _Scale;
		half3 LT = (LTDot + _Ambient) * thickness * atten;  

		return  s.albedo.rgb * LT * translucencyColor * light.color;
	}
#endif

#if defined(_REFRACTION)

	half4 AdjustTint(FragmentCommonData s, half4 thicknessMap, half4 levels){
		//Adjust tint based on thickness map

		float4 constK = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 decoup1 = lerp(float4(float4(s.albedo.rgb,0.0).zy, constK.wz), 
        						float4(float4(s.albedo.rgb,0.0).yz, constK.xy), 
        						step(float4(s.albedo.rgb,0.0).z, float4(s.albedo.rgb,0.0).y));
        float4 decoup2 = lerp(float4(decoup1.xyw, float4(s.albedo.rgb,0.0).x), 
        						float4(float4(s.albedo.rgb,0.0).x, decoup1.yzx), step(decoup1.x, 
        						float4(s.albedo.rgb,0.0).x));
        float decoup3 = decoup2.x - min(decoup2.w, decoup2.y);
        float zeroF = 1.0e-10;
        float3 recoup = float3(abs(decoup2.z + (decoup2.w - decoup2.y) / 
        					(6.0 * decoup3 + zeroF)), decoup3 / (decoup2.x + zeroF), 
        					decoup2.x);

        #ifdef _COLORLEVELS
        	#if !defined(_AFFECTSCOLOR_OFF)
		        float3 thicknessAdjust = (lerp(float3(1, 1, 1), saturate(3.0 * abs(1.0 - 2.0 * frac(recoup.r + 
		        							float3(0.0, -1.0 / 3.0, 1.0 / 3.0))) - 1), (recoup.g * levels)) * 
		        							(recoup.b * (1.0 - (levels * 1))));
	        #else
		        float3 thicknessAdjust = (lerp(float3(1, 1, 1), saturate(3.0 * abs(1.0 - 2.0 * frac(recoup.r + 
							float3(0.0, -1.0 / 3.0, 1.0 / 3.0))) - 1), recoup.g) * 
							recoup.b);

	        #endif
        #else
        	#if !defined(_AFFECTSCOLOR_OFF)
		        float3 thicknessAdjust = (lerp(float3(1, 1, 1), saturate(3.0 * abs(1.0 - 2.0 * frac(recoup.r + 
	    							float3(0.0, -1.0 / 3.0, 1.0 / 3.0))) - 1), (recoup.g * thicknessMap.r)) * 
	    							(recoup.b * (1.0 - (thicknessMap.r * 1))));
	    	#else
		        float3 thicknessAdjust = (lerp(float3(1, 1, 1), saturate(3.0 * abs(1.0 - 2.0 * frac(recoup.r + 
					float3(0.0, -1.0 / 3.0, 1.0 / 3.0))) - 1), recoup.g) * 
					recoup.b);
	    	#endif
        #endif        

	    return saturate(half4(s.albedo, 1) + half4(thicknessAdjust, 1));
	}

	half4 Refraction(FragmentCommonData s, VertexOutputForwardBase i, half4 thicknessMap, half4 levels){
		#if UNITY_UV_STARTS_AT_TOP
	        float grabSign = -_ProjectionParams.x;
	    #else
	        float grabSign = _ProjectionParams.x;
	    #endif

	    i.screenPos = float4( i.screenPos.xy / i.screenPos.w, 0, 0 );
	    i.screenPos.y *= _ProjectionParams.x;

		float2 normalView = mul( UNITY_MATRIX_V, float4(s.normalWorld,0) ).xyz.rgb.rg;

		#if defined(_REFRACTIONLEVELS)
			#if !defined(_AFFECTSREFRACTION_OFF)	
				float3 refracCalc = ((levels.rgb * float3(normalView, 0.0) * _RefractionAmount * -0.1) + 
		    		   		float3((normalView * pow((1.0-max(0,dot(s.normalWorld, -s.eyeVec))), (15.5 - _FresnelLength)) * _FresnelAmount * -0.1), 0.0));
		    #else
		    	float3 refracCalc = ((float3(normalView, 0.0) * _RefractionAmount * -0.1) + 
		    		   		float3((normalView * pow((1.0-max(0,dot(s.normalWorld, -s.eyeVec))), (15.5 - _FresnelLength)) * _FresnelAmount * -0.1), 0.0));
		    #endif
	    #else
	    	#if !defined(_AFFECTSREFRACTION_OFF)
				float3 refracCalc = ((thicknessMap.rgb * float3(normalView, 0.0) * _RefractionAmount * -0.1) + 
			   		float3((normalView * pow((1.0-max(0,dot(s.normalWorld, -s.eyeVec))), (15.5 - _FresnelLength)) * _FresnelAmount * -0.1), 0.0));
			#else
				float3 refracCalc = ((float3(normalView, 0.0) * _RefractionAmount * -0.1) + 
				   		float3((normalView * pow((1.0-max(0,dot(s.normalWorld, -s.eyeVec))), (15.5 - _FresnelLength)) * _FresnelAmount * -0.1), 0.0));
			#endif
		#endif


		float2 sceneUVs = float2(1,grabSign) * i.screenPos.xy * 0.5 + 0.5 + refracCalc.rg;


	    // Blur
	    float offsetD[5] = { 0.0, 1.0, 2.0, 3.0, 4.0 };
		float weight[5] = { 0.2270270270, 0.0972972973, 0.0608108108, 0.02702702705, 0.0081081081 };

		float3 tex;

		#if defined(_FULLBACKGROUND)
			#if defined(_BLUR_ON)
				#if defined(_METALLICGLOSSMAP) || defined(_SPECGLOSSMAP)
					tex = tex2D(_GrabTexture, sceneUVs).rgb * weight[0];

					for(int i = 1; i < 5; i++){
						tex += tex2D(_GrabTexture, sceneUVs + float2(0.0, offsetD[i] * _SizeBlur * saturate(((1 - s.smoothness) + 0.05)))/_ScreenParams.y).rgb * weight[i];
						tex += tex2D(_GrabTexture, sceneUVs - float2(0.0, offsetD[i] * _SizeBlur * saturate(((1 - s.smoothness) + 0.05)))/_ScreenParams.y).rgb * weight[i];
						tex += tex2D(_GrabTexture, sceneUVs + float2(offsetD[i] * _SizeBlur * saturate(((1 - s.smoothness) + 0.05)), 0.0)/_ScreenParams.x).rgb * weight[i];
						tex += tex2D(_GrabTexture, sceneUVs - float2(offsetD[i] * _SizeBlur * saturate(((1 - s.smoothness) + 0.05)), 0.0)/_ScreenParams.x).rgb * weight[i];
					}

				#else

					tex = tex2D(_GrabTexture, sceneUVs).rgb * weight[0];

					for(int i = 1; i < 5; i++){
						tex += tex2D(_GrabTexture, sceneUVs + float2(0.0, offsetD[i] * _SizeBlur)/_ScreenParams.y).rgb * weight[i];
						tex += tex2D(_GrabTexture, sceneUVs - float2(0.0, offsetD[i] * _SizeBlur)/_ScreenParams.y).rgb * weight[i];
						tex += tex2D(_GrabTexture, sceneUVs + float2(offsetD[i] * _SizeBlur, 0.0)/_ScreenParams.x).rgb * weight[i];
						tex += tex2D(_GrabTexture, sceneUVs - float2(offsetD[i] * _SizeBlur, 0.0)/_ScreenParams.x).rgb * weight[i];
					}

				#endif
			#else
				tex = tex2D(_GrabTexture, sceneUVs).rgb;
			#endif

		#else

			#if defined(_BLUR_ON)
				#if defined(_METALLICGLOSSMAP) || defined(_SPECGLOSSMAP)
					tex = tex2D(_BackgroundTex, sceneUVs).rgb * weight[0];

					for(int i = 1; i < 5; i++){
						tex += tex2D(_BackgroundTex, sceneUVs + float2(0.0, offsetD[i] * _SizeBlur * saturate(((1 - s.smoothness) + 0.05)))/_ScreenParams.y).rgb * weight[i];
						tex += tex2D(_BackgroundTex, sceneUVs - float2(0.0, offsetD[i] * _SizeBlur * saturate(((1 - s.smoothness) + 0.05)))/_ScreenParams.y).rgb * weight[i];
						tex += tex2D(_BackgroundTex, sceneUVs + float2(offsetD[i] * _SizeBlur * saturate(((1 - s.smoothness) + 0.05)), 0.0)/_ScreenParams.x).rgb * weight[i];
						tex += tex2D(_BackgroundTex, sceneUVs - float2(offsetD[i] * _SizeBlur * saturate(((1 - s.smoothness) + 0.05)), 0.0)/_ScreenParams.x).rgb * weight[i];
					}

				#else
					tex = tex2D(_BackgroundTex, sceneUVs).rgb * weight[0];

					for(int i = 1; i < 5; i++){
						tex += tex2D(_BackgroundTex, sceneUVs + float2(0.0, offsetD[i] * _SizeBlur)/_ScreenParams.y).rgb * weight[i];
						tex += tex2D(_BackgroundTex, sceneUVs - float2(0.0, offsetD[i] * _SizeBlur)/_ScreenParams.y).rgb * weight[i];
						tex += tex2D(_BackgroundTex, sceneUVs + float2(offsetD[i] * _SizeBlur, 0.0)/_ScreenParams.x).rgb * weight[i];
						tex += tex2D(_BackgroundTex, sceneUVs - float2(offsetD[i] * _SizeBlur, 0.0)/_ScreenParams.x).rgb * weight[i];
					}

				#endif

			#else
				tex = tex2D(_BackgroundTex, sceneUVs).rgb;
			#endif
			 
		#endif

		return half4(tex, 1.0);
	}

#endif

//End of Standard Plus Code


half4 fragForwardBaseInternal (VertexOutputForwardBase i)
{
    FRAGMENT_SETUP(s)

    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    UnityLight mainLight = MainLight ();
    UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);

    //Standard Plus Code
    half4 thicknessMap;
    half4 levels = half4(0,0,0,0);
    half4 colorlevels = half4(0,0,0,0);
    half3 tlContribution = half3(0,0,0);

    #if defined (_TRANSLUCENCY) || defined (_REFRACTION)
		thicknessMap = tex2D(_ThicknessMap, i.tex.xy);
	#endif

    #if defined (_REFRACTIONLEVELS) || defined (_LEVELS)
    	#if !defined(_AFFECTSREFRACTION_OFF)
    		levels = (_OUTMin + ( ((thicknessMap * _INMiddle) - _INMin) * (_OUTMax - _OUTMin) ) / (_INMax - _INMin));
    	#else
    		levels = (_OUTMin + ( (_INMiddle - _INMin) * (_OUTMax - _OUTMin) ) / (_INMax - _INMin));
    	#endif
    #endif

    #if defined (_COLORLEVELS)
    	#if !defined(_AFFECTSCOLOR_OFF)
    		colorlevels = (_OUTMinCOLOR + ( ((thicknessMap * _INMiddleCOLOR) - _INMinCOLOR) * (_OUTMaxCOLOR - _OUTMinCOLOR) ) / (_INMaxCOLOR - _INMinCOLOR));
    	#else
    		colorlevels = (_OUTMinCOLOR + ( (_INMiddleCOLOR - _INMinCOLOR) * (_OUTMaxCOLOR - _OUTMinCOLOR) ) / (_INMaxCOLOR - _INMinCOLOR));
    	#endif
    #endif

	#if defined(_TRANSLUCENCY)
		#ifdef _LEVELS		
			tlContribution = Translucency(s, mainLight, atten, levels);
		#else
			tlContribution = Translucency(s, mainLight, atten, thicknessMap);
		#endif															
	#endif

	#if defined (_REFRACTION)

		half4 sceneColor = Refraction(s, i, thicknessMap, levels);

	    half occlusion = Occlusion(i.tex.xy);

	    UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

	    gi.light.color *= s.alpha;
	    gi.indirect.diffuse *= s.alpha;

	    half4 c = UNITY_BRDF_PBS (half4(0,0,0,0), s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
	    half4 cOpaque = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);

	    c.rgb = c.rgb + (sceneColor.rgb * AdjustTint(s, thicknessMap, colorlevels).rgb);

	    c = lerp(c, cOpaque, s.alpha);

	// End of Standard Plus Code	    	   	   
    #else
    	half occlusion = Occlusion(i.tex.xy);
    	UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

    	half4 c = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
    #endif

    //Standard Plus Code
    #if defined(_TRANSLUCENCY)
    	c.rgb += tlContribution;
    #endif
    //End of Standard Plus Code

    c.rgb += Emission(i.tex.xy);

    UNITY_APPLY_FOG(i.fogCoord, c.rgb);

    #if defined (_REFRACTION) //Standard Plus Code
    	return c;			  //Standard Plus Code
    #else
    	return OutputForward (c, s.alpha);
    #endif
}

half4 fragForwardBase (VertexOutputForwardBase i) : SV_Target   // backward compatibility (this used to be the fragment entry function)
{
    return fragForwardBaseInternal(i);
}

// ------------------------------------------------------------------
//  Additive forward pass (one light per pass)

struct VertexOutputForwardAdd
{
    float4 pos                          : SV_POSITION;
    float4 tex                          : TEXCOORD0;
    half3 eyeVec                        : TEXCOORD1;
    half4 tangentToWorldAndLightDir[3]  : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:lightDir]
    float3 posWorld                     : TEXCOORD5;
    UNITY_SHADOW_COORDS(6)
    UNITY_FOG_COORDS(7)

    // next ones would not fit into SM2.0 limits, but they are always for SM3.0+
#if defined(_PARALLAXMAP)
    half3 viewDirForParallax            : TEXCOORD8;
#endif

    UNITY_VERTEX_OUTPUT_STEREO
};

VertexOutputForwardAdd vertForwardAdd (VertexInput v)
{
    UNITY_SETUP_INSTANCE_ID(v);
    VertexOutputForwardAdd o;
    UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAdd, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
    o.pos = UnityObjectToClipPos(v.vertex);

    o.tex = TexCoords(v);
    o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
    o.posWorld = posWorld.xyz;
    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    #ifdef _TANGENT_TO_WORLD
        float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

        float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
        o.tangentToWorldAndLightDir[0].xyz = tangentToWorld[0];
        o.tangentToWorldAndLightDir[1].xyz = tangentToWorld[1];
        o.tangentToWorldAndLightDir[2].xyz = tangentToWorld[2];
    #else
        o.tangentToWorldAndLightDir[0].xyz = 0;
        o.tangentToWorldAndLightDir[1].xyz = 0;
        o.tangentToWorldAndLightDir[2].xyz = normalWorld;
    #endif
    //We need this for shadow receiving
    UNITY_TRANSFER_SHADOW(o, v.uv1);

    float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
    #ifndef USING_DIRECTIONAL_LIGHT
        lightDir = NormalizePerVertexNormal(lightDir);
    #endif
    o.tangentToWorldAndLightDir[0].w = lightDir.x;
    o.tangentToWorldAndLightDir[1].w = lightDir.y;
    o.tangentToWorldAndLightDir[2].w = lightDir.z;

    #ifdef _PARALLAXMAP
        TANGENT_SPACE_ROTATION;
        o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
    #endif

    UNITY_TRANSFER_FOG(o,o.pos);
    return o;
}

half4 fragForwardAddInternal (VertexOutputForwardAdd i)
{
    FRAGMENT_SETUP_FWDADD(s)

    UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld)
    UnityLight light = AdditiveLight (IN_LIGHTDIR_FWDADD(i), atten);
    UnityIndirect noIndirect = ZeroIndirect ();
    UnityIndirect smallIndirect = SmallIndirect ();

    //Standard Plus Code
    half4 thicknessMap;
    half4 levels = half4(0,0,0,0);
    half4 colorlevels = half4(0,0,0,0);
    half3 tlContribution = half3(0,0,0);

    #if defined (_TRANSLUCENCY) || defined (_REFRACTION)
		thicknessMap = tex2D(_ThicknessMap, i.tex.xy);
	#endif

    #if defined (_LEVELS) || defined (_REFRACTIONLEVELS)
    	#if !defined(_AFFECTSREFRACTION_OFF)
    		levels = (_OUTMin + ( ((thicknessMap * _INMiddle) - _INMin) * (_OUTMax - _OUTMin) ) / (_INMax - _INMin));
    	#else
    		levels = (_OUTMin + ( (_INMiddle - _INMin) * (_OUTMax - _OUTMin) ) / (_INMax - _INMin));
    	#endif
    #endif

    #if defined (_COLORLEVELS)
    	#if !defined(_AFFECTSCOLOR_OFF)
    		colorlevels = (_OUTMinCOLOR + ( ((thicknessMap * _INMiddleCOLOR) - _INMinCOLOR) * (_OUTMaxCOLOR - _OUTMinCOLOR) ) / (_INMaxCOLOR - _INMinCOLOR));
    	#else
    		colorlevels = (_OUTMinCOLOR + ( (_INMiddleCOLOR - _INMinCOLOR) * (_OUTMaxCOLOR - _OUTMinCOLOR) ) / (_INMaxCOLOR - _INMinCOLOR));
    	#endif
    #endif

	#if defined(_TRANSLUCENCY)
		#ifdef _LEVELS		
			tlContribution = Translucency(s, light, 1, levels);
		#else
			tlContribution = Translucency(s, light, 1, thicknessMap);
		#endif															
	#endif

	#if defined(_REFRACTION)

		s.specColor *= AdjustTint(s, thicknessMap, levels);

		half4 c = UNITY_BRDF_PBS (half3(0,0,0), s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect);
		half4 cOpaque = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect);

		c = lerp(c, cOpaque, s.alpha);

	//End of Standard Plus Code
	#else
		half4 c = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect);
	#endif
    

    #if defined(_TRANSLUCENCY)   //Standard Plus Code
    	c.rgb += tlContribution; //Standard Plus Code
    #endif						 //Standard Plus Code

    UNITY_APPLY_FOG_COLOR(i.fogCoord, c.rgb, half4(0,0,0,0)); // fog towards black in additive pass

    #if defined (_REFRACTION) //Standard Plus Code
    	return c;			  //Standard Plus Code
    #else
    	return OutputForward (c, s.alpha);
    #endif

}

half4 fragForwardAdd (VertexOutputForwardAdd i) : SV_Target     // backward compatibility (this used to be the fragment entry function)
{
    return fragForwardAddInternal(i);
}

// ------------------------------------------------------------------
//  Deferred pass

struct VertexOutputDeferred
{
    float4 pos                          : SV_POSITION;
    float4 tex                          : TEXCOORD0;
    half3 eyeVec                        : TEXCOORD1;
    half4 tangentToWorldAndPackedData[3]: TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
    half4 ambientOrLightmapUV           : TEXCOORD5;    // SH or Lightmap UVs

    #if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
        float3 posWorld                     : TEXCOORD6;
    #endif

    UNITY_VERTEX_OUTPUT_STEREO
};


VertexOutputDeferred vertDeferred (VertexInput v)
{
    UNITY_SETUP_INSTANCE_ID(v);
    VertexOutputDeferred o;
    UNITY_INITIALIZE_OUTPUT(VertexOutputDeferred, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
    #if UNITY_REQUIRE_FRAG_WORLDPOS
        #if UNITY_PACK_WORLDPOS_WITH_TANGENT
            o.tangentToWorldAndPackedData[0].w = posWorld.x;
            o.tangentToWorldAndPackedData[1].w = posWorld.y;
            o.tangentToWorldAndPackedData[2].w = posWorld.z;
        #else
            o.posWorld = posWorld.xyz;
        #endif
    #endif
    o.pos = UnityObjectToClipPos(v.vertex);

    o.tex = TexCoords(v);
    o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    #ifdef _TANGENT_TO_WORLD
        float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

        float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
        o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
        o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
        o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
    #else
        o.tangentToWorldAndPackedData[0].xyz = 0;
        o.tangentToWorldAndPackedData[1].xyz = 0;
        o.tangentToWorldAndPackedData[2].xyz = normalWorld;
    #endif

    o.ambientOrLightmapUV = 0;
    #if defined(_CUSTOM_LIGHTMAP)
    	o.ambientOrLightmapUV.xy = (v.uv1.xy - float2(_uvLmZ, _uvLmW)) / float2(_uvLmX, _uvLmY);
    #elif UNITY_SHOULD_SAMPLE_SH
        o.ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, o.ambientOrLightmapUV.rgb);
    #endif

    #if defined (DYNAMICLIGHTMAP_ON)
        o.ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif

    #ifdef _PARALLAXMAP
        TANGENT_SPACE_ROTATION;
        half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
        o.tangentToWorldAndPackedData[0].w = viewDirForParallax.x;
        o.tangentToWorldAndPackedData[1].w = viewDirForParallax.y;
        o.tangentToWorldAndPackedData[2].w = viewDirForParallax.z;
    #endif

    return o;
}

void fragDeferred (
    VertexOutputDeferred i,
    out half4 outGBuffer0 : SV_Target0,
    out half4 outGBuffer1 : SV_Target1,
    out half4 outGBuffer2 : SV_Target2,
    out half4 outEmission : SV_Target3          // RT3: emission (rgb), --unused-- (a)
#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
    ,out half4 outShadowMask : SV_Target4       // RT4: shadowmask (rgba)
#endif
)
{
    #if (SHADER_TARGET < 30)
        outGBuffer0 = 1;
        outGBuffer1 = 1;
        outGBuffer2 = 0;
        outEmission = 0;
        #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
            outShadowMask = 1;
        #endif
        return;
    #endif

    FRAGMENT_SETUP(s)

    // no analytic lights in this pass
    UnityLight dummyLight = DummyLight ();
    half atten = 1;

    // only GI
    half occlusion = Occlusion(i.tex.xy);
#if UNITY_ENABLE_REFLECTION_BUFFERS
    bool sampleReflectionsInDeferred = false;
#else
    bool sampleReflectionsInDeferred = true;
#endif

    UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, dummyLight, sampleReflectionsInDeferred);

    half3 emissiveColor = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect).rgb;

    #ifdef _EMISSION
        emissiveColor += Emission (i.tex.xy);
    #endif

    #ifndef UNITY_HDR_ON
        emissiveColor.rgb = exp2(-emissiveColor.rgb);
    #endif

    UnityStandardData data;
    data.diffuseColor   = s.diffColor;
    data.occlusion      = occlusion;
    data.specularColor  = s.specColor;
    data.smoothness     = s.smoothness;
    data.normalWorld    = s.normalWorld;

    UnityStandardDataToGbuffer(data, outGBuffer0, outGBuffer1, outGBuffer2);

    // Emissive lighting buffer
    outEmission = half4(emissiveColor, 1);

    // Baked direct lighting occlusion if any
    #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
        outShadowMask = UnityGetRawBakedOcclusions(i.ambientOrLightmapUV.xy, IN_WORLDPOS(i));
    #endif
}


//
// Old FragmentGI signature. Kept only for backward compatibility and will be removed soon
//

inline UnityGI FragmentGI(
    float3 posWorld,
    half occlusion, half4 i_ambientOrLightmapUV, half atten, half smoothness, half3 normalWorld, half3 eyeVec,
    UnityLight light,
    bool reflections)
{
    // we init only fields actually used
    FragmentCommonData s = (FragmentCommonData)0;
    s.smoothness = smoothness;
    s.normalWorld = normalWorld;
    s.eyeVec = eyeVec;
    s.posWorld = posWorld;
    return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, reflections);
}
inline UnityGI FragmentGI (
    float3 posWorld,
    half occlusion, half4 i_ambientOrLightmapUV, half atten, half smoothness, half3 normalWorld, half3 eyeVec,
    UnityLight light)
{
    return FragmentGI (posWorld, occlusion, i_ambientOrLightmapUV, atten, smoothness, normalWorld, eyeVec, light, true);
}

#endif // UNITY_STANDARD_CORE_INCLUDED
