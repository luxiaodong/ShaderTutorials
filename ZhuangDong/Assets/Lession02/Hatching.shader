Shader "Lession02/Hatching"
{
    Properties {
		_RampTex ("RampTex", 2D) = "white" {}
        _Dark ("Dark", Color) = (0.5,0.5,0.5,1)
        _Light ("Light", Color) = (0.5,0.5,0.5,1)
        _Multiplycolor ("multiply color", Color) = (0.5,0.5,0.5,1)
	}

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}

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
            // UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	            UNITY_DEFINE_INSTANCED_PROP(float4, _Dark)
	            UNITY_DEFINE_INSTANCED_PROP(float4, _Light)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Multiplycolor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _RampTex_ST)
            // UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
            CBUFFER_END

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.positionSS = ComputeScreenPos(o.positionCS);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                // 需要转到相机空间
                o.positionSS.z = -TransformWorldToView(o.positionWS).z;
                return o;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                Light light = GetMainLight();
                float ndotl = dot(normalize(i.normalWS), light.direction);
                float2 screenUV = i.positionSS.xy/i.positionSS.w; // 0-1
                //这步操作包保证不受屏幕宽高比影响
                // screenUV = float2(screenUV.x * (_ScreenParams.r/_ScreenParams.g), screenUV.y).rg;
                screenUV = float2((screenUV.x * 2 - 1)*(_ScreenParams.r/_ScreenParams.g), screenUV.y * 2 - 1).rg;
                float partZ = max(0, i.positionSS.z - _ProjectionParams.g);
                screenUV = screenUV*partZ;
                float4 tex = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, TRANSFORM_TEX(screenUV, _RampTex) );
                float4 color = lerp(_Dark, _Light, step(tex.r, ndotl)) + ndotl*_Multiplycolor;
                return float4(color.rgb, 1);
            }

			ENDHLSL
        }
    }
}
