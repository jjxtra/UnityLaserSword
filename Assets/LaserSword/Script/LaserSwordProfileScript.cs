using UnityEngine;

namespace DigitalRuby.LaserSword
{
    [CreateAssetMenu(fileName = "LaserSwordProfile_", menuName = "LaserSword/Create Profile", order = 1)]
    public class LaserSwordProfileScript : ScriptableObject
    {
        [Header("Blade")]
        [Tooltip("Blade texture")]
        public Texture2D BladeTexture;

        [Tooltip("Blade color")]
        public Color BladeColor = Color.magenta;

        [Range(0.0f, 10.0f)]
        [Tooltip("Blade intensity")]
        public float BladeIntensity = 1.0f;

        [Tooltip("Blade rim color")]
        public Color BladeRimColor = Color.white;

        [Range(0.0f, 8.0f)]
        [Tooltip("Blade rim power")]
        public float BladeRimPower = 2.0f;

        [Range(0.0f, 10.0f)]
        [Tooltip("Blade rim intensity")]
        public float BladeRimIntensity = 1.0f;

        [Header("Glow")]
        [Tooltip("Glow color")]
        public Color GlowColor = Color.red;

        [Tooltip("Glow intensity")]
        [Range(0.0f, 100.0f)]
        public float GlowIntensity = 3.0f;

        [Tooltip("Glow falloff, control power of glow")]
        [Range(0.0f, 64.0f)]
        public float GlowFalloff = 1.5f;

        [Tooltip("Glow center falloff, control glow further from center of blade")]
        [Range(0.01f, 1.0f)]
        public float GlowCenterFalloff = 0.15f;

        [Tooltip("Glow dither")]
        [Range(0.0f, 1.0f)]
        public float GlowDither = 0.1f;

        [Tooltip("Glow max")]
        [Range(0.0f, 10.0f)]
        public float GlowMax = 1.0f;

        [Tooltip("Glow scale / width")]
        public Vector3 GlowScale = new Vector3(0.35f, 1.5f, 0.35f);

        [Header("Audio")]
        [Tooltip("Sound to play when the laser sword turns on")]
        public AudioClip StartSound;

        [Tooltip("Sound to play when the laser sword turns off")]
        public AudioClip StopSound;

        [Tooltip("Sound to play when the laser sword stays on")]
        public AudioClip ConstantSound;

        [Header("Other")]
        [Tooltip("How long it takes to turn the laser sword on and off")]
        [Range(0.1f, 3.0f)]
        public float ActivationTime = 1.0f;

        [Tooltip("Flicker intensity")]
        [Range(0.0f, 0.3f)]
        public float FlickerIntensity = 0.03f;
    }
}