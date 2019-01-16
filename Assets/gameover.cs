using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using System.Threading;

public class gameover : MonoBehaviour {

    public string collidingObject;
    public GameObject ending;
    public GameObject seccondEnding;

    // Update is called once per frame
    void GameoverMagic ()
    {
         if (seccondNarration.seccondStrang == 1)
         {
            ending.SetActive(false);
            seccondNarration.seccondStrang = 0;
            seccondEnding.SetActive(true);
            }
        else
        {
            seccondEnding.SetActive(false);
            ending.SetActive(true);
        }
    }
   
    void OnCollisionEnter(Collision coll)
    {
        if (coll.gameObject.name == collidingObject)
        {
            GameoverMagic();
        }
    }

}
