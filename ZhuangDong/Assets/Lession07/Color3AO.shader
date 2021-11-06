Shader "Lession07/Color3AO"
{
    Properties {
		_Occlusion ("Occlusion", 2D) = "white" {}
        _EnvUpColor ("EnvUpColor", Color) = (1,1,1,1)
        _EnvMiddleColor ("EnvMidColor", Color) = (1,1,1,1)
        _EnvDownColor ("EnvDownColor", Color) = (1,1,1,1)
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

            TEXTURE2D(_Occlusion);
            SAMPLER(sampler_Occlusion);

            CBUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _EnvUpColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _EnvMiddleColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _EnvDownColor)
            CBUFFER_END

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.uv = i.uv;
                return o;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                float normalG = i.normalWS.y;
                float upValue = max(0.0, normalG);
                float downValue = max(0.0, -normalG);
                float middleValue = 1.0 - upValue - downValue;
                float4 envColor = _EnvUpColor*upValue + _EnvDownColor*downValue + _EnvMiddleColor*middleValue;
                float4 color = SAMPLE_TEXTURE2D(_Occlusion, sampler_Occlusion, i.uv);
                float4 finalColor = color*envColor;
                return float4(finalColor.rgb,1);
            }

			ENDHLSL
        }
    }
}
