Shader "EdgeCollapse/Displacement"
{
    Properties {
        _Albedo ("Albedo", 2D) = "white" {}
        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1
        _Factor ("Factor", Range(1,32)) = 1 
        _DisplacementMap ("Displacement", 2D) = "white" {}
        _DisplacementStrength ("Displacement Strength", Range(0, 1)) = 0.1
	}

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            Tags{"LightMode" = "SRPDefaultUnlit"}

            HLSLPROGRAM
            #pragma target 4.6
            #pragma require geometry
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull tessHull
            #pragma domain tessDomain

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v {
                float4 positionOS : POSITION;
                float4 tangentOS : TANGENT;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2t {
                float4 positionOS : INTERNALTESSPOS;
                float4 tangentOS : TANGENT;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD1;
            };

            struct t2f {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 binormalWS : TEXCOORD4;
            };

            struct tessFactor
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            TEXTURE2D(_Albedo);
            SAMPLER(sampler_Albedo);
            TEXTURE2D(_Normal);
            SAMPLER(sampler_Normal);
            sampler2D _DisplacementMap;

            float3 _WireColor;
            float _WireWidth;
            float _Factor;
            float _DisplacementStrength;
            float _BumpScale;

            v2t vert(a2v i)
            {
                v2t o;
                o.positionOS = i.positionOS;
                o.tangentOS = i.tangentOS;
                o.normalOS = i.normalOS;
                o.uv = i.uv;
                return o;
            }

            tessFactor patchConstant (InputPatch<v2t, 3> patch) 
            {
                tessFactor f;
                f.edge[0] = _Factor;
                f.edge[1] = _Factor;
                f.edge[2] = _Factor;
                f.inside = _Factor;
                return f;
            }

            [domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("fractional_odd")]
            [patchconstantfunc("patchConstant")]
            v2t tessHull(InputPatch<v2t, 3> patch, uint id : SV_OutputControlPointID) 
            {
                return patch[id];
            }

            [domain("tri")]
            t2f tessDomain( tessFactor factors, OutputPatch<v2t, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) 
            {
                t2f o;
                float2 uv = float2(0,0);
                uv += patch[0].uv * barycentricCoordinates.x;
                uv += patch[1].uv * barycentricCoordinates.y;
                uv += patch[2].uv * barycentricCoordinates.z;

                float3 normalOS = float3(0,0,0);
                normalOS += patch[0].normalOS * barycentricCoordinates.x;
                normalOS += patch[1].normalOS * barycentricCoordinates.y;
                normalOS += patch[2].normalOS * barycentricCoordinates.z;
                normalOS = normalize(normalOS);

                float4 tangentOS = float4(0,0,0,0);
                tangentOS += patch[0].tangentOS * barycentricCoordinates.x;
                tangentOS += patch[1].tangentOS * barycentricCoordinates.y;
                tangentOS += patch[2].tangentOS * barycentricCoordinates.z;

                float3 positionOS = float3(0,0,0);
                positionOS += patch[0].positionOS.xyz * barycentricCoordinates.x;
                positionOS += patch[1].positionOS.xyz * barycentricCoordinates.y;
                positionOS += patch[2].positionOS.xyz * barycentricCoordinates.z;

                float displacement = tex2Dlod(_DisplacementMap, float4(uv, 0, 0)).g;
                displacement = (displacement - 0.5f) * _DisplacementStrength;
                positionOS.xyz += normalOS * displacement;

                o.positionWS = TransformObjectToWorld(positionOS);
                o.positionCS = TransformObjectToHClip(positionOS);
                o.normalWS = TransformObjectToWorldNormal(normalOS);
                o.tangentWS = TransformObjectToWorldDir(tangentOS.xyz);
                o.binormalWS = cross(o.normalWS, o.tangentWS) * tangentOS.w;
                o.uv = uv;
                return o;
            }

            float4 frag (t2f i) : SV_TARGET 
            {
                float3 tangentSpaceNormal = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, i.uv), _BumpScale);

                float3 normalWS = normalize(
                    tangentSpaceNormal.x * i.tangentWS +
                    tangentSpaceNormal.y * i.binormalWS +
                    tangentSpaceNormal.z * i.normalWS
                );

                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);

                Light light = GetMainLight(shadowCoord);
                float3 ndotl = dot(normalWS, light.direction);
                float3 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, i.uv);
                float3 diffuse = albedo * light.shadowAttenuation;  // max(0, ndotl).rgb

