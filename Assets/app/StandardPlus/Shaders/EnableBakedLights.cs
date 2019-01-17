using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class EnableBakedLights : MonoBehaviour {

	[HideInInspector]
	public static int singleIndex = 0;
	public static int startSingleIndex = 0;

	Renderer render;
	Material mat;
	bool onlyObject = true;

	void OnEnable(){

		EnableBakedLights.singleIndex++;

		if(EnableBakedLights.singleIndex > 2){
			onlyObject = false;
		}

		render = transform.GetComponent<Renderer> ();
		mat = render.sharedMaterial;

		mat.SetFloat ("_uvLmX", 1);
		mat.SetFloat ("_uvLmY", 1);
		mat.SetFloat ("_uvLmZ", 0);
		mat.SetFloat ("_uvLmW", 0);
	}

	void Start(){

		EnableBakedLights.startSingleIndex++;

		if(EnableBakedLights.startSingleIndex > 1){
			onlyObject = false;
		}

		if(render.lightmapIndex != 65535 && !onlyObject){
			mat.SetFloat ("_uvLmX", render.lightmapScaleOffset.x);
			mat.SetFloat ("_uvLmY", render.lightmapScaleOffset.y);
			mat.SetFloat ("_uvLmZ", render.lightmapScaleOffset.z);
			mat.SetFloat ("_uvLmW", render.lightmapScaleOffset.w);
		}

	}


}
