Shader "Custom/Plane/ScreenSpace"
{
    Properties {
		_DotSize ("DotSize", Range(0, 1)) = 0.5
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
                UNITY_DEFINE_INSTANCED_PROP(float, _DotSize)
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
                float2 screenUV = i.positionSS.xy/i.positionSS.w;
                screenUV.x = screenUV.x * (_ScreenParams.x/_ScreenParams.y);

                float zZoom = max(0.01, i.positionSS.w - _ProjectionParams.y);
                screenUV *= zZoom;

                float len = length(frac(screenUV*_DotSize) - 0.5);
                float3 color = lerp(float3(1,0,0), float3(1,1,0), len*2);
                color = lerp(color, float3(0,0,0), step(1, len*2));

                return float4(color,1);
                // return float4(screenUV.x, screenUV.y, 0, 1);
            }

			ENDHLSL
        }
    }
}
