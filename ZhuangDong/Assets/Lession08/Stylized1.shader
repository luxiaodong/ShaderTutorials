Shader "Lession08/Stylized1"
{
    Properties {
		_RampTex ("RampTex", 2D) = "white" {}
        _FresnelCol ("FresnelCol", Color) = (0.7505785,0.9463587,0.9528302,1)
        _FresnelPow ("FresnelPow", Range(0, 20)) = 5
        _SpecPow ("SpecPow", Range(1, 90)) = 1
        _MainCol ("MainCol", Color) = (0.1792453,0.1581079,0.1593877,1)
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
                float3 normalWS : TEXCOORD1;
            };

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

            CBUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _FresnelCol)
                UNITY_DEFINE_INSTANCED_PROP(float, _FresnelPow)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainCol)
                UNITY_DEFINE_INSTANCED_PROP(float, _SpecPow)
            CBUFFER_END

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                return o;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                //向量
                Light light = GetMainLight();
                float3 lightDir = light.direction;
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 halfDir = normalize(viewDir + lightDir);
                float3 refDir = reflect(-lightDir, i.normalWS);

                //点乘
                float ndotl = dot(i.normalWS, light.direction);
                float ndoth = dot(i.normalWS, halfDir);
                float U = pow( max(0, ndoth), _SpecPow );

                //菲尼尔
                float fresnel = (1.0-max(0,dot(i.normalWS, viewDir)));
                fresnel = pow(fresnel, _FresnelPow);

                //颜色
                float3 diffuse = _MainCol*max(0,ndotl);
                float3 texColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(U, 0.2));
                float3 specular = lerp(texColor, _FresnelCol.rgb, fresnel*i.normalWS.g );
                float3 color = diffuse + specular;
                return float4(color, 1.0);
            }

			ENDHLSL
        }
    }
}
