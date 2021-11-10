Shader "Lession11/OldSchoolPro"
{
    Properties 
    {
        [Header(Diffuse)]
            _MainCol    ("基本色",Color)                 = (0.5, 0.5, 0.5, 1.0)
            _MainTex    ("RGB:基础颜色 A:环境遮罩",2D)     = "white" {}
            _NormalTex	("RGB:法线贴图", 2D)              = "bump" {}

        [Header(Specular)]
            _SpecTex    ("RGB:高光颜色 A:高光强度", 2D)     = "gray" {} //A
            _SpecPowMax ("最大高光次幂",    Range(1, 90))   = 30

        [Header(Env Diffuse)]
            _EnvDiffInt ("环境漫反射强度",  Range(0, 1))    = 0.2
            _EnvUpCol   ("环境天顶颜色", Color)             = (1.0, 1.0, 1.0, 1.0)
            _EnvSideCol ("环境水平颜色", Color)             = (0.5, 0.5, 0.5, 1.0)
            _EnvDownCol ("环境地表颜色", Color)             = (0.0, 0.0, 0.0, 0.0)

        [Header(Env Specular)]
            _EnvSpecInt ("环境镜面反射强度", Range(0, 5))    = 0.2
            _EnvCubeMap ("RGB:环境贴图", cube)              = "_Skybox" {}
            _EnvCubemapMip ("环境贴图的Mipmap", Range(0, 7))       = 0
            _FresnelPow ("菲涅尔次幂", Range(0, 5))         = 1

        [Header(Emission)]
            _EmitInt    ("自发光强度", range(0, 10))         = 1
            _EmitTex    ("RGB:自发光贴图", 2d)               = "black" {}
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
                float4 positionOS : POSITION;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv0 : TEXCOORD0;
            };

            struct v2f {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 uv0 : TEXCOORD1;
                // float4 normalWS : TEXCOORD2;
                float3 tDirWS:TEXCOORD2;
				float3 bDirWS:TEXCOORD3;
				float3 nDirWS:TEXCOORD4;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            TEXTURE2D(_SpecTex);
            SAMPLER(sampler_SpecTex);
            TEXTURECUBE(_EnvCubeMap);
            SAMPLER(sampler_EnvCubeMap);
            TEXTURE2D(_EmitTex);
            SAMPLER(sampler_EmitTex);

            CBUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainCol)
                UNITY_DEFINE_INSTANCED_PROP(float, _SpecPowMax)
                UNITY_DEFINE_INSTANCED_PROP(float, _EnvDiffInt)
                UNITY_DEFINE_INSTANCED_PROP(float3, _EnvUpCol)
                UNITY_DEFINE_INSTANCED_PROP(float3, _EnvSideCol)
                UNITY_DEFINE_INSTANCED_PROP(float3, _EnvDownCol)
                UNITY_DEFINE_INSTANCED_PROP(float, _EnvSpecInt)
                UNITY_DEFINE_INSTANCED_PROP(float, _EnvCubemapMip)
                UNITY_DEFINE_INSTANCED_PROP(float, _FresnelPow)
                UNITY_DEFINE_INSTANCED_PROP(float, _EmitInt)
            CBUFFER_END

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformObjectToHClip(i.positionOS);
                // o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.uv0 = i.uv0;
                o.nDirWS = TransformObjectToWorldNormal(i.normalOS);
                o.tDirWS = normalize(TransformObjectToWorld(i.tangentOS));
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS))*i.tangentOS.z;
                return o;
            }

            float3 getNormalWS(v2f i)
            {
                float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv0));
                float3x3 tbnMatrix = float3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                float3 normalWS = mul(normalTS ,tbnMatrix);
                return normalize(normalWS);
            }

            float3 color3Ambient(float3 n)
            {
                float uMask = max(0.0, n.g);        // 获取朝上部分遮罩
                float dMask = max(0.0, -n.g);       // 获取朝下部分遮罩
                float sMask = 1.0 - uMask - dMask;  // 获取侧面部分遮罩
                float3 envCol = _EnvUpCol * uMask + _EnvSideCol * sMask + _EnvDownCol * dMask; // 混合环境色
                return envCol;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                //准备向量
                float3 nDirWS = getNormalWS(i);
                float3 lDirWS = GetMainLight().direction;
                float3 lrDirWS = reflect(-lDirWS, nDirWS); //光的反射方向,用于phong模型
                float3 vDirWS = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 vrDirWS = reflect(-vDirWS, nDirWS); //相机的反射方向,用于反射环境光
                //准备点积结果
                float ndotl = dot(nDirWS, lDirWS);  //用于漫反射
                float vdotr = dot(vDirWS, lrDirWS); //用于phong模型,不是bling-phong
                float vdotn = dot(vDirWS, nDirWS);  //用于菲涅尔                
                //采样纹理
                float4 mainTexCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
                float4 specTexCol = SAMPLE_TEXTURE2D(_SpecTex, sampler_SpecTex, i.uv0);
                float4 emitTexCol = SAMPLE_TEXTURE2D(_EmitTex, sampler_EmitTex, i.uv0); //这里理论上只需要单通道标示出发光强度即可
                // float4 cubeMapCol = SAMPLE_TEXTURECUBE_LOD(_EnvCubeMap, sampler_EnvCubeMap, vrDirWS, _EnvCubemapMip);
                float4 cubeMapCol = SAMPLE_TEXTURECUBE_LOD(_EnvCubeMap, sampler_EnvCubeMap, vrDirWS, lerp(_EnvCubemapMip,0.0,specTexCol.a));
                //光照模型(直接光照部分)
                float3 baseColor = (mainTexCol*_MainCol).rgb;
                float3 diffuseColor = baseColor*max(0.0, ndotl);
                float phong = pow(max(0.0, vdotr), lerp(1.0, _SpecPowMax, specTexCol.a));
                float3 specColor = specTexCol.rgb*phong;
                float shadow = MainLightRealtimeShadow(TransformWorldToShadowCoord(i.positionWS));
                float3 directLightColor = (diffuseColor + specColor)*shadow;
                //光照模型(环境光照部分)
                float3 usdColor = color3Ambient(nDirWS);
                float3 envDiffuseColor = baseColor * usdColor * _EnvDiffInt;
                float fresnel = pow(max(0.0, 1.0 - vdotn), _FresnelPow);
                float3 envSpecColor = cubeMapCol.rgb * fresnel * _EnvSpecInt;
                float occlusion = mainTexCol.a; //遮挡信息单通道即可
                float3 envColor = (envDiffuseColor + envSpecColor)*occlusion;
                //光照模型(自发光部分)
                float emitInt = _EmitInt * (sin(frac(_Time.z)) * 0.5 + 0.5);
                float3 emiColor = emitTexCol.rgb * emitInt;
                //返回结果
                float3 finalColor = directLightColor + envColor + emiColor;
                return float4(finalColor,1);
            }

			ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