//    diffuse = float3(light.shadowAttenuation, light.shadowAttenuation, light.shadowAttenuation);

                return float4(diffuse, 1);
            }

            ENDHLSL
        }



        Pass
        {
            Tags{"LightMode" = "ShadowCaster"}

            HLSLPROGRAM
            #pragma target 4.6
            #pragma require geometry
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull tessHull
            #pragma domain tessDomain

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v {
                float4 positionOS : POSITION;
                float4 tangentOS : TANGENT;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2t {
                float4 positionOS : INTERNALTESSPOS;
                float4 tangentOS : TANGENT;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD1;
            };

            struct t2f {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 tangentWS : TEXCOORD2;
                float3 binormalWS : TEXCOORD3;
            };

            struct tessFactor
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            TEXTURE2D(_Albedo);
            SAMPLER(sampler_Albedo);
            TEXTURE2D(_Normal);
            SAMPLER(sampler_Normal);
            sampler2D _DisplacementMap;

            float3 _WireColor;
            float _WireWidth;
            float _Factor;
            float _DisplacementStrength;
            float _BumpScale;

            v2t vert(a2v i)
            {
                v2t o;
                o.positionOS = i.positionOS;
                o.tangentOS = i.tangentOS;
                o.normalOS = i.normalOS;
                o.uv = i.uv;
                return o;
            }

            tessFactor patchConstant (InputPatch<v2t, 3> patch) 
            {
                tessFactor f;
                f.edge[0] = _Factor;
                f.edge[1] = _Factor;
                f.edge[2] = _Factor;
                f.inside = _Factor;
                return f;
            }

            [domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("fractional_odd")]
            [patchconstantfunc("patchConstant")]
            v2t tessHull(InputPatch<v2t, 3> patch, uint id : SV_OutputControlPointID) 
            {
                return patch[id];
            }

            [domain("tri")]
            t2f tessDomain( tessFactor factors, OutputPatch<v2t, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) 
            {
                t2f o;
                float2 uv = float2(0,0);
                uv += patch[0].uv * barycentricCoordinates.x;
                uv += patch[1].uv * barycentricCoordinates.y;
                uv += patch[2].uv * barycentricCoordinates.z;

                float3 normalOS = float3(0,0,0);
                normalOS += patch[0].normalOS * barycentricCoordinates.x;
                normalOS += patch[1].normalOS * barycentricCoordinates.y;
                normalOS += patch[2].normalOS * barycentricCoordinates.z;
                normalOS = normalize(normalOS);

                float4 tangentOS = float4(0,0,0,0);
                tangentOS += patch[0].tangentOS * barycentricCoordinates.x;
                tangentOS += patch[1].tangentOS * barycentricCoordinates.y;
                tangentOS += patch[2].tangentOS * barycentricCoordinates.z;

                float3 positionOS = float3(0,0,0);
                positionOS += patch[0].positionOS.xyz * barycentricCoordinates.x;
                positionOS += patch[1].positionOS.xyz * barycentricCoordinates.y;
                positionOS += patch[2].positionOS.xyz * barycentricCoordinates.z;

                float displacement = tex2Dlod(_DisplacementMap, float4(uv, 0, 0)).g;
                displacement = (displacement - 0.5f) * _DisplacementStrength;
                positionOS.xyz += normalOS * displacement;

                o.positionCS = TransformObjectToHClip(positionOS);
                o.normalWS = TransformObjectToWorldNormal(normalOS);
                o.tangentWS = TransformObjectToWorldDir(tangentOS.xyz);
                o.binormalWS = cross(o.normalWS, o.tangentWS) * tangentOS.w;
                o.uv = uv;
                return o;
            }

            float4 frag (t2f i) : SV_TARGET 
            {
                return float4(1, 1, 1, 1);
            }

            ENDHLSL
        }
    }
}

