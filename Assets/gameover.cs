using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using System.Threading;

public class gameover : MonoBehaviour {

    public string collidingObject;
    public GameObject ending;

    // Update is called once per frame
    void GameoverMagic ()
    {
        ending.SetActive(true);
        Thread.Sleep(9000);
        SceneManager.LoadScene("TitleScreen");

    }
   
    void OnCollisionEnter(Collision coll)
    {
        if (coll.gameObject.name == collidingObject)
        {
            GameoverMagic();
        }
    }

}
