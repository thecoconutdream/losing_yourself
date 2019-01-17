// This is an extension of a Unity built-in shader source.
//
// Everywhere except the regions noted by "Standard Plus Code" is under
// Copyright (c) 2016 Unity Technologies. MIT license (see license.txt).
//
// Standard Plus code by Paulo Cunha.


using System;
using UnityEngine;
using UnityEditor;

public class StandardPlusGUI : ShaderGUI {

	private enum WorkflowMode
	{
		Specular,
		Metallic,
		Dielectric
	}

	public enum BlendMode
	{
		Opaque,
		Cutout,
		Fade,
		Transparent
	}

	public enum SmoothnessMapChannel
	{
		SpecularMetallicAlpha,
		AlbedoAlpha,
	}

	private static class Styles
	{
		public static GUIContent uvSetLabel = new GUIContent("UV Set");

		public static GUIContent albedoText = new GUIContent("Albedo", "Albedo (RGB) and Transparency (A)");
		public static GUIContent alphaCutoffText = new GUIContent("Alpha Cutoff", "Threshold for alpha cutoff");
		public static GUIContent specularMapText = new GUIContent("Specular", "Specular (RGB) and Smoothness (A)");
		public static GUIContent metallicMapText = new GUIContent("Metallic", "Metallic (R) and Smoothness (A)");
		public static GUIContent smoothnessText = new GUIContent("Smoothness", "Smoothness value");
		public static GUIContent smoothnessScaleText = new GUIContent("Smoothness", "Smoothness scale factor");
		public static GUIContent smoothnessMapChannelText = new GUIContent("Source", "Smoothness texture and channel");
		public static GUIContent highlightsText = new GUIContent("Specular Highlights", "Specular Highlights");
		public static GUIContent reflectionsText = new GUIContent("Reflections", "Glossy Reflections");
		public static GUIContent normalMapText = new GUIContent("Normal Map", "Normal Map");
		public static GUIContent heightMapText = new GUIContent("Height Map", "Height Map (G)");
		public static GUIContent occlusionText = new GUIContent("Occlusion", "Occlusion (G)");
		public static GUIContent emissionText = new GUIContent("Color", "Emission (RGB)");
		public static GUIContent detailMaskText = new GUIContent("Detail Mask", "Mask for Secondary Maps (A)");
		public static GUIContent detailAlbedoText = new GUIContent("Detail Albedo x2", "Albedo (RGB) multiplied by 2");
		public static GUIContent detailNormalMapText = new GUIContent("Normal Map", "Normal Map");

		public static string primaryMapsText = "Main Maps";
		public static string secondaryMapsText = "Secondary Maps";
		public static string forwardText = "Forward Rendering Options";
		public static string renderingMode = "Rendering Mode";
		public static string advancedText = "Advanced Options";
		public static GUIContent emissiveWarning = new GUIContent("Emissive value is animated but the material has not been configured to support emissive. Please make sure the material itself has some amount of emissive.");
		public static readonly string[] blendNames = Enum.GetNames(typeof(BlendMode));


		//Standard Plus Code
		public static GUIContent useCustomText = new GUIContent ("Custom Lightmaps", "");
		public static GUIContent customLightmapMapText = new GUIContent("Lightmap 01", "Lightmap Texture (RGB) Uses Second UV Channel");
		public static GUIContent customLightmapMapText2 = new GUIContent("Lightmap 02", "Lightmap Texture (RGB) Uses Second UV Channel");
		public static GUIContent customLightmapMapText3 = new GUIContent("Lightmap 03", "Lightmap Texture (RGB) Uses Second UV Channel");
		public static GUIContent customLightmapMapText4 = new GUIContent("Lightmap 04", "Lightmap Texture (RGB) Uses Second UV Channel");
		public static GUIContent customLightmapMapText5 = new GUIContent("Lightmap 05", "Lightmap Texture (RGB) Uses Second UV Channel");

		public static GUIContent translucencyText = new GUIContent ("Translucency", "");
		public static GUIContent backFaceText = new GUIContent ("Show Back Faces", "");
		public static GUIContent thicknessMapText = new GUIContent ("Thickness Map", "");

