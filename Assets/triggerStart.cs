using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class triggerStart : MonoBehaviour
{

    // Use this for initialization
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        if ((Avatar.FindObjectOfType<playerGrab>().enabled) && (Input.GetButtonDown("Fire1")))
        {
            SceneManager.LoadScene("TitleScreen");
        }
    }


}