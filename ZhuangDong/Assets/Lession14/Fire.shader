Shader "Lession14/Fire"
{
    Properties {
        _MainTex ("MainTex", 2d) = "gray"{}
        _NoiseTex ("NoiseTex", 2d) = "gray"{}
        _Noise1Params   ("噪声1 X:大小 Y:流速 Z:强度", vector) = (1.0, 0.2, 0.2, 1.0)
        _Noise2Params   ("噪声1 X:大小 Y:流速 Z:强度", vector) = (1.0, 0.2, 0.2, 1.0)
        [HDR]_Color1    ("外焰颜色", color) = (1,1,1,1)
        [HDR]_Color2    ("内焰颜色", color) = (1,1,1,1)
	}

    SubShader
    {
        Tags {
            "Queue"="Transparent"
            "ForceNoShadowCasting"="True"       // 关闭阴影投射
            "IgnoreProjector"="True"            // 不响应投射器
        }

        Pass
        {
            Blend One OneMinusSrcAlpha

			HLSLPROGRAM
			#pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float2 uv1 : TEXCOORD2;         // UV信息 采样Noise1
                float2 uv2 : TEXCOORD3;         // UV信息 采样Noise2
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            CBUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Noise1Params)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Noise2Params)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color1)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color2)
            CBUFFER_END

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                o.uv1 = o.uv * _Noise1Params.x + float2(0.0, frac(_Time.x * _Noise1Params.y));
                o.uv2 = o.uv * _Noise2Params.x + float2(0.0, frac(_Time.x * _Noise2Params.y));
                return o;
            }

            // float2 uv1 = TRANSFORM_TEX((_NoiseTiling1*i.uv), _RampTex);

            float4 frag (v2f i) : SV_TARGET
            {
                // return float4(i.uv.x, i.uv.y, 0, 1);
                // 扰动遮罩
                float warpMask = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, TRANSFORM_TEX(i.uv, _MainTex) ).b;
                float var_Noise1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv1).r;
                float var_Noise2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv2).g;
                float noise = var_Noise1 * _Noise1Params.z + var_Noise2 * _Noise2Params.z;
                float2 warpUV = i.uv + float2(0.0, noise) * warpMask;
                float3 var_Mask = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, TRANSFORM_TEX(warpUV, _MainTex) );
                // return float4(var_Mask, 1);
                float3 color = _Color1 * var_Mask.r + _Color2 * var_Mask.g;
                float opacity = var_Mask.r + var_Mask.g;
                return float4(color, opacity);
            }

			ENDHLSL
        }
    }
}
