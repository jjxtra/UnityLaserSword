// LaserSword for Unity
// (c) 2016 Digital Ruby, LLC
// http://www.digitalruby.com

using UnityEngine;
using System.Collections;

namespace DigitalRuby.LaserSword
{
    public class LaserSwordScript : MonoBehaviour
    {
        [Tooltip("Laser sword profile")]
        public LaserSwordProfileScript Profile;

        [Tooltip("Root game object.")]
        public GameObject Root;

        [Tooltip("Hilt game object.")]
        public GameObject Hilt;

        [Tooltip("Blade sword renderer.")]
        public MeshRenderer BladeSwordRenderer;

        [Tooltip("Blade glow renderer.")]
        public MeshRenderer BladeGlowRenderer;

        [Tooltip("Blade sword mesh.")]
        public MeshFilter BladeSwordMesh;

        [Tooltip("Light game object.")]
        public Light Light;

        [Tooltip("Audio source.")]
        public AudioSource AudioSource;

        [Tooltip("Audio source for looping.")]
        public AudioSource AudioSourceLoop;

        [Tooltip("Blade start")]
        public GameObject BladeStart;

        [Tooltip("Blade end")]
        public GameObject BladeEnd;

        private float bladeHeight;
        private int state; // 0 = off, 1 = on, 2 = turning off, 3 = turning on
        private GameObject temporaryBladeStart;
        private float bladeDir; // 1 = up, -1 = down
        private float bladeTime;
        private float bladeIntensity;
        private MaterialPropertyBlock swordBlock;
        private MaterialPropertyBlock glowBlock;

        private void CheckState()
        {
            if (state == 2 || state == 3)
            {
                bladeTime += Time.deltaTime;
                float percent = Mathf.Lerp(0.01f, 1.0f, bladeTime / Profile.ActivationTime);
                Vector3 end = temporaryBladeStart.transform.position + (Root.transform.up * bladeDir * percent * bladeHeight);
                BladeEnd.transform.position = end;
                bladeIntensity = Mathf.Pow((state == 3 ? percent : (1.0f - percent)), 0.33f);

                if (bladeTime >= Profile.ActivationTime)
                {
                    GameObject.Destroy(temporaryBladeStart);
                    bladeTime = 0.0f;
                    if (state == 2)
                    {
                        state = 0;
                    }
                    else
                    {
                        state = 1;
                    }
                }
            }
        }

