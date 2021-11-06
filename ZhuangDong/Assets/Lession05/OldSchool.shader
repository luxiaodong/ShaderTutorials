Shader "Lession05/OldSchool"
{
    Properties {
        _MainColor ("颜色", color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularPow ("高光次幂", range(1, 90)) = 30
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

            CBUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _SpecularPow)
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
                float3 ndotl = dot(i.normalWS, light.direction);
                float3 ndoth = dot(i.normalWS, halfDir);
                float3 vdotr = dot(viewDir, refDir);

                //各项
                float3 diffuse = _MainColor*max(0, ndotl).rgb;
                // float3 specular = pow( max(0, ndoth), _SpecularPow );
                float3 specular = pow( max(0, vdotr), _SpecularPow );
                float3 color = diffuse + specular;
                return float4(color,1);
            }

			ENDHLSL
        }
    }
}
