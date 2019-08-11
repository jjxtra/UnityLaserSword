Shader "LaserSword/LaserSwordVolumetricGlowShader"
{
	Properties
	{
		[PerRendererData] _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		[PerRendererData] _CapsuleStart("Start", Vector) = (0.0, 0.0, 0.0, 0.0)
		[PerRendererData] _CapsuleEnd("End", Vector) = (0.0, 10.0, 0.0, 0.0)
		[PerRendererData] _CapsuleScale("Scale", Vector) = (1.0, 1.0, 1.0, 1.0)
		[PerRendererData] _CapsuleRoundness("Roundness", Range(0.0, 1.0)) = 0.5
		[PerRendererData] _GlowIntensity("Intensity", Range(0.0, 10.0)) = 3.0
		[PerRendererData] _GlowPower("Glow Power", Range(0.0, 8.0)) = 3.0
		[PerRendererData] _MaxGlow("Max Glow", Range(0.0, 1.0)) = 1.0
	}
		SubShader
	{
		Tags{ "RenderType" = "Transparent" "IgnoreProjector" = "True" "Queue" = "Transparent+1" "LightMode" = "Always" "PreviewType" = "Plane" }

		Pass
		{
			Blend One One
			ZWrite Off
			Cull Front

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform fixed3 _Color;
			uniform float3 _CapsuleStart;
			uniform float3 _CapsuleEnd;
			uniform float3 _CapsuleScale;
			uniform float _CapsuleRoundness;
			uniform fixed _GlowIntensity;
			uniform fixed _GlowPower;
			uniform fixed _MaxGlow;
			
#define CAPSULE_RAY_MARCH_COUNT 4
#define CAPSULE_RAY_MARCH_COUNT_INV (1.0 / float(CAPSULE_RAY_MARCH_COUNT))
#define CAPSULE_RADIUS_MULTIPLIER 0.35
#define CAPSULE_LENGTH_MULTIPLIER 1.15
#define CAPSULE_LENGTH_POWER 0.5
#define _InvFade 0.01

			static const float capsuleRadius = _CapsuleScale.x * CAPSULE_RADIUS_MULTIPLIER;
			static const float capsuleLength = _CapsuleScale.y * CAPSULE_LENGTH_MULTIPLIER;
			static const float3 capsuleDir = normalize(_CapsuleEnd - _CapsuleStart);
			static const float3 capsuleCenter = (_CapsuleEnd + _CapsuleStart) * 0.5;

#if defined(SOFTPARTICLES_ON)

			fixed _InvFade;
			sampler2D _CameraDepthTexture;

#endif

            struct appdata_vert
            {
                float4 vertex : POSITION;
                //float2 uv : TEXCOORD0;
            };

            struct v2f
            {
				float4 vertex : SV_POSITION;
				float3 rayDir : NORMAL;
                //float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD0;


#if defined(SOFTPARTICLES_ON)

				float4 projPos : TEXCOORD1;

#endif

            };

			// intersect capsule : http://www.iquilezles.org/www/articles/intersectors/intersectors.htm
			float CapsuleIntersect(in float3 ro, in float3 rd, in float3 pa, in float3 pb, in float r)
			{
				float3 ba = pb - pa;
				float3 oa = ro - pa;

				float baba = dot(ba, ba);
				float bard = dot(ba, rd);
				float baoa = dot(ba, oa);
				float rdoa = dot(rd, oa);
				float oaoa = dot(oa, oa);

				float a = baba - bard * bard;
				float b = baba * rdoa - baoa * bard;
				float c = baba * oaoa - baoa * baoa - r * r*baba;
				float h = b * b - a * c;
				if (h >= 0.0)
				{
					float t = (-b - sqrt(h)) / a;

					float y = baoa + t * bard;

					// body
					if (y > 0.0 && y < baba) return t;

					// caps
					float3 oc = (y <= 0.0) ? oa : ro - pb;
					b = dot(rd, oc);
					c = dot(oc, oc) - r * r;
					h = b * b - c;
					if (h > 0.0)
					{
						return -b - sqrt(h);
					}
				}
				return -1.0;
			}

			inline float LinePointDistanceSquared(float3 lineStart, float3 lineDir, float3 p)
			{
				// http://wiki.unity3d.com/index.php?title=3d_Math_functions

				// distance vector from point to line start
				float3 linePointToPoint = p - lineStart;

				// distance from line start in lineDir direction where point p is closest
				float t = dot(linePointToPoint, lineDir);

				// point on line where p is closest
				float3 onLine = lineStart + (lineDir * t);

				// distance from point to line point
				onLine = onLine - p;

				// return squared distance
				return dot(onLine, onLine);
			}

            v2f vert(appdata_vert v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.rayDir = o.worldPos - _WorldSpaceCameraPos;

#if defined(SOFTPARTICLES_ON)

				o.projPos = ComputeScreenPos(o.vertex);
				COMPUTE_EYEDEPTH(o.projPos.z);

#endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				i.rayDir = normalize(i.rayDir);
				float intersect = CapsuleIntersect(_WorldSpaceCameraPos, i.rayDir, _CapsuleStart, _CapsuleEnd, _CapsuleRoundness);
				float3 rayStart = _WorldSpaceCameraPos + (intersect * i.rayDir);
				float3 rayEnd = i.worldPos;
				intersect = distance(rayStart, rayEnd);
				float3 rayMarch = (rayEnd - rayStart) * CAPSULE_RAY_MARCH_COUNT_INV;
				float dist = 0.0;

				// ray march through glow volume
				UNITY_LOOP
				for (uint i = 0; i < CAPSULE_RAY_MARCH_COUNT; i++)
				{
					dist += saturate((capsuleRadius - LinePointDistanceSquared(_CapsuleStart, capsuleDir, rayStart)) *
						pow((capsuleLength - distance(rayStart, capsuleCenter)), CAPSULE_LENGTH_POWER));
					rayStart += rayMarch;
				}
				dist *= CAPSULE_RAY_MARCH_COUNT_INV;
				dist = pow(dist, _GlowPower);

#if defined(SOFTPARTICLES_ON)

				float sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))));
				float partZ = i.projPos.z;
				dist *= saturate(_InvFade * (sceneZ - partZ));

#endif

				intersect = min(_MaxGlow, intersect * dist * _GlowIntensity);
				return fixed4(intersect * _Color.r, intersect * _Color.g, intersect * _Color.b, intersect);
            }
            ENDCG
        }
    }
}