        private void UpdateBlade()
        {
            float distance = Vector3.Distance(BladeEnd.transform.position, BladeStart.transform.position);
            float percent = distance / bladeHeight;
            float jitterBladeIntensity = percent * (1.0f + UnityEngine.Random.Range(0.0f, Profile.FlickerIntensity));

            BladeSwordRenderer.transform.localScale = new Vector3(1.0f, percent, 1.0f);
            if (percent < 0.01f)
            {
                BladeSwordRenderer.gameObject.SetActive(false);
                BladeGlowRenderer.gameObject.SetActive(false);
            }
            else
            {
                BladeSwordRenderer.gameObject.SetActive(true);
                BladeGlowRenderer.gameObject.SetActive(true);
            }

            BladeGlowRenderer.transform.position = BladeStart.transform.position + ((BladeEnd.transform.position - BladeStart.transform.position) * 0.5f);
            BladeGlowRenderer.transform.up = (BladeEnd.transform.position - BladeStart.transform.position).normalized;
            BladeGlowRenderer.transform.localScale = new Vector3(Profile.GlowScale.x, (BladeEnd.transform.position - BladeStart.transform.position).magnitude * 0.5f * Profile.GlowScale.y, Profile.GlowScale.z);

            float halfGlowCapsule = BladeGlowRenderer.transform.lossyScale.y;
            Vector3 glowCapsuleTop = BladeGlowRenderer.transform.position - (halfGlowCapsule * BladeGlowRenderer.transform.up);
            Vector3 glowCapsuleBottom = BladeGlowRenderer.transform.position + (halfGlowCapsule * BladeGlowRenderer.transform.up);

            Light.intensity = jitterBladeIntensity;
            Light.color = Profile.GlowColor;

            BladeSwordRenderer.GetPropertyBlock(swordBlock);
            if (Profile.BladeTexture != null)
            {
                swordBlock.SetTexture("_MainTex", Profile.BladeTexture);
            }

            swordBlock.SetColor("_TintColor", Profile.BladeColor * jitterBladeIntensity);
            swordBlock.SetFloat("_Intensity", Profile.BladeIntensity * jitterBladeIntensity);
            swordBlock.SetColor("_RimColor", Profile.BladeRimColor);
            swordBlock.SetFloat("_RimPower", Profile.BladeRimPower);
            swordBlock.SetFloat("_RimIntensity", Profile.BladeRimIntensity * jitterBladeIntensity);
            BladeSwordRenderer.SetPropertyBlock(swordBlock);

            BladeGlowRenderer.GetPropertyBlock(glowBlock);
            float capsuleRadius = (BladeGlowRenderer.transform.lossyScale.x + BladeGlowRenderer.transform.lossyScale.z) * 0.5f;
            glowBlock.SetColor("_Color", Profile.GlowColor * jitterBladeIntensity);
            glowBlock.SetVector("_CapsuleStart", glowCapsuleTop);
            glowBlock.SetVector("_CapsuleEnd", glowCapsuleBottom);
            glowBlock.SetFloat("_CapsuleRadius", capsuleRadius);
            glowBlock.SetFloat("_CapsuleRadiusInv", 1.0f / capsuleRadius);
            glowBlock.SetFloat("_GlowIntensity", Profile.GlowIntensity * jitterBladeIntensity);
            glowBlock.SetFloat("_GlowFalloff", Profile.GlowFalloff);
            glowBlock.SetFloat("_GlowCenterFalloff", Profile.GlowCenterFalloff);
            glowBlock.SetFloat("_GlowDither", Profile.GlowDither);
            glowBlock.SetFloat("_GlowMax", Profile.GlowMax);
            BladeGlowRenderer.SetPropertyBlock(glowBlock);
        }

        private void Start()
        {
            swordBlock = new MaterialPropertyBlock();
            glowBlock = new MaterialPropertyBlock();
            BladeEnd.transform.position = BladeStart.transform.position;
            bladeHeight = BladeSwordMesh.sharedMesh.bounds.extents.y * 2.0f;

            if (Camera.main != null && Camera.main.depthTextureMode == DepthTextureMode.None)
            {
                Camera.main.depthTextureMode = DepthTextureMode.Depth;
            }
        }

        private void Update()
        {
            CheckState();
            UpdateBlade();
        }

        /// <summary>
        /// Pass true to turn on the laser sword, false to turn it off
        /// </summary>
        /// <param name="value">Whether the laser sword is on or off</param>
        /// <returns>True if success, false if invalid operation (i.e. laser sword is already on or off)</returns>
        public bool TurnOn(bool value)
        {
            if (state == 2 || state == 3 || (state == 1 && value) || (state == 0 && !value))
            {
                return false;
            }
            temporaryBladeStart = new GameObject("LaserSwordTemporaryBladeStart");
            temporaryBladeStart.hideFlags = HideFlags.HideAndDontSave;
            temporaryBladeStart.transform.parent = Root.transform;
            temporaryBladeStart.transform.position = BladeEnd.transform.position;

            if (value)
            {
                bladeDir = 1.0f;
                state = 3;
                AudioSource.PlayOneShot(Profile.StartSound);
                AudioSourceLoop.clip = Profile.ConstantSound;
                AudioSourceLoop.Play();
            }
            else
            {
                bladeDir = -1.0f;
                state = 2;
                AudioSource.PlayOneShot(Profile.StopSound);
                AudioSourceLoop.Stop();
            }

            return true;
        }


        /// <summary>
        /// Turn on the laser sword
        /// </summary>
        public void Activate()
        {
            TurnOn(true);
        }

        /// <summary>
        /// Turn off the laser sword
        /// </summary>
        public void Deactivate()
        {
            TurnOn(false);
        }

        /// <summary>
        /// Activate or deactivate the laser sword
        /// </summary>
        /// <param name="active">True to activate, false to deactivate</param>
        public void SetActive(bool active)
        {
            if (active)
            {
                Activate();
            }
            else
            {
                Deactivate();
            }
        }
    }
}