		public static GUIContent distortionText = new GUIContent ("Distortion", "");
		public static GUIContent powerText = new GUIContent ("Power", "");
		public static GUIContent scaleText = new GUIContent ("Scale", "");
		public static GUIContent ambientText = new GUIContent ("Ambient", "");

		public static GUIContent adjustLevelsText = new GUIContent ("Adjust Levels", "");
		public static GUIContent inMinText = new GUIContent ("IN Min", "");
		public static GUIContent inMiddleText = new GUIContent ("IN Middle", "");
		public static GUIContent inMaxText = new GUIContent ("IN Max", "");
		public static GUIContent outMinText = new GUIContent ("OUT Min", "");
		public static GUIContent outMaxText = new GUIContent ("OUT Max", "");

		public static string plusLightText = "Plus Lightmaps";
		public static string plusTransText = "Plus Translucency";
		public static string customLightmapText = "Custom Lightmaps";
		//End of Standard Plus Code
	}

	MaterialProperty blendMode = null;
	MaterialProperty albedoMap = null;
	MaterialProperty albedoColor = null;
	MaterialProperty alphaCutoff = null;
	MaterialProperty specularMap = null;
	MaterialProperty specularColor = null;
	MaterialProperty metallicMap = null;
	MaterialProperty metallic = null;
	MaterialProperty smoothness = null;
	MaterialProperty smoothnessScale = null;
	MaterialProperty smoothnessMapChannel = null;
	MaterialProperty highlights = null;
	MaterialProperty reflections = null;
	MaterialProperty bumpScale = null;
	MaterialProperty bumpMap = null;
	MaterialProperty occlusionStrength = null;
	MaterialProperty occlusionMap = null;
	MaterialProperty heigtMapScale = null;
	MaterialProperty heightMap = null;
	MaterialProperty emissionColorForRendering = null;
	MaterialProperty emissionMap = null;
	MaterialProperty detailMask = null;
	MaterialProperty detailAlbedoMap = null;
	MaterialProperty detailNormalMapScale = null;
	MaterialProperty detailNormalMap = null;
	MaterialProperty uvSetSecondary = null;

	//Standard Plus Code
	MaterialProperty lightMapTex = null;
	MaterialProperty lightMapTex2 = null;
	MaterialProperty lightMapTex3 = null;
	MaterialProperty lightMapTex4 = null;
	MaterialProperty lightMapTex5 = null;
	MaterialProperty lightmapTint = null;
	MaterialProperty lightmapTint2 = null;
	MaterialProperty lightmapTint3 = null;
	MaterialProperty lightmapTint4 = null;
	MaterialProperty lightmapTint5 = null;
	MaterialProperty translucencyColor = null;
	MaterialProperty thicknessMap = null;
	MaterialProperty distortion = null;
	MaterialProperty power = null;
	MaterialProperty scale = null;
	MaterialProperty ambient = null;
	MaterialProperty inMin = null;
	MaterialProperty inMiddle = null;
	MaterialProperty inMax = null;
	MaterialProperty outMin = null;
	MaterialProperty outMax = null;
	//End of Standard Plus Code

	MaterialEditor m_MaterialEditor;
	WorkflowMode m_WorkflowMode = WorkflowMode.Specular;
	ColorPickerHDRConfig m_ColorPickerHDRConfig = new ColorPickerHDRConfig(0f, 99f, 1 / 99f, 3f);

	bool m_FirstTimeApply = true;

	//Standard Plus Code
	bool useCustomLightMap = false;
	bool translucencyOn = false;
	bool disableCull = false;
	bool adjustLevels = false;
	public static Texture2D iconLogo;
	//End of Standard Plus Code

