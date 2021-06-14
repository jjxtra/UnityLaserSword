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
			
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _TintColor;
			fixed _Intensity;
			fixed4 _RimColor;
			fixed _RimPower;
			fixed _RimIntensity;
			
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
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				WM_INSTANCE_FRAG(i);

				fixed rim = i.color.a;
				fixed3 rimLight = _RimIntensity * pow(rim, _RimPower) * _RimColor.rgb;
				fixed3 col = tex2D(_MainTex, i.texcoord).rgb * i.color.rgb * _TintColor.rgb * _Intensity;
				return fixed4(col + rimLight, 1.0);
			}

			ENDCG 
		}
	}
}