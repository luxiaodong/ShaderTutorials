Shader "SDF/RayMarching"
{
    Properties {
	}

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
			HLSLPROGRAM
			#pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            float _Raidus;

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS);
                o.normalWS = TransformObjectToWorldNormal(i.positionOS);
                o.uv = i.uv;
                return o;
            }

            float getDistance(float3 p)
            {
                float4 s = float4(0,0,0,2.5); //球的坐标和半径
                float d2s = length(p-s.xyz)-s.w;
                float d2p = p.y;
                float d = min(d2s, d2p);
                return d;
            }

            float3 getNormal(float3 p)
            {
                float2 e = float2(0.01f, 0.0f);
                float d = getDistance(p);
                float dx = getDistance(p - e.xyy);
                float dy = getDistance(p - e.yxy);
                float dz = getDistance(p - e.yyx);
                float3 n = float3(d - dx, d - dy, d - dz);
                return normalize(n);
            }

            // 原点和方向
            float rayMarching(float3 origin, float3 dir)
            {
                float depth = 0.0f;
                for(int i = 0; i < 100; ++i)
                {
                    float3 pos = origin + depth * dir;
                    float dist = getDistance(pos);
                    depth += dist;
                    if(dist < 0.01) return 1.0;
                }
                return 0.0;
            }

            float getLight(float3 p, float3 lightPos)
            {
                float3 dirL = normalize(lightPos - p);
                float3 dirN = getNormal(p);  //float3(0,1,0)
                float ndotl = dot(dirN, dirL)*0.5f + 0.5f;
                float dist = rayMarching(lightPos, -dirL);
                return dist*ndotl;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                float3 lightPos = _WorldSpaceCameraPos; //相机的位置当光源的位置
                float color = getLight(i.positionWS, lightPos);
                return float4(color, color, color, 1.0f);

                // float3 color = normalize(i.positionWS);
                // float3 color = getNormal(i.positionWS);
                // return float4(color, 1.0);
            }
 
			ENDHLSL
        }
    }
}

