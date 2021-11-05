Shader "Lession04/Stylized2"
{
    Properties {
        _DarkColor ("DarkCol 暗部颜色", Color) = (0.7169812,0.7000712,0.7000712,1)
        _LightColor ("LightCol 亮部颜色", Color) = (0.7169812,0.7000712,0.7000712,1)
        _SpecColor ("SpecCol 高光颜色", Color) = (0.5,0.5,0.5,1)
        _SpecPower ("SpecPower 高光次幂", Range(1, 90)) = 30

        _RampTex ("RampTex", 2D) = "white" {}
        _NoisePower ("NoisePower 噪点强度", Range(-1, 1)) = 0
        _NoiseTiling1 ("NoiseTiling1 噪点缩放1", Float ) = 1
        _NoiseTiling2 ("NoiseTiling2 噪点缩放2", Float ) = 10
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
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

            CBUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _LightColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _DarkColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _SpecColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _SpecPower)
                UNITY_DEFINE_INSTANCED_PROP(float4, _RampTex_ST)

                UNITY_DEFINE_INSTANCED_PROP(float, _NoisePower)
                UNITY_DEFINE_INSTANCED_PROP(float, _NoiseTiling1)
                UNITY_DEFINE_INSTANCED_PROP(float, _NoiseTiling2)
            CBUFFER_END

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.uv = i.uv;
                return o;
            }

            float3 blend_overlay(float3 color1, float3 color2)
            {
                return saturate(lerp( 2*color1*color2, 1-2.0*(1-color1)*(1-color2), step(0.5, color2) ));
                // return saturate(( color2.rgb > 0.5 ? (1.0-(1.0-2.0*(color1.rgb-0.5))*(1.0-color2.rgb)) : (2.0*color1.rgb*color2.rgb) ));
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                float2 uv1 = TRANSFORM_TEX((_NoiseTiling1*i.uv), _RampTex);
                float2 uv2 = TRANSFORM_TEX((_NoiseTiling2*i.uv), _RampTex);
                float3 noiseColor1 = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, uv1).rgb;
                float3 noiseColor2 = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, uv2).rgb;
                float3 noiseColor = lerp( float3(0.5,0.5,0.5), noiseColor1*noiseColor2, _NoisePower);

                Light light = GetMainLight();
                float ndotl = dot(i.normalWS, light.direction);
                float3 diffColor = lerp(_DarkColor, _LightColor, step(0,ndotl));

                float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 halfDir = normalize(viewDir + normalize(light.direction));
                float3 specColor = pow( max(0, dot(i.normalWS, halfDir)), _SpecPower); //_SpecColor

                float3 temp1 = blend_overlay(specColor, noiseColor);
                float3 temp2 = blend_overlay(noiseColor, max(0, ndotl) );
                float3 temp3 = lerp( _DarkColor, _LightColor, round(temp2) );
                float3 temp4 = lerp(temp3, _SpecColor, round(temp1) );

                return float4(temp4, 1);
            }

			ENDHLSL
        }
    }
}
