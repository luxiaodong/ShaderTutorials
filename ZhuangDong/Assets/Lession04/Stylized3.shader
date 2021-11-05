Shader "Lession04/Stylized3"
{
    Properties {
		_RampTex ("RampTex", 2D) = "white" {}
        _Threshold1 ("_Threshold1", Range(-1, 1)) = -0.5
        _Threshold2 ("_Threshold2", Range(-1, 1)) = 0
        _Threshold3 ("_Threshold3", Range(-1, 1)) = 0.5
        _Color1 ("_Color1", Color) = (0,0,0,1)
        _Color2 ("_Color2", Color) = (0,0,1,1)
        _Color3 ("_Color3", Color) = (0,1,1,1)
        _Color4 ("_Color4", Color) = (1,1,1,1)
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
            };

            struct v2f {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float4 positionSS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

            CBUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _Threshold1)
                UNITY_DEFINE_INSTANCED_PROP(float, _Threshold2)
                UNITY_DEFINE_INSTANCED_PROP(float, _Threshold3)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color1)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color2)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color3)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color4)
                UNITY_DEFINE_INSTANCED_PROP(float4, _RampTex_ST)
            CBUFFER_END

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.positionSS = ComputeScreenPos(o.positionCS);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.positionSS.z = -TransformWorldToView(o.positionWS).z;
                return o;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                float2 screenUV = i.positionSS.xy/i.positionSS.w;
                screenUV = float2(screenUV.x*(_ScreenParams.r/_ScreenParams.g), screenUV.y).rg;
                float partZ = max(0, i.positionSS.z - _ProjectionParams.g);
                screenUV = screenUV*partZ;
                float3 texColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, TRANSFORM_TEX(screenUV, _RampTex)).rgb;

                Light light = GetMainLight();
                float ndotl = dot(i.normalWS, light.direction);
                float3 color = _Color1;
                color = lerp(color, _Color2, step(_Threshold1, ndotl));
                color = lerp(color, _Color3*texColor, step(_Threshold2, ndotl));
                color = lerp(color, _Color4, step(_Threshold3, ndotl));
                return float4(color,1);
            }

			ENDHLSL
        }
    }
}
