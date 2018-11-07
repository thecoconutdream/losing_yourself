using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class playerGrab : MonoBehaviour {

    public GameObject hand;

    public GameObject myHand;

    bool inhands = false;

    Vector3 handPosition;


	// Use this for initialization
	void Start () {
        handPosition = hand.transform.position;
	}
	
	// Update is called once per frame
	void Update () {
		if(Input.GetButtonDown("Fire1"))
           {
            if (!inhands)
            {
                hand.transform.SetParent(myHand.transform);
                hand.transform.localPosition = myHand.transform.localPosition;
                inhands = true;
            }
            else if(inhands)
            {
                hand.transform.SetParent(null);
                hand.transform.localPosition = handPosition;
                inhands = false;
            }
            }
	}
}
