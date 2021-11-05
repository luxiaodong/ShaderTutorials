Shader "Lession02/DoubleSpot"
{
    Properties {
		_RampTex ("RampTex", 2D) = "white" {}

        _HighlightOffset1 ("HighlightOffset1", Vector) = (0,0,0,0)
        _HighlightOffset2 ("HighlightOffset2", Vector) = (0,0,0,0)

        _HightlightRange1 ("HightlightRange1", Range(0.6, 1)) = 0.8
        _HightlightRange2 ("HightlightRange2", Range(0.6, 1)) = 0.8

        _HightlightCol ("HightlightCol", Color) = (0.9079778,0.9333333,0.7812,1)
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
                float3 normalWS : TEXCOORD1;
            };

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

            CBUFFER_START(UnityPerMaterial)
            // UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	            UNITY_DEFINE_INSTANCED_PROP(float4, _HighlightOffset1)
	            UNITY_DEFINE_INSTANCED_PROP(float4, _HighlightOffset2)
                UNITY_DEFINE_INSTANCED_PROP(float, _HightlightRange1)
                UNITY_DEFINE_INSTANCED_PROP(float, _HightlightRange2)
                UNITY_DEFINE_INSTANCED_PROP(float4, _HightlightCol)
            // UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
            CBUFFER_END

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
                float2 uv = float2( dot(i.normalWS, light.direction)*0.5+0.5, 0.3);
                float4 color = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, uv);

                float ndotl1 = dot(normalize(i.normalWS), normalize(light.direction + _HighlightOffset1.xyz));
                float ndotl2 = dot(normalize(i.normalWS), normalize(light.direction + _HighlightOffset2.xyz));
                // float ndotl1 = dot(normalize(i.normalWS + _HighlightOffset1.xyz), normalize(light.direction));
                // float ndotl2 = dot(normalize(i.normalWS + _HighlightOffset2.xyz), normalize(light.direction));

                float mask1 = step(_HightlightRange1, ndotl1);
                float mask2 = step(_HightlightRange2, ndotl2);
                float mask = max(mask1, mask2);

                color = lerp(color, _HightlightCol, mask);
                return float4(color);
            }

			ENDHLSL
        }
    }
}
