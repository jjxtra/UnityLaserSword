// Laser Sword for Unity
// (c) 2016 Digital Ruby, LLC
// http://www.digitalruby.com

Shader "LaserSword/LaserSwordShader"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
		_TintColor ("Tint Color", Color) = (1, 1, 1, 1)
		_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimPower("Rim Power", Float) = 1
		_Intensity("Intensity", Float) = 1
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
			fixed4 _RimColor;
			fixed _RimPower;
			fixed _Intensity;
			
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
				float3 viewPos : TEXCOORD1;
				float3 normal : TEXCOORD2;
				float4 worldPos : TEXCOORD3;
			};

			v2f vert (appdata_t v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.viewPos = normalize(UnityObjectToViewPos(v.vertex).xyz);
				o.normal = UnityObjectToViewPos(-v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed d = distance(_WorldSpaceCameraPos, i.worldPos);
				fixed4 col = tex2D(_MainTex, i.texcoord);
				fixed rimFalloff = max(0, dot(i.viewPos, i.normal) / min(1, d));
				rimFalloff = pow(rimFalloff, _RimPower);
				col = lerp(_RimColor, col, rimFalloff) * _TintColor * i.color * _Intensity;
				return col;
			}
			ENDCG 
		}
	}
}