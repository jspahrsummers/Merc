using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerCameraController : MonoBehaviour
{
    private GameObject followTarget => GameObject.FindWithTag("Player");

    void Start()
    {

    }

    void LateUpdate()
    {
        var followPosition = followTarget.transform.position;
        transform.position = new Vector3(followPosition.x, followPosition.y, transform.position.z);
    }
}
