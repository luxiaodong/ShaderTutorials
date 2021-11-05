Shader "Lession02/Halftone"
{
    Properties {
		_DotSize ("DotSize", Range(1, 100)) = 8
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
            };

            struct v2f {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float4 positionSS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

            CBUFFER_START(UnityPerMaterial)
            // UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _DotSize)
            // UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
            CBUFFER_END

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.positionSS = ComputeScreenPos(o.positionCS);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                return o;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                Light light = GetMainLight();
                float ndotl = dot(i.normalWS, light.direction);
                float2 screenUV = i.positionSS.xy/i.positionSS.w; // 0-1
                screenUV = float2(screenUV.x * (_ScreenParams.r/_ScreenParams.g), screenUV.y).rg;
                float len = length(frac(screenUV*_DotSize) - 0.5);
                float color = round( pow(len, max(0, ndotl)*-2.5 + 2));
                return float4(color,color,color,1);
            }

			ENDHLSL
        }
    }
}
