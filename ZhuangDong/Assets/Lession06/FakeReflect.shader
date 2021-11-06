Shader "Lession06/FakeReflect"
{
    Properties {
        _RampTex ("RampTex", 2D) = "white" {}
        _RampType ("RampType", Range(0, 1)) = 0
        _EnvRefInt ("EnvRefInt", Range(0, 1)) = 0.1570397
        _SpecularPow ("高光次幂", range(1, 90)) = 30
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

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

            CBUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _RampType)
                UNITY_DEFINE_INSTANCED_PROP(float, _EnvRefInt)
                UNITY_DEFINE_INSTANCED_PROP(float, _SpecularPow)
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
                //向量
                Light light = GetMainLight();
                float3 lightDir = light.direction;
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 refDir = reflect(-lightDir, i.normalWS);

                //点乘, 半Phong
                float vdotr = dot(viewDir, refDir);

                //各项
                float2 uv = float2(vdotr*0.5+0.5, _RampType);
                float3 diffuse = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, uv);
                float3 specular = pow( max(0, vdotr), _SpecularPow);
                float3 color = diffuse*_EnvRefInt + specular;
                return float4(color,1);
            }

			ENDHLSL
        }
    }
}