	public void FindProperties(MaterialProperty[] props)
	{
		blendMode = FindProperty("_Mode", props);
		albedoMap = FindProperty("_MainTex", props);
		albedoColor = FindProperty("_Color", props);
		alphaCutoff = FindProperty("_Cutoff", props);
		specularMap = FindProperty("_SpecGlossMap", props, false);
		specularColor = FindProperty("_SpecColor", props, false);
		metallicMap = FindProperty("_MetallicGlossMap", props, false);
		metallic = FindProperty("_Metallic", props, false);
		if (specularMap != null && specularColor != null)
			m_WorkflowMode = WorkflowMode.Specular;
		else if (metallicMap != null && metallic != null)
			m_WorkflowMode = WorkflowMode.Metallic;
		else
			m_WorkflowMode = WorkflowMode.Dielectric;
		smoothness = FindProperty("_Glossiness", props);
		smoothnessScale = FindProperty("_GlossMapScale", props, false);
		smoothnessMapChannel = FindProperty("_SmoothnessTextureChannel", props, false);
		highlights = FindProperty("_SpecularHighlights", props, false);
		reflections = FindProperty("_GlossyReflections", props, false);
		bumpScale = FindProperty("_BumpScale", props);
		bumpMap = FindProperty("_BumpMap", props);
		heigtMapScale = FindProperty("_Parallax", props);
		heightMap = FindProperty("_ParallaxMap", props);
		occlusionStrength = FindProperty("_OcclusionStrength", props);
		occlusionMap = FindProperty("_OcclusionMap", props);
		emissionColorForRendering = FindProperty("_EmissionColor", props);
		emissionMap = FindProperty("_EmissionMap", props);
		detailMask = FindProperty("_DetailMask", props);
		detailAlbedoMap = FindProperty("_DetailAlbedoMap", props);
		detailNormalMapScale = FindProperty("_DetailNormalMapScale", props);
		detailNormalMap = FindProperty("_DetailNormalMap", props);
		uvSetSecondary = FindProperty("_UVSec", props);

		//Standard Plus Code
		lightMapTex = FindProperty ("_CustomLightmap", props);
		lightMapTex2 = FindProperty ("_CustomLightmap2", props);
		lightMapTex3 = FindProperty ("_CustomLightmap3", props);
		lightMapTex4 = FindProperty ("_CustomLightmap4", props);
		lightMapTex5 = FindProperty ("_CustomLightmap5", props);
		lightmapTint = FindProperty ("_LightmapTint", props);
		lightmapTint2 = FindProperty ("_LightmapTint2", props);
		lightmapTint3 = FindProperty ("_LightmapTint3", props);
		lightmapTint4 = FindProperty ("_LightmapTint4", props);
		lightmapTint5 = FindProperty ("_LightmapTint5", props);
		translucencyColor = FindProperty ("_TranslucencyColor", props);
		thicknessMap = FindProperty ("_ThicknessMap", props);
		distortion = FindProperty ("_Distortion", props);
		power = FindProperty ("_Power", props);
		scale = FindProperty ("_Scale", props);
		ambient = FindProperty ("_Ambient", props);
		inMin = FindProperty ("_INMin", props);
		inMiddle = FindProperty ("_INMiddle", props);
		inMax = FindProperty ("_INMax", props);
		outMin = FindProperty ("_OUTMin", props);
		outMax = FindProperty ("_OUTMax", props);
		//End of Standard Plus Code
	}

	public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
	{
		//StandardPlusCode
		if (iconLogo == null) {
			string[] icons = AssetDatabase.FindAssets("plusLogo t:Texture2D", null);
			if (icons.Length>0) {
				iconLogo = AssetDatabase.LoadAssetAtPath<Texture2D>(AssetDatabase.GUIDToAssetPath(icons[0]));
			}
		}
		//End of StandardPlusCode

		FindProperties(props); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly
		m_MaterialEditor = materialEditor;
		Material material = materialEditor.target as Material;

		// Make sure that needed setup (ie keywords/renderqueue) are set up if we're switching some existing
		// material to a standard shader.
		// Do this before any GUI code has been issued to prevent layout issues in subsequent GUILayout statements (case 780071)
		if (m_FirstTimeApply)
		{
			MaterialChanged(material, m_WorkflowMode);
			m_FirstTimeApply = false;
		}

		ShaderPropertiesGUI(material);
	}

