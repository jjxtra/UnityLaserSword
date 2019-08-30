// Laser Sword for Unity
// (c) 2016 Digital Ruby, LLC
// http://www.digitalruby.com

Shader "LaserSword/LaserSwordGlowShader"
{
	Properties
	{
		_TintColor("Tint Color", Color) = (1, 1, 1, 1)
		_InvFade("Inv Fade", Range(0.01, 3)) = 0.05
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

			fixed4 _TintColor;

#if defined(SOFTPARTICLES_ON)

			fixed _InvFade;
			sampler2D _CameraDepthTexture;

#endif

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 normal : TEXCOORD0;
				float3 ray : TEXCOORD1;
				float3 tangent : TANGENT;

#if defined(SOFTPARTICLES_ON)

				float4 projPos : TEXCOORD2;

#endif

			};

			float4 iCapsule(in float3 ro, in float3 rd, in float3 cc, in float3 ca, float cr, float ch) // cc center, ca orientation axis, cr radius, ch height
			{
				float3  oc = ro - cc;
				ch *= 0.5;

				float card = dot(ca, rd);
				float caoc = dot(ca, oc);

				float a = 1.0 - card*card;
				float b = dot(oc, rd) - caoc*card;
				float c = dot(oc, oc) - caoc*caoc - cr*cr;
				float h = b*b - a*c;
				if (h<0.0) return (-1.0);
				float t = (-b - sqrt(h)) / a;
				float y = caoc + t*card;

				// body
				if (abs(y)<ch) return float4(t, normalize(oc + t*rd - ca*y));

				// caps
				float sy = sign(y);
				oc = ro - (cc + sy*ca*ch);
				b = dot(rd, oc);
				c = dot(oc, oc) - cr*cr;
				h = b*b - c;
				if (h>0.0)
				{
					t = -b - sqrt(h);
					return float4(t, normalize(oc + rd*t));
				}

				return (-1.0);
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
				o.ray = WorldSpaceViewDir(v.vertex);
				o.tangent = v.tangent;

#if defined(SOFTPARTICLES_ON)

				o.projPos = ComputeScreenPos(o.vertex);
				COMPUTE_EYEDEPTH(o.projPos.z);

#endif

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed d = max(0, dot(normalize(i.normal), normalize(i.ray)));
				fixed4 c = _TintColor;
				c.a = pow(d, 3);

				// https://www.shadertoy.com/view/Xt3SzX
				float4 tnor = iCapsule(_WorldSpaceCameraPos, i.ray, 0.0, normalize(float3(0.3, 0.1, 0.4)), 0.2, 0.9);
				float t = tnor.x;
				c.a = t;

#if defined(SOFTPARTICLES_ON)

				float sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))));
				float partZ = i.projPos.z;
				i.color.a *= saturate(_InvFade * (sceneZ - partZ));

#endif

				return c;
			}
			ENDCG
		}
	}
}
