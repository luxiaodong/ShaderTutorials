Shader "Lession10/OldSchoolPro"
{
    Properties {
        _BaseColor ("baseColor", color) = (1.0, 1.0, 1.0, 1.0)  //物体的颜色
        _LightColor ( "lightColor" ,color) = (1.0, 1.0, 1.0, 1.0) //光的颜色
        _SpecularPow ("specPow", range(1, 90)) = 30
        _EnvRange ("EnvRange", range(0,5) ) = 0
        _Occlusion ("Occlusion", 2D) = "white" {}
        _EnvUpColor ("EnvUpColor", Color) = (1,1,1,1)
        _EnvMiddleColor ("EnvMidColor", Color) = (1,1,1,1)
        _EnvDownColor ("EnvDownColor", Color) = (1,1,1,1)
        _NormalTex ("NormalMap", 2D) = "bump" {}
        _Cubemap   ("CubeMap", Cube) = "_Skybox" {}
        _CubemapMip ("CubeMapMip", Range(0, 7)) = 0
        _FresnelPower ("FresnelPower", Range(0,10)) = 0
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
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct a2v {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 TtoW1:TEXCOORD3;
				float3 TtoW2:TEXCOORD4;
				float3 TtoW3:TEXCOORD5;
            };

            TEXTURE2D(_Occlusion);
            SAMPLER(sampler_Occlusion);
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            TEXTURECUBE(_Cubemap);
            SAMPLER(sampler_Cubemap);

            CBUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _LightColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _SpecularPow)
                UNITY_DEFINE_INSTANCED_PROP(float, _EnvRange)
                UNITY_DEFINE_INSTANCED_PROP(float4, _EnvUpColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _EnvMiddleColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _EnvDownColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _FresnelPower)
                UNITY_DEFINE_INSTANCED_PROP(float, _CubemapMip)
            CBUFFER_END

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.uv = i.uv;
                float3 normalWS = TransformObjectToWorldNormal(i.normalOS);
                float3 tangentWS = normalize(TransformObjectToWorld(i.tangentOS));
                float3 binormalWS = normalize(cross(normalWS, tangentWS))*i.tangentOS.z;

                o.TtoW1 = float3(tangentWS.x, binormalWS.x, normalWS.x);
                o.TtoW2 = float3(tangentWS.y, binormalWS.y, normalWS.y);
                o.TtoW3 = float3(tangentWS.z, binormalWS.z, normalWS.z);
                return o;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                //向量
                float4 normalTS = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv);
                float3 packedNormal = UnpackNormal(normalTS);

                float3x3 rotate = float3x3(i.TtoW1, i.TtoW2, i.TtoW3);
                float3 normalWS = normalize(mul(rotate, packedNormal));

                Light light = GetMainLight();
                float3 lightDir = light.direction;
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 halfDir = normalize(viewDir + lightDir);
                float3 refDir = reflect(-lightDir, normalWS);

                //点乘
                float3 ndotl = dot(normalWS, light.direction);
                float3 ndoth = dot(normalWS, halfDir);
                // float3 vdotr = dot(viewDir, refDir);

                //菲涅尔
                float power = pow(1.0-max(0, dot(normalWS,viewDir)), _FresnelPower);

                //各项
                float3 diffuse = _BaseColor*max(0, ndotl).rgb;
                float3 specular = pow( max(0, ndoth), _SpecularPow );
                float shadow = MainLightRealtimeShadow(TransformWorldToShadowCoord(i.positionWS));
                float3 directColor = (diffuse + specular)*_LightColor*shadow;

                float3 rvDir = reflect(-viewDir, normalWS);
                float3 texColor = SAMPLE_TEXTURECUBE_LOD(_Cubemap, sampler_Cubemap, rvDir, _CubemapMip);

                float normalG = normalWS.y;
                float upValue = max(0.0, normalG);
                float downValue = max(0.0, -normalG);
                float middleValue = 1.0 - upValue - downValue;
                float4 envMask = _EnvUpColor*upValue + _EnvDownColor*downValue + _EnvMiddleColor*middleValue;
                // float3 envColor = envMask.rgb * _BaseColor; //叠加物体颜色的影响
                float oaColor = SAMPLE_TEXTURE2D(_Occlusion, sampler_Occlusion, i.uv); //直接获得单通道也可以
                float3 indirectColor = oaColor* (envMask.rgb + texColor*power) * _BaseColor;

                float3 color = directColor + _EnvRange * indirectColor;
                return float4(color,1);
            }

			ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