	public void ShaderPropertiesGUI(Material material)
	{
		// Use default labelWidth
		EditorGUIUtility.labelWidth = 0f;

		// Detect any changes to the material
		EditorGUI.BeginChangeCheck();
		{
			GUILayout.Label(iconLogo);

			BlendModePopup();

			// Primary properties
			GUILayout.Label(Styles.primaryMapsText, EditorStyles.boldLabel);
			DoAlbedoArea(material);
			DoSpecularMetallicArea();
			m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, bumpMap, bumpMap.textureValue != null ? bumpScale : null);
			m_MaterialEditor.TexturePropertySingleLine(Styles.heightMapText, heightMap, heightMap.textureValue != null ? heigtMapScale : null);
			m_MaterialEditor.TexturePropertySingleLine(Styles.occlusionText, occlusionMap, occlusionMap.textureValue != null ? occlusionStrength : null);
			m_MaterialEditor.TexturePropertySingleLine(Styles.detailMaskText, detailMask);
			DoEmissionArea(material);
			EditorGUI.BeginChangeCheck();
			m_MaterialEditor.TextureScaleOffsetProperty(albedoMap);
			if (EditorGUI.EndChangeCheck())
				emissionMap.textureScaleAndOffset = albedoMap.textureScaleAndOffset; // Apply the main texture scale and offset to the emission texture as well, for Enlighten's sake

			EditorGUILayout.Space();

			// Secondary properties
			GUILayout.Label(Styles.secondaryMapsText, EditorStyles.boldLabel);
			m_MaterialEditor.TexturePropertySingleLine(Styles.detailAlbedoText, detailAlbedoMap);
			m_MaterialEditor.TexturePropertySingleLine(Styles.detailNormalMapText, detailNormalMap, detailNormalMapScale);
			m_MaterialEditor.TextureScaleOffsetProperty(detailAlbedoMap);   

			m_MaterialEditor.ShaderProperty(uvSetSecondary, Styles.uvSetLabel.text);

			//Standard Plus Code
			EditorGUILayout.Space();
			GUILayout.Label(Styles.plusLightText, EditorStyles.boldLabel);
			DoCustomLightmapArea();
			EditorGUILayout.Space();
			GUILayout.Label(Styles.plusTransText, EditorStyles.boldLabel);
			DoTranslucencyArea ();
			EditorGUILayout.Space();
			//End of Standard Plus Code

			// Third properties
			GUILayout.Label(Styles.forwardText, EditorStyles.boldLabel);
			if (highlights != null)
				m_MaterialEditor.ShaderProperty(highlights, Styles.highlightsText);
			if (reflections != null)
				m_MaterialEditor.ShaderProperty(reflections, Styles.reflectionsText);
		}
		if (EditorGUI.EndChangeCheck())
		{
			foreach (var obj in blendMode.targets)
				MaterialChanged((Material)obj, m_WorkflowMode);
		}

		EditorGUILayout.Space();

