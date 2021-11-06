Shader "Lession06/PaintDrop"
{
    Properties {
        _RampTex ("RampTex", 2D) = "white" {}
        _ColorSmooth ("Color(Smooth)", Color) = (0.5,0.5,0.5,1)
        _ColorRough ("Color(Rough)", Color) = (0.5,0.5,0.5,1)
        _MaskRange ("Mask Range", Range(0, 1)) = 0.4075758
        _FresnalRange ("Fresnal Range", Range(0, 5)) = 0.2
        _SpecularPow1 ("SpecPow1", Range(0, 100)) = 10
        _SpecularPow2 ("SpecPow2", Range(0, 100)) = 10
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
                UNITY_DEFINE_INSTANCED_PROP(float4, _ColorSmooth)
                UNITY_DEFINE_INSTANCED_PROP(float4, _ColorRough)
                UNITY_DEFINE_INSTANCED_PROP(float, _MaskRange)
                UNITY_DEFINE_INSTANCED_PROP(float, _FresnalRange)
                UNITY_DEFINE_INSTANCED_PROP(float4, _RampTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float, _SpecularPow1)
                UNITY_DEFINE_INSTANCED_PROP(float, _SpecularPow2)
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

                //点乘
                float ndotl = dot(i.normalWS, lightDir);
                float vdotr = dot(viewDir, refDir);

                //菲涅尔
                float fresnel = (1.0-max(0,dot(i.normalWS, viewDir)));
                float fresnelPower = pow(fresnel, _FresnalRange);

                //贴图
                float2 uv = TRANSFORM_TEX(i.uv, _RampTex);
                float3 texColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, uv).rgb;
                float3 texMask = step(texColor, _MaskRange);
                // float3 texMask = step(_MaskRange, texColor);
                float  gray = dot(texMask, float3(0.3, 0.59, 0.11));
                float  power = lerp(_SpecularPow1, _SpecularPow2, gray);

                //各项颜色
                float3 diffuse = lerp(_ColorSmooth, _ColorRough, gray).rgb * max(0, ndotl);
                float3 fresnelColor = _ColorSmooth*fresnelPower;
                float3 specular = pow( max(0, vdotr), power) + fresnelColor;
                float3 finalColor = diffuse + specular;

                return float4(finalColor, 1);
            }

			ENDHLSL
        }
    }
}
