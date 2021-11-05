Shader "Tutorials/RenderPipeline/Chapter3/FakeLight"
{
    Properties {
        _Diffuse ("Diffuse", 2D) = "white" {}
        [MaterialToggle] _LightSwitch ("LightSwitch", Float) = 1
        _LightDir ("LightDir", Vector) = (0.5,0.5,0.5,1)
        _LightColor ("LightColor", Color) = (0.6933962,0.9671069,1,1)
        _LightPower ("LightPower", Range(0, 2)) = 1.295701
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

            TEXTURE2D(_Diffuse);
            SAMPLER(sampler_Diffuse);

            CBUFFER_START(UnityPerMaterial)
	            UNITY_DEFINE_INSTANCED_PROP(float, _LightSwitch)
	            UNITY_DEFINE_INSTANCED_PROP(float4, _LightDir)
                UNITY_DEFINE_INSTANCED_PROP(float4, _LightColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _LightPower)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Diffuse_ST)
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

            float4 frag (v2f i) : SV_TARGET 
            {
                float3 diffuse = SAMPLE_TEXTURE2D(_Diffuse, sampler_Diffuse, TRANSFORM_TEX(i.uv, _Diffuse) );
                float ndotl = dot(i.normalWS, normalize(_LightDir.xyz))*0.5+0.5;
                float3 lightColor = _LightPower*ndotl*_LightColor;
                float3 color = lerp(diffuse, lightColor*diffuse, _LightSwitch);
                return float4(color,1);
            }

			ENDHLSL
        }
    }
}
