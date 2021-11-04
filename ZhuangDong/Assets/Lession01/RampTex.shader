Shader "Lession01/RampTex"
{
    Properties {
		_RampTex ("RampTex", 2D) = "white" {}
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
                float4 color = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, uv);
                return float4(color);

                // float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                // float ndotl = dot(i.normalWS, viewDir)*0.5 + 0.5;
                // float3 color = lerp(float3(1,0,0), float3(0,1,0), pow(ndotl,5));
                // return float4(color, 1);
            }

			ENDHLSL
        }
    }
}
