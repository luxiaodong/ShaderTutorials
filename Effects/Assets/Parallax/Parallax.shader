Shader "Effect/Parallax"
{
    Properties {
        _Albedo ("Albedo", 2D) = "white" {}
        [NoScaleOffset] _Normal ("Normal", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1
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
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 TtoW1:TEXCOORD3;
				float3 TtoW2:TEXCOORD4;
				float3 TtoW3:TEXCOORD5;
            };

            TEXTURE2D(_Albedo);
            SAMPLER(sampler_Albedo);
            TEXTURE2D(_Normal);
            SAMPLER(sampler_Normal);
            float _BumpScale;

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
                float4 normalTS = SAMPLE_TEXTURE2D(_Normal, sampler_Normal, i.uv);
                // float3 packedNormal = UnpackNormal(normalTS);
                float3 packedNormal = UnpackNormalScale(normalTS, _BumpScale);

                float3x3 rotate = float3x3(i.TtoW1, i.TtoW2, i.TtoW3);
                float3 normalWS = normalize(mul(rotate, packedNormal));

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
