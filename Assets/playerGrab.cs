using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class playerGrab : MonoBehaviour {

    public GameObject grabbingObject;

    public GameObject grabbed;

    bool inhands = false;

    Vector3 handPosition;


	// Use this for initialization
	void Start () {
        handPosition = grabbingObject.transform.position;
	}
	
	// Update is called once per frame
	void Update () {
		if(Input.GetButtonDown("Fire1"))
           {
            if (!inhands)
            {
                grabbingObject.transform.SetParent(grabbed.transform);
                grabbingObject.transform.localPosition = grabbed.transform.localPosition;
                inhands = true;
            }
            else if(inhands)
            {
                this.GetComponent<playerGrab>().enabled = false;
                grabbingObject.transform.SetParent(null);
                grabbingObject.transform.localPosition = this.transform.localPosition;
                //hand.transform.localPosition = handPosition;
                inhands = false;
            }
            }
	}
}
