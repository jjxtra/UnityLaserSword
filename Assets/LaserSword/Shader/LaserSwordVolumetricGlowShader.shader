Shader "LaserSword/LaserSwordVolumetricGlowShader"
{
	Properties
	{
		[PerRendererData] _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		[PerRendererData] _CapsuleStart("Start", Vector) = (0.0, 0.0, 0.0, 0.0)
		[PerRendererData] _CapsuleEnd("End", Vector) = (0.0, 10.0, 0.0, 0.0)
		[PerRendererData] _CapsuleRadius("Radius", Float) = 0.5
		[PerRendererData] _GlowIntensity("Intensity", Range(0.0, 10.0)) = 3.0
		[PerRendererData] _GlowFalloff("Glow Power", Range(0.01, 8.0)) = 1.5
		[PerRendererData] _GlowCenterFalloff("Glow Center Power", Range(0.01, 1.0)) = 0.15
		[PerRendererData] _GlowDither("Glow Dither", Range(0.0, 1.0)) = 0.1
		[PerRendererData] _GlowMax("Max Glow", Range(0.0, 3.0)) = 1.0
		[PerRendererData] _GlowInvFade("Glow inv fade", Range(0.0, 3.0)) = 0.5
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
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile_instancing
			#pragma multi_compile_particles

			#include "UnityCG.cginc"

			uniform fixed3 _Color;
			uniform float3 _CapsuleStart; 
			uniform float3 _CapsuleEnd;
			uniform float _CapsuleRadius;
			uniform float _CapsuleRadiusInv;
			uniform fixed _GlowIntensity;
			uniform fixed _GlowFalloff;
			uniform fixed _GlowCenterFalloff;
			uniform fixed _GlowDither;
			uniform fixed _GlowMax;
			uniform fixed _GlowInvFade;

#if defined(SOFTPARTICLES_ON)

			uniform sampler2D _CameraDepthTexture;

#endif

			static const float3 capsuleDir = normalize(_CapsuleStart - _CapsuleEnd);
			static const float3 capsuleCenter = (_CapsuleStart + _CapsuleEnd) * 0.5;
			static const float capsuleHeightHalf = 1.0 / (distance(_CapsuleStart, _CapsuleEnd) * 0.5);

#define WM_INSTANCE_VERT(v, type, o) type o; UNITY_SETUP_INSTANCE_ID(v); UNITY_TRANSFER_INSTANCE_ID(v, o); UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
#define WM_INSTANCE_FRAG(i) UNITY_SETUP_INSTANCE_ID(i); UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

            struct appdata_vert
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
				float4 vertex : SV_POSITION;
				float3 rayDir : NORMAL;
				float4 worldPos : TEXCOORD0;

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

				// optimization - we know we hit the capsule
				//UNITY_BRANCH
				//if (h >= 0.0)
				{
					float t = (-b - sqrt(h)) / a;
					float y = baoa + t * bard;

					UNITY_BRANCH
					if (y > 0.0 && y < baba)
					{
						// body
						h = t;
					}
					else
					{
						// caps
						float3 oc = (y <= 0.0) ? oa : ro - pb;
						b = dot(rd, oc);
						c = dot(oc, oc) - r * r;
						h = b * b - c;

						// optimization - we know we hit the capsule
						//UNITY_BRANCH
						//if (h > 0.0)
						{
							h = -b - sqrt(h);
						}
						//else
						//{
							//h = 0.0;
						//}
					}
				}
				//else
				//{
					//h = 0.0;
				//}

				// h is distance to capsule
				return h;
			}

			inline float RandomFloat(float3 v)
			{
				return (frac(frac(dot(v.xyz, float3(12.9898, 78.233, 45.5432))) * 43758.5453) - 0.5) * 2.0;
				//return frac(sin(dot(v.xyz, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
			}

			inline float3 LinePointDistance3(float3 lineStart, float3 lineDir, float3 p)
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

				return onLine;
			}

			inline float LinePointDistance(float3 lineStart, float3 lineDir, float3 p)
			{
				float3 lp = LinePointDistance3(lineStart, lineDir, p);
				return length(lp);
			}

			inline float LinePointDistanceSquared(float3 lineStart, float3 lineDir, float3 p)
			{
				float3 lp = LinePointDistance3(lineStart, lineDir, p);
				return dot(lp, lp);
			}

            v2f vert(appdata_vert v)
            {
				WM_INSTANCE_VERT(v, v2f, o);

                o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldPos.w = distance(_WorldSpaceCameraPos, o.worldPos.xyz);
				o.rayDir = o.worldPos - _WorldSpaceCameraPos;

#if defined(SOFTPARTICLES_ON)

				o.projPos = ComputeScreenPos(o.vertex);
				COMPUTE_EYEDEPTH(o.projPos.z);

#endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				WM_INSTANCE_FRAG(i);

				i.rayDir = normalize(i.rayDir);
				fixed dither = (1.0 + (_GlowDither * RandomFloat(i.rayDir)));
				float toCapsule = CapsuleIntersect(_WorldSpaceCameraPos, i.rayDir, _CapsuleStart, _CapsuleEnd, _CapsuleRadius);
				float intersect = i.worldPos.w - toCapsule;
				float3 startPos = _WorldSpaceCameraPos + (i.rayDir * toCapsule);
				float3 endPos = startPos + (i.rayDir * intersect);
				float3 avgPos = (startPos + endPos) * 0.5;
				float3 offset = (i.rayDir * intersect * 0.25);
				fixed lineDist1 = 1.0 - (_CapsuleRadiusInv * LinePointDistance(_CapsuleStart, capsuleDir, avgPos));
				fixed lineDist2 = 1.0 - (_CapsuleRadiusInv * LinePointDistance(_CapsuleStart, capsuleDir, startPos + offset));
				fixed lineDist3 = 1.0 - (_CapsuleRadiusInv * LinePointDistance(_CapsuleStart, capsuleDir, endPos - offset));
				fixed lineDist = (lineDist1 + lineDist2 + lineDist3) * 0.3333;
				fixed centerDist = pow(1.0 - saturate(capsuleHeightHalf * distance(avgPos, capsuleCenter)), _GlowCenterFalloff);

				intersect = min(1.0, lineDist * centerDist * dither);
				intersect = pow(intersect, _GlowFalloff);
				intersect = min(intersect * _GlowIntensity, _GlowMax);

#if defined(SOFTPARTICLES_ON)

				float sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))));
				float partZ = i.projPos.z;
				intersect *= saturate(_GlowInvFade * min(partZ * partZ * partZ, (sceneZ - partZ)));

#endif

				return fixed4(_Color * intersect, 0.0);
            }
            ENDCG
        }
    }
}
