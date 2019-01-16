using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class seccondNarration : MonoBehaviour {

    public static int seccondStrang = 0;
    public string collidingObject;


    void OnCollisionEnter(Collision coll)
    {
        if (coll.gameObject.name == collidingObject)
        {
            seccondStrang = 1;
        }
    }
}
