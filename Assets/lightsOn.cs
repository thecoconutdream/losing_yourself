using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class lightsOn : MonoBehaviour {

    public GameObject bigLamp;
    public GameObject middleLamp;
    public GameObject smallLamp;
    public GameObject directionalLight;
    public GameObject flickerNoise;

    public float timer;

    private int i=4;

    // Use this for initialization
    void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    private void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.name == "lightTrigger")
        {

            StartCoroutine(FlickeringLight());
            directionalLight.SetActive(true);

        }
    }

    IEnumerator FlickeringLight()
    {
        i--;
        Debug.Log(i);
        flickerNoise.SetActive(true);
        bigLamp.SetActive(true);
        middleLamp.SetActive(true);
        smallLamp.SetActive(true);
        
        timer = Random.Range(0.1f, 0.2f);

        yield return new WaitForSeconds(timer);

        bigLamp.SetActive(false);
        middleLamp.SetActive(false);
        smallLamp.SetActive(false);
        
        timer = Random.Range(0.1f, 0.2f);
        yield return new WaitForSeconds(timer);

        if (i == 0)
        {
            flickerNoise.SetActive(true);
            bigLamp.SetActive(true);
            middleLamp.SetActive(true);
            smallLamp.SetActive(true);
            StopCoroutine(FlickeringLight());
        }
        else
        {
            StartCoroutine(FlickeringLight());
        }
    }
}
