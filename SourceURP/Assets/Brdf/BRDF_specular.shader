Shader "Custom/BRDF/BRDF_specular"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _SpecGlossMap("Specular", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Scale", Float) = 1.0
    }

    SubShader
    {
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vertex
            #pragma fragment frag

            #pragma shader_feature _NORMALMAP

            // -------#include "LitInput.hlsl" begin-----------
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _Smoothness;
                half _BumpScale;
            CBUFFER_END

            struct a2v
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);

            struct v2f
            {
                float4 positionCS               : SV_POSITION;
                float2 uv                       : TEXCOORD0;
                float3 positionWS               : TEXCOORD2;
                float3 normalWS                 : TEXCOORD3;
                float4 tangentWS                : TEXCOORD4;
                float3 viewDirWS                : TEXCOORD5;
                float4 shadowCoord              : TEXCOORD7;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            v2f vertex(a2v i)
            {
                v2f v = (v2f)0;

                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(v);

                v.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                v.viewDirWS = GetCameraPositionWS() - v.positionWS;
                v.positionCS = TransformWorldToHClip(v.positionWS);
                v.normalWS =  TransformObjectToWorldNormal(i.normalOS);
                v.tangentWS.xyz = TransformObjectToWorldDir(i.tangentOS.xyz);
                v.tangentWS.a = i.tangentOS.w*GetOddNegativeScale();
                v.uv = TRANSFORM_TEX(i.texcoord, _BaseMap);
                v.shadowCoord = float4(0, 0, 0, 0);
                return v;
            }

            // https://www.zhihu.com/question/48050245
            // 法线分布函数
            half factor_d_ggx_unity(half3 n, half3 h, half r)
            {
                // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
                half ndoth = saturate(dot(n, h));
                half2 r2 = r*r;
                half ndoth2 = ndoth*ndoth;
                half denom = ndoth2*(r2 - 1.0f) + 1.00001f;
                return r2/(denom*denom);
            }

            // http://www.thetenthplanet.de/archives/255
            // V*F, v means geometric visibility factor
            half factor_vf_unity(half3 l, half3 h, half r)
            {
                //V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
                // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
                // https://community.arm.com/events/1155

                half ldoth = saturate(dot(l, h));
                half ldoth2 = max(0.1h, ldoth*ldoth);
                half denom = ldoth2*(r + 0.5f);
                return 1.0/denom;
            }

            half brdf_unity(half3 n, half3 l, half3 v, half r)
            {
                //BRDFspec = (D * V * F) / 4.0
                half3 h = SafeNormalize(l+v);
                return factor_d_ggx_unity(n,h,r)*factor_vf_unity(l,h,r)/4.0f;
            }

            half factor_g(half3 n, half3 l, half3 v, half r)
            {
                half k = (r+1)*(r+1)/8.0; // r*r/2.0
                half ndotv = saturate(dot(n, v));
                half ndotl = saturate(dot(n, l));
                float g1 = ndotv/(ndotv*(1-k)+k);
                float g2 = ndotl/(ndotl*(1-k)+k);
                return g1*g2;
            }

            half3 factor_f(half3 f0, half3 v, half3 h)
            {
                half vdoth = saturate(dot(v, h));
                return f0 + (1-f0)*pow(1-vdoth, 5);
            }
            
            half3 brdf_standard(half3 n, half3 l, half3 v, half r, half3 f0)
            {
                half3 h = SafeNormalize(l+v);
                half d = factor_d_ggx_unity(n,h,r)/3.1415926;
                half g = factor_g(n,l,v,r);
                half3 f = factor_f(f0, v, h);

                half ndotl = saturate(dot(n, l));
                half ndotv = saturate(dot(n, v));
                float denom = 4.0*ndotl*ndotv + 0.00001f;
                return d*g*f/denom;
            }

            half4 brdf(InputData inputData, SurfaceData surfaceData)
            {
                BRDFData brdfData;
                half reflectivity = ReflectivitySpecular(surfaceData.specular);
                half oneMinusReflectivity = 1.0 - reflectivity;
                brdfData.diffuse = surfaceData.albedo * (half3(1.0h, 1.0h, 1.0h) - surfaceData.specular);
                brdfData.specular = surfaceData.specular;

                brdfData.grazingTerm = saturate(surfaceData.smoothness + reflectivity);
                brdfData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surfaceData.smoothness);
                brdfData.roughness = max(PerceptualRoughnessToRoughness(brdfData.perceptualRoughness), HALF_MIN);
                brdfData.roughness2 = brdfData.roughness * brdfData.roughness;
                brdfData.normalizationTerm = brdfData.roughness * 4.0h + 2.0h;
                brdfData.roughness2MinusOne = brdfData.roughness2 - 1.0h;

                Light light = GetMainLight(inputData.shadowCoord);
                half specularTerm = brdf_unity(inputData.normalWS, light.direction, inputData.viewDirectionWS, brdfData.roughness);
                // half3 specularTerm = brdf_standard(inputData.normalWS, light.direction, inputData.viewDirectionWS, brdfData.roughness, brdfData.specular);
                half3 brdfColor = specularTerm * brdfData.specular + brdfData.diffuse;
    
                // half3 brdfColor = DirectBDRF(brdfData, inputData.normalWS, light.direction, inputData.viewDirectionWS);

                half ndotl = saturate(dot(inputData.normalWS, light.direction));
                half attenuation = light.distanceAttenuation*light.shadowAttenuation;
                half3 color = brdfColor*light.color*attenuation*ndotl;
                //half3 color = LightingPhysicallyBased(brdfData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, inputData.normalWS, inputData.viewDirectionWS);
                //half3 color = LightingPhysicallyBased(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS);
                return half4(color, surfaceData.alpha);

                //half4 color = UniversalFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);
                //return color;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                half4 specGloss = SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, i.uv);

                SurfaceData surfaceData;
                surfaceData = (SurfaceData)0;
                half4 albedoAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                surfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
                surfaceData.alpha = _BaseColor.a;
                surfaceData.normalTS = SampleNormal(i.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
                surfaceData.metallic = 1.0f;
                surfaceData.smoothness = specGloss.a*_Smoothness;
                surfaceData.specular = specGloss.rgb;
                surfaceData.occlusion = 1.0f;
                surfaceData.emission = 0.0f;

                float sgn = i.tangentWS.w;      // should be either +1 or -1
                float3 bitangent = sgn * cross(i.normalWS.xyz, i.tangentWS.xyz);
                float3 normalWS = TransformTangentToWorld(surfaceData.normalTS, half3x3(i.tangentWS.xyz, bitangent.xyz, i.normalWS.xyz));

                InputData inputData;
                inputData = (InputData)0;
                inputData.positionWS = i.positionWS;
                inputData.normalWS = normalize(normalWS);
                inputData.viewDirectionWS = SafeNormalize(i.viewDirWS);
                inputData.shadowCoord = float4(0, 0, 0, 0);
                inputData.fogCoord = 0.0f;
                inputData.vertexLighting = half3(0.0f, 0.0f, 0.0f);
                inputData.bakedGI = 0.0f;

                return brdf(inputData, surfaceData);
            }

            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
