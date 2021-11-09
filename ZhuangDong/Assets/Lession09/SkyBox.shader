Shader "Lession09/SkyBox"
{
    Properties {
        _CubemapMip ("CubeMapMip", Range(0, 7)) = 0
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
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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
            };

            CBUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _CubemapMip)
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
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 rvDir = reflect(-viewDir, i.normalWS);
                float4 texColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, rvDir, _CubemapMip);
                float3 color = DecodeHDREnvironment(texColor, unity_SpecCube0_HDR);
                // float3 color = texColor.rgb;
                return float4(color, 1);
            }

			ENDHLSL
        }
    }
}