		GUILayout.Label(Styles.advancedText, EditorStyles.boldLabel);
		m_MaterialEditor.RenderQueueField();
		m_MaterialEditor.EnableInstancingField();
	}

	internal void DetermineWorkflow(MaterialProperty[] props)
	{
		if (FindProperty("_SpecGlossMap", props, false) != null && FindProperty("_SpecColor", props, false) != null)
			m_WorkflowMode = WorkflowMode.Specular;
		else if (FindProperty("_MetallicGlossMap", props, false) != null && FindProperty("_Metallic", props, false) != null)
			m_WorkflowMode = WorkflowMode.Metallic;
		else
			m_WorkflowMode = WorkflowMode.Dielectric;
	}

	public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
	{
		// _Emission property is lost after assigning Standard shader to the material
		// thus transfer it before assigning the new shader
		if (material.HasProperty("_Emission"))
		{
			material.SetColor("_EmissionColor", material.GetColor("_Emission"));
		}

		base.AssignNewShaderToMaterial(material, oldShader, newShader);

//		if (oldShader == null || !oldShader.name.Contains("Legacy Shaders/"))
//		{
//			SetupMaterialWithBlendMode(material, (BlendMode)material.GetFloat("_Mode"));
//			return;
//		}

		BlendMode blendMode = BlendMode.Opaque;
		if (oldShader.name.Contains("/Transparent/Cutout/"))
		{
			blendMode = BlendMode.Cutout;
		}
		else if (oldShader.name.Contains("/Transparent/"))
		{
			// NOTE: legacy shaders did not provide physically based transparency
			// therefore Fade mode
			blendMode = BlendMode.Fade;
		}
		material.SetFloat("_Mode", (float)blendMode);

		DetermineWorkflow(MaterialEditor.GetMaterialProperties(new Material[] { material }));
		MaterialChanged(material, m_WorkflowMode);
	}

	void BlendModePopup()
	{
		EditorGUI.showMixedValue = blendMode.hasMixedValue;
		var mode = (BlendMode)blendMode.floatValue;

		EditorGUI.BeginChangeCheck();
		mode = (BlendMode)EditorGUILayout.Popup(Styles.renderingMode, (int)mode, Styles.blendNames);
		if (EditorGUI.EndChangeCheck())
		{
			m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
			blendMode.floatValue = (float)mode;
		}

		EditorGUI.showMixedValue = false;
	}

	void DoAlbedoArea(Material material)
	{
		m_MaterialEditor.TexturePropertySingleLine(Styles.albedoText, albedoMap, albedoColor);


		if (((BlendMode)material.GetFloat("_Mode") == BlendMode.Cutout))
		{
			m_MaterialEditor.ShaderProperty(alphaCutoff, Styles.alphaCutoffText.text, MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);
		}
	}

	void DoEmissionArea(Material material)
	{
		// Emission for GI?
		if (m_MaterialEditor.EmissionEnabledProperty())
		{
			bool hadEmissionTexture = emissionMap.textureValue != null;

			// Texture and HDR color controls
			m_MaterialEditor.TexturePropertyWithHDRColor(Styles.emissionText, emissionMap, emissionColorForRendering, m_ColorPickerHDRConfig, false);

			// If texture was assigned and color was black set color to white
			float brightness = emissionColorForRendering.colorValue.maxColorComponent;
			if (emissionMap.textureValue != null && !hadEmissionTexture && brightness <= 0f)
				emissionColorForRendering.colorValue = Color.white;

			// change the GI flag and fix it up with emissive as black if necessary
			m_MaterialEditor.LightmapEmissionFlagsProperty(MaterialEditor.kMiniTextureFieldLabelIndentLevel, true);
		}
	}

	void DoSpecularMetallicArea()
	{
		bool hasGlossMap = false;
		if (m_WorkflowMode == WorkflowMode.Specular)
		{
			hasGlossMap = specularMap.textureValue != null;
			m_MaterialEditor.TexturePropertySingleLine(Styles.specularMapText, specularMap, hasGlossMap ? null : specularColor);
		}
		else if (m_WorkflowMode == WorkflowMode.Metallic)
		{
			hasGlossMap = metallicMap.textureValue != null;
			m_MaterialEditor.TexturePropertySingleLine(Styles.metallicMapText, metallicMap, hasGlossMap ? null : metallic);
		}

		bool showSmoothnessScale = hasGlossMap;
		if (smoothnessMapChannel != null)
		{
			int smoothnessChannel = (int)smoothnessMapChannel.floatValue;
			if (smoothnessChannel == (int)SmoothnessMapChannel.AlbedoAlpha)
				showSmoothnessScale = true;
		}

		int indentation = 2; // align with labels of texture properties
		m_MaterialEditor.ShaderProperty(showSmoothnessScale ? smoothnessScale : smoothness, showSmoothnessScale ? Styles.smoothnessScaleText : Styles.smoothnessText, indentation);

		++indentation;
		if (smoothnessMapChannel != null)
			m_MaterialEditor.ShaderProperty(smoothnessMapChannel, Styles.smoothnessMapChannelText, indentation);
	}

	//Standard Plus Code
	void DoCustomLightmapArea(){

		EditorGUI.BeginChangeCheck();
		useCustomLightMap = EditorGUILayout.Toggle(Styles.useCustomText,
			IsKeywordEnabled(m_MaterialEditor.target as Material, "_CUSTOM_LIGHTMAP"));
		if (EditorGUI.EndChangeCheck()) {
			SetKeyword("_CUSTOM_LIGHTMAP", useCustomLightMap);
			SetKeyword("_CUSTOM_LIGHTMAP2", useCustomLightMap);
			SetKeyword("_CUSTOM_LIGHTMAP3", useCustomLightMap);
			SetKeyword("_CUSTOM_LIGHTMAP4", useCustomLightMap);
			SetKeyword("_CUSTOM_LIGHTMAP5", useCustomLightMap);
		}

		if(useCustomLightMap){
			m_MaterialEditor.TexturePropertyWithHDRColor(Styles.customLightmapMapText, lightMapTex, lightmapTint, m_ColorPickerHDRConfig, false);
			m_MaterialEditor.TexturePropertyWithHDRColor(Styles.customLightmapMapText2, lightMapTex2, lightmapTint2, m_ColorPickerHDRConfig, false);
			m_MaterialEditor.TexturePropertyWithHDRColor(Styles.customLightmapMapText3, lightMapTex3, lightmapTint3, m_ColorPickerHDRConfig, false);
			m_MaterialEditor.TexturePropertyWithHDRColor(Styles.customLightmapMapText4, lightMapTex4, lightmapTint4, m_ColorPickerHDRConfig, false);
			m_MaterialEditor.TexturePropertyWithHDRColor(Styles.customLightmapMapText5, lightMapTex5, lightmapTint5, m_ColorPickerHDRConfig, false);
		}

		EditorGUI.BeginChangeCheck();
		disableCull = EditorGUILayout.Toggle(Styles.backFaceText, IsCullEnabled(m_MaterialEditor.target as Material));

		if (EditorGUI.EndChangeCheck()) {			
			Material mat = m_MaterialEditor.target as Material;
			if(disableCull == true){				
				mat.SetInt("_CullMode", 0);
			}else{
				mat.SetInt("_CullMode", 2);
			}
		}
	}

	void DoTranslucencyArea(){

		EditorGUI.BeginChangeCheck();
		translucencyOn = EditorGUILayout.Toggle(Styles.translucencyText,
			IsKeywordEnabled(m_MaterialEditor.target as Material, "_TRANSLUCENCY"));
		if (EditorGUI.EndChangeCheck()) {
			SetKeyword("_TRANSLUCENCY", translucencyOn);
		}

		if(translucencyOn){

			m_MaterialEditor.TexturePropertySingleLine(Styles.thicknessMapText, thicknessMap, translucencyColor);

			EditorGUI.BeginChangeCheck();
			adjustLevels = EditorGUILayout.Toggle(Styles.adjustLevelsText,
				IsKeywordEnabled(m_MaterialEditor.target as Material, "_LEVELS"));
			if (EditorGUI.EndChangeCheck()) {
				SetKeyword("_LEVELS", adjustLevels);
			}

			if(adjustLevels){
				EditorGUI.indentLevel += 2;
				m_MaterialEditor.ShaderProperty (inMin, Styles.inMinText);
				m_MaterialEditor.ShaderProperty (inMiddle, Styles.inMiddleText);
				m_MaterialEditor.ShaderProperty (inMax, Styles.inMaxText);
				m_MaterialEditor.ShaderProperty (outMin, Styles.outMinText);
				m_MaterialEditor.ShaderProperty (outMax, Styles.outMaxText);
				EditorGUILayout.Space();
				EditorGUI.indentLevel -= 2;
			}

			m_MaterialEditor.ShaderProperty (distortion, Styles.distortionText);
			m_MaterialEditor.ShaderProperty (power, Styles.powerText);
			m_MaterialEditor.ShaderProperty (scale, Styles.scaleText);
			m_MaterialEditor.ShaderProperty (ambient, Styles.ambientText);
		}
	}

	bool IsCullEnabled (Material target) {
		if(target.GetInt("_CullMode") == 2){
			return false;
		}else if(target.GetInt("_CullMode") == 0){
			return true;
		}else{
			return false; 
		}
	}
	//End of Standard Plus Code



	public static void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
	{
		switch (blendMode)
		{
		case BlendMode.Opaque:
			material.SetOverrideTag("RenderType", "");
			material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
			material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
			material.SetInt("_ZWrite", 1);
			material.DisableKeyword("_ALPHATEST_ON");
			material.DisableKeyword("_ALPHABLEND_ON");
			material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
			material.renderQueue = -1;
			break;
		case BlendMode.Cutout:
			material.SetOverrideTag("RenderType", "TransparentCutout");
			material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
			material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
			material.SetInt("_ZWrite", 1);
			material.EnableKeyword("_ALPHATEST_ON");
			material.DisableKeyword("_ALPHABLEND_ON");
			material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
			material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
			break;
		case BlendMode.Fade:
			material.SetOverrideTag("RenderType", "Transparent");
			material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
			material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
			material.SetInt("_ZWrite", 0);
			material.DisableKeyword("_ALPHATEST_ON");
			material.EnableKeyword("_ALPHABLEND_ON");
			material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
			material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
			break;
		case BlendMode.Transparent:
			material.SetOverrideTag("RenderType", "Transparent");
			material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
			material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
			material.SetInt("_ZWrite", 0);
			material.DisableKeyword("_ALPHATEST_ON");
			material.DisableKeyword("_ALPHABLEND_ON");
			material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
			material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
			break;
		}
	}

	static SmoothnessMapChannel GetSmoothnessMapChannel(Material material)
	{
		int ch = (int)material.GetFloat("_SmoothnessTextureChannel");
		if (ch == (int)SmoothnessMapChannel.AlbedoAlpha)
			return SmoothnessMapChannel.AlbedoAlpha;
		else
			return SmoothnessMapChannel.SpecularMetallicAlpha;
	}

	static void SetMaterialKeywords(Material material, WorkflowMode workflowMode)
	{
		// Note: keywords must be based on Material value not on MaterialProperty due to multi-edit & material animation
		// (MaterialProperty value might come from renderer material property block)
		SetKeyword(material, "_NORMALMAP", material.GetTexture("_BumpMap") || material.GetTexture("_DetailNormalMap"));
		if (workflowMode == WorkflowMode.Specular)
			SetKeyword(material, "_SPECGLOSSMAP", material.GetTexture("_SpecGlossMap"));
		else if (workflowMode == WorkflowMode.Metallic)
			SetKeyword(material, "_METALLICGLOSSMAP", material.GetTexture("_MetallicGlossMap"));
		SetKeyword(material, "_PARALLAXMAP", material.GetTexture("_ParallaxMap"));
		SetKeyword(material, "_DETAIL_MULX2", material.GetTexture("_DetailAlbedoMap") || material.GetTexture("_DetailNormalMap"));

		// A material's GI flag internally keeps track of whether emission is enabled at all, it's enabled but has no effect
		// or is enabled and may be modified at runtime. This state depends on the values of the current flag and emissive color.
		// The fixup routine makes sure that the material is in the correct state if/when changes are made to the mode or color.
		MaterialEditor.FixupEmissiveFlag(material);
		bool shouldEmissionBeEnabled = (material.globalIlluminationFlags & MaterialGlobalIlluminationFlags.EmissiveIsBlack) == 0;
		SetKeyword(material, "_EMISSION", shouldEmissionBeEnabled);

		if (material.HasProperty("_SmoothnessTextureChannel"))
		{
			SetKeyword(material, "_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A", GetSmoothnessMapChannel(material) == SmoothnessMapChannel.AlbedoAlpha);
		}
	}

	static void MaterialChanged(Material material, WorkflowMode workflowMode)
	{
		SetupMaterialWithBlendMode(material, (BlendMode)material.GetFloat("_Mode"));

		SetMaterialKeywords(material, workflowMode);
	}

	bool IsKeywordEnabled (Material target, string keyword) {
		return target.IsKeywordEnabled(keyword);
	}

	void SetKeyword (string keyword, bool state) {
		if (state) {
			foreach (Material m in m_MaterialEditor.targets) {
				m.EnableKeyword(keyword);
			}
		}
		else {
			foreach (Material m in m_MaterialEditor.targets) {
				m.DisableKeyword(keyword);
			}
		}
	}

	static void SetKeyword(Material m, string keyword, bool state)
	{
		if (state)
			m.EnableKeyword(keyword);
		else
			m.DisableKeyword(keyword);
	}
}
