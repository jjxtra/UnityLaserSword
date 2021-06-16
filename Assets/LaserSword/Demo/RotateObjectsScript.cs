using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DigitalRuby.LaserSword
{
    public class RotateObjectsScript : MonoBehaviour
    {
        public RotationInfo[] ObjectsToRotate;

        private void Update()
        {
            foreach (var info in ObjectsToRotate)
            {
                if (info != null && info.Transform != null)
                {
                    info.Transform.Rotate(info.RotationVelocity * Time.deltaTime);
                }
            }
        }
    }

    [System.Serializable]
    public class RotationInfo
    {
        public Transform Transform;
        public Vector3 RotationVelocity = new Vector3(20.0f, 175.0f, 150.0f);
    }
}