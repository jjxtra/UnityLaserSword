// Laser Sword for Unity
// (c) 2016 Digital Ruby, LLC
// http://www.digitalruby.com

Shader "LaserSword/LaserSwordShader"
{
	Properties
	{
		[PerRendererData] _MainTex("Main Texture", 2D) = "white" {}
		[PerRendererData] _TintColor ("Tint Color", Color) = (1, 1, 1, 1)
		[PerRendererData] _Intensity("Intensity", Float) = 1
		[PerRendererData] _RimColor("Rim Color", Color) = (1, 1, 1, 1)
		[PerRendererData] _RimPower("Rim Power", Float) = 2
		[PerRendererData] _RimIntensity("Rim Intensity", Float) = 1
		[PerRendererData] _InvFade("Inv Fade", Range(0.01, 3.0)) = 0.5
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent" "IgnoreProjector" = "True" "Queue" = "Transparent" "LightMode" = "Always" "PreviewType" = "Plane" }
		LOD 100
		Cull Back
		Lighting Off
		ColorMask RGBA
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile_instancing
			#pragma multi_compile_particles

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
		    uniform float4 _MainTex_ST;
			uniform fixed4 _TintColor;
			uniform fixed _Intensity;
			uniform fixed4 _RimColor;
			uniform fixed _RimPower;
			uniform fixed _RimIntensity;
			uniform fixed _InvFade;

#if defined(SOFTPARTICLES_ON)

			uniform sampler2D _CameraDepthTexture;

#endif
			
			struct appdata_t
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;

#if defined(SOFTPARTICLES_ON)

				float4 worldPos : TEXCOORD1;
				float4 projPos : TEXCOORD2;

#endif

			};

#define WM_INSTANCE_VERT(v, type, o) type o; UNITY_SETUP_INSTANCE_ID(v); UNITY_TRANSFER_INSTANCE_ID(v, o); UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
#define WM_INSTANCE_FRAG(i) UNITY_SETUP_INSTANCE_ID(i); UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

			inline float3 WorldSpaceVertexPos(float4 vertex)
			{
				return mul(unity_ObjectToWorld, vertex).xyz;
			}

			inline float3 WorldSpaceNormal(float3 normal)
			{
				return mul((float3x3)unity_ObjectToWorld, normal);
			}

			v2f vert (appdata_t v)
			{
				WM_INSTANCE_VERT(v, v2f, o);

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				fixed3 viewDir = normalize(_WorldSpaceCameraPos - WorldSpaceVertexPos(v.vertex).xyz);
				fixed3 normalDir = normalize(WorldSpaceNormal(v.normal));
				o.color.a = 1.0 - abs(dot(viewDir, normalDir));

#if defined(SOFTPARTICLES_ON)

				o.projPos = ComputeScreenPos(o.vertex);
				COMPUTE_EYEDEPTH(o.projPos.z);
				o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldPos.w = distance(_WorldSpaceCameraPos, o.worldPos.xyz);

#endif

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				WM_INSTANCE_FRAG(i);

				fixed rim = i.color.a;
				fixed3 rimLight = _RimIntensity * pow(rim, _RimPower) * _RimColor.rgb;
				fixed3 col = tex2D(_MainTex, i.texcoord).rgb * i.color.rgb * _TintColor.rgb * _Intensity;
				col += rimLight;

#if defined(SOFTPARTICLES_ON)

				float sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))));
				float partZ = i.projPos.z;
				float fade = saturate(_InvFade * min(partZ * partZ * partZ, (sceneZ - partZ)));
				return fixed4(col, fade);
#else

				return fixed4(col, 1.0);

#endif

			}

			ENDCG 
		}
	}
}