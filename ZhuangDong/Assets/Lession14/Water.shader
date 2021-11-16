Shader "Lession14/Water"
{
    Properties {
        _MainTex ("MainTex", 2D) = "gray"{}
        _Speed ("X：流速X Y：流速Y", Vector) = (1.0, 1.0, 0.5, 1.0)
        _WarpTex ("扰动图", 2D) = "gray"{}
        _Warp1Params    ("X：大小 Y：流速X Z：流速Y W：强度", vector) = (1.0, 1.0, 0.5, 1.0)
        _Warp2Params    ("X：大小 Y：流速X Z：流速Y W：强度", vector) = (1.0, 1.0, 0.5, 1.0)
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
			HLSLPROGRAM
			#pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 warpUV : TEXCOORD1;
            };

            struct v2f {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float4 warpUV : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_WarpTex);
            SAMPLER(sampler_WarpTex);

            CBUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Speed)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Warp1Params)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Warp2Params)
            CBUFFER_END

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv - frac(_Time.x * _Speed);
                o.warpUV.xy = i.uv * _Warp1Params.x - frac(_Time.x * _Warp1Params.yz);
                o.warpUV.zw = i.uv * _Warp2Params.x - frac(_Time.x * _Warp2Params.yz);
                return o;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                float3 wrap1 = SAMPLE_TEXTURE2D(_WarpTex, sampler_WarpTex, i.warpUV.xy);
                float3 wrap2 = SAMPLE_TEXTURE2D(_WarpTex, sampler_WarpTex, i.warpUV.wz);
                half2 warp = (wrap1.xy - 0.5) * _Warp1Params.w + (wrap2.xy - 0.5) * _Warp2Params.w;
                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv+warp);
                return color;
            }

			ENDHLSL
        }
    }
}
