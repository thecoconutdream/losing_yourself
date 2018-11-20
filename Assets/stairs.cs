using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class stairs : MonoBehaviour {

    public GameObject avatar;

    public Rigidbody freeze;

    public GameObject spiralStairs;
    // Use this for initialization
    void Start () {
        freeze = avatar.GetComponent<Rigidbody>();
    }
	
	// Update is called once per frame
	void Update () {

        if(avatar.transform.localPosition.x == this.transform.localPosition.x)
        {
            freeze.constraints = RigidbodyConstraints.FreezePositionX & RigidbodyConstraints.FreezePositionY;
        }
		
	}
}
