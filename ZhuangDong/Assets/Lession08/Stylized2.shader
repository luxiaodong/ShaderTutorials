Shader "Lession08/Stylized2"
{
    Properties {
        _BaseColor ("baseColor", color) = (1.0, 1.0, 1.0, 1.0)  //物体的颜色
        _LightColor ( "lightColor" ,color) = (1.0, 1.0, 1.0, 1.0) //光的颜色
        _SpecularPow ("specPow", range(1, 90)) = 30
        _EnvRange ("EnvRange", range(0,1) ) = 0
        _Occlusion ("Occlusion", 2D) = "white" {}
        _OcclusionColor ("OcclusionColor", Color) = (1,1,1,1)

        _EnvUpColor ("EnvUpColor", Color) = (1,1,1,1)
        _EnvMiddleColor ("EnvMidColor", Color) = (1,1,1,1)
        _EnvDownColor ("EnvDownColor", Color) = (1,1,1,1)
        _UpRange ("TopRange", Range(0.1, 10)) = 1
        _DownRange ("TopRange", Range(0.1, 10)) = 1

        _FresnelColor ("FresnelColor", Color) = (0.7505785,0.9463587,0.9528302,1)
        _FresnelPow ("FresnelPow", Range(0, 20)) = 5

        _Fresnel2Color ("Fresnel2Color", Color) = (0.7505785,0.9463587,0.9528302,1)
        _Fresnel2Pow ("Fresnel2Pow", Range(0, 20)) = 5

        _ShadowRange ("ShadowRange", range(0,1) ) = 0
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

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ Anti_Aliasing_ON

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
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _LightColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _SpecularPow)
                UNITY_DEFINE_INSTANCED_PROP(float, _EnvRange)
                UNITY_DEFINE_INSTANCED_PROP(float4, _OcclusionColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _EnvUpColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _EnvMiddleColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _EnvDownColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _UpRange)
                UNITY_DEFINE_INSTANCED_PROP(float, _DownRange)
                UNITY_DEFINE_INSTANCED_PROP(float4, _FresnelColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _FresnelPow)
                UNITY_DEFINE_INSTANCED_PROP(float, _ShadowRange)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Fresnel2Color)
                UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel2Pow)
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
                float3 halfDir = normalize(viewDir + lightDir);
                float3 refDir = reflect(-lightDir, i.normalWS);

                //点乘
                float3 ndotl = dot(i.normalWS, light.direction);
                float3 ndoth = dot(i.normalWS, halfDir);
                // float3 vdotr = dot(viewDir, refDir);

                //菲尼尔
                float fresnel = (1.0-max(0,dot(i.normalWS, viewDir)));
                fresnel = pow(fresnel, _FresnelPow);
                float3 fresnelColor = lerp(_FresnelColor.rgb, float3(1,1,1), fresnel);

                //各项
                float3 diffuse = _BaseColor*max(0, ndotl).rgb;
                float3 specular = pow( max(0, ndoth), _SpecularPow );
                float shadow = MainLightRealtimeShadow(TransformWorldToShadowCoord(i.positionWS));
                float3 directColor = (diffuse + specular)*_LightColor*shadow;

                float normalG = i.normalWS.y;
                float upValue = pow(max(0.0, normalG), _UpRange);
                float downValue = pow(max(0.0, -normalG), _DownRange);
                float middleValue = 1.0 - upValue - downValue;
                float4 envMask = _EnvUpColor*upValue + _EnvDownColor*downValue + _EnvMiddleColor*middleValue;

                float oaValue = SAMPLE_TEXTURE2D(_Occlusion, sampler_Occlusion, i.uv); //直接获得单通道也可以
                float3 occColor = lerp(_OcclusionColor, envMask.rgb*fresnelColor, oaValue);
                float3 shadowColor = occColor*lerp(1,shadow,_ShadowRange);
                float3 specularColor = specular*_LightColor;

                float fresnel2 = (1.0-max(0,dot(i.normalWS, viewDir)));
                fresnel2 = pow(fresnel2, _Fresnel2Pow);
                float3 fresnel2Color = _Fresnel2Color.rgb*fresnel2;
                // _ShadowRange
                return float4(shadowColor+specularColor+fresnel2Color,1);
            }

			ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
