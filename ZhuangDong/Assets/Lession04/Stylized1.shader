Shader "Lession04/Stylized1"
{
    Properties {
		_RampTex ("RampTex", 2D) = "white" {}
        _DispersionColor ("DispersionColor 色散频率", Color) = (0.5,0.5,0.5,1)
        _DispersionPower ("_DispersionPower 色散强度", Range(0, 1)) = 0.5816852
        _LightColor ("LightCol 亮部颜色", Color) = (0.7169812,0.7000712,0.7000712,1)
        _DarkColor ("DarkCol 暗部颜色", Color) = (0.7169812,0.7000712,0.7000712,1)
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
                UNITY_DEFINE_INSTANCED_PROP(float4, _DispersionColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _DispersionPower)
                UNITY_DEFINE_INSTANCED_PROP(float4, _LightColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _DarkColor)
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
                float3 maskColor = _DispersionPower*_DispersionColor;
                float3 mask = step(maskColor, ndotl);

                float vmax = max(max(mask.r, mask.g), mask.b);
                float vmin = min(min(mask.r, mask.g), mask.b);

                // float3 color = texColor*mask;
                // color = lerp(_DarkColor, color, vmax);
                // color = lerp(color, _LightColor, vmin);
                // return float4(color,1);

                float3 color = lerp(texColor, mask, vmin);
                color = mask*color;
                color = lerp(_DarkColor, color, vmax);
                color = lerp(color, _LightColor, vmin);
                return float4(color,1);
            }

			ENDHLSL
        }
    }
}
