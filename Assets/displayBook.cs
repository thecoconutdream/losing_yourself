using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class displayBook : MonoBehaviour {

    public GameObject book;
    // Use this for initialization
    void Start () {
        if (seccondNarration.seccondStrang == 1)
        {
            book.SetActive(true);
        }
    }
	
}
