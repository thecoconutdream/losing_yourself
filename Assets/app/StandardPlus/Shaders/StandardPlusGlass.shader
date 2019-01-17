// This is an extension of a Unity built-in shader source.
//
// Everywhere except the regions noted by "Standard Plus Code" is under
// Copyright (c) 2016 Unity Technologies. MIT license (see license.txt).
//
// Standard Plus code by Paulo Cunha.

Shader "Standard Plus/Standard Plus Glass"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,0)
		_MainTex("Albedo", 2D) = "white" {}
		
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		[Enum(Metallic Alpha,0,Albedo Alpha,1)] _SmoothnessTextureChannel ("Smoothness texture channel", Float) = 0

		[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}

		[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[ToggleOff] _GlossyReflections("Glossy Reflections", Float) = 1.0

		_BumpScale("Scale", Float) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}

		_Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
		_ParallaxMap ("Height Map", 2D) = "black" {}

		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionMap("Occlusion", 2D) = "white" {}

		_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}
		
		_DetailMask("Detail Mask", 2D) = "white" {}

		_DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
		_DetailNormalMapScale("Scale", Float) = 1.0
		_DetailNormalMap("Normal Map", 2D) = "bump" {}

		[Enum(UV0,0,UV1,1)] _UVSec ("UV Set for secondary textures", Float) = 0

		//Standard Plus Code
		_CustomLightmap("Custom Lightmap", 2D) = "white" {}
		_CustomLightmap2("Custom Lightmap2", 2D) = "white" {}
		_CustomLightmap3("Custom Lightmap3", 2D) = "white" {}
		_CustomLightmap4("Custom Lightmap4", 2D) = "white" {}
		_CustomLightmap5("Custom Lightmap5", 2D) = "white" {}

		_LightmapTint("Lightmap Tint", Color) = (0,0,0,1)
		_LightmapTint2("Lightmap Tint2", Color) = (0,0,0,1)
		_LightmapTint3("Lightmap Tint3", Color) = (0,0,0,1)
		_LightmapTint4("Lightmap Tint4", Color) = (0,0,0,1)
		_LightmapTint5("Lightmap Tint5", Color) = (0,0,0,1)

		_ThicknessMap("Thickness Map", 2D) = "white" {}

		[ToggleOff] _AffectsRefraction("Map Affects Refraction", Float) = 1.0
		[ToggleOff] _AffectsColor("Map Affects Color", Float) = 1.0

		_RefractionAmount("Refraction Amount", Range(-20, 20)) = 1

		_INMin("IN Min", Range(0, 1)) = 0
		_INMiddle("IN Middle", Range(0, 2)) = 1
		_INMax("IN Max", Range(0, 1)) = 1
		_OUTMin("IN Min", Range(0, 1)) = 0
		_OUTMax("IN Min", Range(0, 1)) = 1

		_INMinCOLOR("IN Min COLOR", Range(0, 1)) = 0
		_INMiddleCOLOR("IN Middle COLOR", Range(0, 2)) = 1
		_INMaxCOLOR("IN Max COLOR", Range(0, 1)) = 1
		_OUTMinCOLOR("IN Min COLOR", Range(0, 1)) = 0
		_OUTMaxCOLOR("IN Min COLOR", Range(0, 1)) = 1

		_SizeBlur("Blur Amount", Range(0, 10)) = 0

		_FresnelAmount("FresnelAmount", Range(-10, 10)) = 1
		_FresnelLength("FresnelLength", Range(0.5, 15)) = 4

		_uvLmZ("", Float) = 0
		_uvLmW("", Float) = 0
		_uvLmX("", Float) = 1
		_uvLmY("", Float) = 1
		//End of Standard Plus Code

		//Cull mode
		[HideInInspector]  _CullMode("mode", Float) = 2

		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("__src", Float) = 1.0
		[HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[HideInInspector] _ZWrite ("__zw", Float) = 1.0
	}

	CGINCLUDE
		#define UNITY_SETUP_BRDF_INPUT MetallicSetup
	ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
		LOD 300

		Cull [_CullMode]

		GrabPass{"_BackgroundTex"}	

		// ------------------------------------------------------------------
		//  Base forward pass (directional light, emission, lightmaps, ...)
		Pass
		{
			Name "FORWARD" 
			Tags { "LightMode" = "ForwardBase" }

			Blend [_SrcBlend] [_DstBlend]
			//ZWrite Off
			ZWrite [_ZWrite]

			CGPROGRAM
			#pragma target 3.0

			// -------------------------------------

			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF
			#pragma shader_feature _PARALLAXMAP

			//Standard Plus Code
			#pragma shader_feature _CUSTOM_LIGHTMAP
			#pragma shader_feature _CUSTOM_LIGHTMAP2
			#pragma shader_feature _CUSTOM_LIGHTMAP3
			#pragma shader_feature _CUSTOM_LIGHTMAP4
			#pragma shader_feature _CUSTOM_LIGHTMAP5
			#pragma shader_feature _ _AFFECTSREFRACTION_OFF
			#pragma shader_feature _ _AFFECTSCOLOR_OFF
			#pragma shader_feature _REFRACTION
			#pragma shader_feature _COLORLEVELS
			#pragma shader_feature _REFRACTIONLEVELS
			#pragma shader_feature _BLUR_ON
			//End of Standard Plus Code

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			#pragma vertex vertBase
			#pragma fragment fragBase

			#include "./Includes/StandardPlusStandardCoreForward.cginc" //Standard Plus Code

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Additive forward pass (one light per pass)
		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend [_SrcBlend] One
			Fog { Color (0,0,0,0) } // in additive pass fog should be black
			ZWrite Off
			ZTest LEqual

			CGPROGRAM
			#pragma target 3.0

			// -------------------------------------


			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _PARALLAXMAP

			//Standard Plus Code
			#pragma shader_feature _CUSTOM_LIGHTMAP
			#pragma shader_feature _CUSTOM_LIGHTMAP2
			#pragma shader_feature _CUSTOM_LIGHTMAP3
			#pragma shader_feature _CUSTOM_LIGHTMAP4
			#pragma shader_feature _CUSTOM_LIGHTMAP5
			#pragma shader_feature _REFRACTION
			#pragma shader_feature _COLORLEVELS
			#pragma shader_feature _REFRACTIONLEVELS
			//End of Standard Plus Code

			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			#pragma vertex vertAdd
			#pragma fragment fragAdd

			#include "./Includes/StandardPlusStandardCoreForward.cginc" //Standard Plus Code

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Shadow rendering pass
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual

			CGPROGRAM
			#pragma target 3.0

			// -------------------------------------


			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _PARALLAXMAP
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

			#include "./Includes/StandardPlusShadow.cginc" //Standard Plus Code

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Deferred pass
		Pass
		{
			Name "DEFERRED"
			Tags { "LightMode" = "Deferred" }

			CGPROGRAM
			#pragma target 3.0
			#pragma exclude_renderers nomrt


			// -------------------------------------

			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _PARALLAXMAP

			//Standard Plus Code
			#pragma shader_feature _CUSTOM_LIGHTMAP
			#pragma shader_feature _CUSTOM_LIGHTMAP2
			#pragma shader_feature _CUSTOM_LIGHTMAP3
			#pragma shader_feature _CUSTOM_LIGHTMAP4
			#pragma shader_feature _CUSTOM_LIGHTMAP5
			#pragma shader_feature _REFRACTION
			#pragma shader_feature _ _AFFECTSREFRACTION_OFF
			#pragma shader_feature _ _AFFECTSCOLOR_OFF
			#pragma shader_feature _COLORLEVELS
			#pragma shader_feature _REFRACTIONLEVELS
			#pragma shader_feature _BLUR_ON
			//End of Standard Plus Code

			#pragma multi_compile_prepassfinal
			#pragma multi_compile_instancing

			#pragma vertex vertDeferred
			#pragma fragment fragDeferred

			#include "./Includes/StandardPlusStandardCore.cginc" //Standard Plus Code

			ENDCG
		}

		// ------------------------------------------------------------------
		// Extracts information for lightmapping, GI (emission, albedo, ...)
		// This pass it not used during regular rendering.
		Pass
		{
			Name "META" 
			Tags { "LightMode"="Meta" }

			Cull Off

			CGPROGRAM
			#pragma vertex vert_meta
			#pragma fragment frag_meta

			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature EDITOR_VISUALIZATION

			#include "UnityStandardMeta.cginc"
			ENDCG
		}
	}


	FallBack "VertexLit"

	CustomEditor "StandardPlusGlassGUI" //Standard Plus Code
}
