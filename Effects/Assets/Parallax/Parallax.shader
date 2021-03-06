Shader "Effect/Parallax"
{
    Properties {
        _Albedo ("Albedo", 2D) = "white" {}
        [NoScaleOffset] _Normal ("Normal", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1
        [NoScaleOffset] _ParallaxMap ("Parallax", 2D) = "black" {}
        _ParallaxStrength ("Parallax Strength", Range(0, 0.1)) = 0
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
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 tangentWS : TEXCOORD2;
                float3 binormalWS : TEXCOORD3;
                float3 viewDirTS : TEXCOORD4;                
            };

            TEXTURE2D(_Albedo);
            SAMPLER(sampler_Albedo);
            TEXTURE2D(_Normal);
            SAMPLER(sampler_Normal);
            float _BumpScale;

            TEXTURE2D(_ParallaxMap);
            SAMPLER(sampler_ParallaxMap);
            float _ParallaxStrength;

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.tangentWS = TransformObjectToWorldDir(i.tangentOS.xyz);
                o.binormalWS = cross(o.normalWS, o.tangentWS) * i.tangentOS.w;

                o.uv = i.uv;
                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
                float3 viewDirWS = _WorldSpaceCameraPos - positionWS;
                // ?????????????????????,??????????????????????????????????????????,?????????????????? != ?????????????????????
                float3 viewDirOS = TransformWorldToObjectDir(viewDirWS, false);
                float3x3 objectToTangent = float3x3( i.tangentOS.xyz, cross(i.normalOS, i.tangentOS.xyz) * i.tangentOS.w, i.normalOS);
                o.viewDirTS = mul(objectToTangent, viewDirOS);
                return o;
            }

            float getParallaxHeight(float2 uv)
            {
                return SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, uv).r;
            }

            float2 parallaxOffset(float2 uv, float2 viewDir)
            {
                float height = getParallaxHeight(uv);
                height -= 0.5f;
                height *= _ParallaxStrength;
                return viewDir * height;
            }

            // https://www.jianshu.com/p/98c137baf855

            float2 parallaxSteep(float2 uv, float2 viewDir)
            {
                int stepCount = 10;
                float stepSize = 1.0/stepCount;
                float2 uvDelta = viewDir * stepSize * _ParallaxStrength;

                // ??????????????????
                // float2 uvOffset = viewDir * _ParallaxStrength;
                // float2 uvOffset = 0;
                float2 uvOffset = viewDir * _ParallaxStrength / 2; 
                int i = 0;

                for(; i<stepCount; ++i)
                {
                    uvOffset -= uvDelta;
                    float heightFromLayer = 1.0f - (i+1.0f)/stepCount;
                    float heightFromMap = getParallaxHeight(uv + uvOffset);
                    if(heightFromLayer < heightFromMap) break;
                }

                return uvOffset;
            }

            float2 parallaxOcclusion(float2 uv, float2 viewDir)
            {
                int stepCount = 10;
                float stepSize = 1.0/stepCount;
                float2 uvDelta = viewDir * stepSize * _ParallaxStrength;

                // ??????????????????
                // float2 uvOffset = viewDir * _ParallaxStrength;
                // float2 uvOffset = 0;
                float2 uvOffset = viewDir * _ParallaxStrength / 2; 
                int i = 0;

                for(; i<stepCount; ++i)
                {
                    uvOffset -= uvDelta;
                    float heightFromLayer = 1.0f - (i+1.0f)/stepCount;
                    float heightFromMap = getParallaxHeight(uv + uvOffset);
                    if(heightFromLayer < heightFromMap) break;
                }

                float a = 1.0f - i/stepCount;
                float b = 1.0f - (i+1.0f)/stepCount;
                float c = getParallaxHeight(uv + uvOffset + uvDelta);
                float d = getParallaxHeight(uv + uvOffset);
                float t = abs(a-c)/(abs(a-c)+abs(d-b));
                return uvOffset + (1-t)*uvDelta;

                // return uvOffset;
            }

            float2 parallaxRelief(float2 uv, float2 viewDir)
            {
                int stepCount = 10;
                float stepSize = 1.0/stepCount;
                float2 uvDelta = viewDir * stepSize * _ParallaxStrength;

                // ??????????????????
                // float2 uvOffset = viewDir * _ParallaxStrength;
                float2 uvOffset = 0;
                // float2 uvOffset = viewDir * _ParallaxStrength / 2; 
                int i = 0;

                for(; i<stepCount; ++i)
                {
                    uvOffset -= uvDelta;
                    float heightFromLayer = 1.0f - (i+1.0f)/stepCount;
                    float heightFromMap = getParallaxHeight(uv + uvOffset);
                    if(heightFromLayer < heightFromMap) break;
                }

                float heightFromLayer = 1.0f - (i+1.0f)/stepCount;
                i = 1;
                float binaryStep = 0.5f;
                int sign = 1;
                while(i < 10)
                {
                    uvDelta = uvDelta*0.5;
                    stepSize = stepSize*0.5;

                    uvOffset += uvDelta*sign;
                    heightFromLayer += stepSize*sign;

                    float heightFromMap = getParallaxHeight(uv + uvOffset);
                    if(heightFromMap < heightFromLayer)
                    {
                        sign = -1;
                    }
                    else
                    {
                        sign = 1;
                    }

                    i++;
                }

                return uvOffset;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                // i.viewDirTS = normalize(i.viewDirTS);
                i.viewDirTS.xy /= (i.viewDirTS.z + 0.001f);
                // float height = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, i.uv.xy).r;
                // height -= 0.5f;
                // height *= _ParallaxStrength;
                // i.uv.xy += i.viewDirTS.xy * height;

                // float2 offset = parallaxOffset(i.uv.xy, i.viewDirTS.xy);
                // float2 offset = parallaxSteep(i.uv.xy, i.viewDirTS.xy);
                // float2 offset = parallaxOcclusion(i.uv.xy, i.viewDirTS.xy);
                float2 offset = parallaxRelief(i.uv.xy, i.viewDirTS.xy);
                i.uv.xy += offset;

                // float4 normalTS = SAMPLE_TEXTURE2D(_Normal, sampler_Normal, i.uv);
                // float3 packedNormal = UnpackNormalScale(normalTS, _BumpScale);
                // float3x3 rotate = float3x3(i.TtoW1, i.TtoW2, i.TtoW3);
                // float3 normalWS = normalize(mul(rotate, packedNormal));


                float3 tangentSpaceNormal = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, i.uv), _BumpScale);
				float3 normalWS = normalize(
					tangentSpaceNormal.x * i.tangentWS +
					tangentSpaceNormal.y * i.binormalWS +
					tangentSpaceNormal.z * i.normalWS
				);

                Light light = GetMainLight();
                float3 ndotl = dot(normalWS, light.direction);
                float3 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, i.uv).rgb;
                float3 diffuse = albedo * max(0, ndotl).rgb;
                return float4(diffuse, 1);
            }

			ENDHLSL
        }
    }
}
