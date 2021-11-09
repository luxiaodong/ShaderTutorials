Shader "Lession09/Fresnel"
{
    Properties {
        _FresnelColor ("FresnelCol", Color) = (1,1,1,1)
        _FresnelPower ("FresnelPower", Range(0.1,10)) = 2
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
	            UNITY_DEFINE_INSTANCED_PROP(float4, _FresnelColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _FresnelPower)
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
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                float power = pow(1.0-max(0, dot(i.normalWS,viewDir)), _FresnelPower);
                float4 color = _FresnelColor*power; // F0 = 0
                return float4(color.rgb, 1);
            }

			ENDHLSL
        }
    }
}
