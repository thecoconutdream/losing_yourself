using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class loadingScenes : MonoBehaviour
{

    public string scene;

    public string collidingObject;

    void OnCollisionEnter(Collision coll)
    {
        if (coll.gameObject.name == collidingObject)
        {
            SceneManager.LoadScene(scene);
        }
    }

}