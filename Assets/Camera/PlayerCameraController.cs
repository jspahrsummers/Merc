using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerCameraController : MonoBehaviour
{
    private GameObject followTarget => GameObject.FindWithTag("Player");

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        var followPosition = followTarget.transform.position;
        transform.position = new Vector3(followPosition.x, followPosition.y, transform.position.z);
    }
}
