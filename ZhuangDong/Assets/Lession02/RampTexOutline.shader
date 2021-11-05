Shader "Lession02/RampTexOutline"
{
    Properties {
		_RampTex ("RampTex", 2D) = "white" {}
        _OutlineCol ("OutlineCol", Color) = (0,0,0,1)
        _OutlineWidth ("OutlineWidth", Range(0, 0.05)) = 0.015
	}

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            Name "OUTLINE"
            Cull Front
            Tags{"LightMode" = "SRPDefaultUnlit"}
            
            HLSLPROGRAM
			#pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct a2v {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct v2f {
                float4 positionCS : SV_POSITION;
            };

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

            CBUFFER_START(UnityPerMaterial)
            // UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	            UNITY_DEFINE_INSTANCED_PROP(float4, _OutlineCol)
	            UNITY_DEFINE_INSTANCED_PROP(float, _OutlineWidth)
            // UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
            CBUFFER_END

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz + i.normalOS*_OutlineWidth );
                return o;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                return float4(_OutlineCol);
            }

			ENDHLSL
        }

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}

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
                float3 normalWS : TEXCOORD1;
            };

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                return o;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                Light light = GetMainLight();
                float2 uv = float2( dot(i.normalWS, light.direction)*0.5 + 0.5, 0.3);
                // float2 uv = float2( dot(i.normalWS, light.direction), 0.3);
                float4 color = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, uv);
                return float4(color);
            }

			ENDHLSL
        }
    }
}
