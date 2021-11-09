Shader "Lession09/CubeMap"
{
    Properties {
		_NormalTex ("NormalMap", 2D) = "white" {}
        _Cubemap   ("CubeMap", Cube) = "_Skybox" {}
        _CubemapMip ("CubeMapMip", Range(0, 7)) = 0
        _FresnelPower ("FresnelPower", Range(0,10)) = 0
        _EnvSpecular ("EnvSpecular", Range(0,5)) = 1
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
                float3 TtoW1:TEXCOORD3;
				float3 TtoW2:TEXCOORD4;
				float3 TtoW3:TEXCOORD5;
            };

            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);

            TEXTURECUBE(_Cubemap);
            SAMPLER(sampler_Cubemap);

            CBUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _FresnelPower)
                UNITY_DEFINE_INSTANCED_PROP(float, _EnvSpecular)
                UNITY_DEFINE_INSTANCED_PROP(float, _CubemapMip)
            CBUFFER_END

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.uv = i.uv;

                float3 normalWS = TransformObjectToWorldNormal(i.normalOS);
                float3 tangentWS = normalize(TransformObjectToWorld(i.tangentOS));
                float3 binormalWS = normalize(cross(normalWS, tangentWS))*i.tangentOS.z;

                o.TtoW1 = float3(tangentWS.x, binormalWS.x, normalWS.x);
                o.TtoW2 = float3(tangentWS.y, binormalWS.y, normalWS.y);
                o.TtoW3 = float3(tangentWS.z, binormalWS.z, normalWS.z);
                return o;
            }

            float4 frag (v2f i) : SV_TARGET
            {
                float4 normalTS = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv);
                float3 packedNormal = UnpackNormal(normalTS);
                float3x3 rotate = float3x3(i.TtoW1, i.TtoW2, i.TtoW3);
                float3 normalWS = mul(rotate, packedNormal);

                float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 rvDir = reflect(-viewDir, normalWS);
                float3 texColor = SAMPLE_TEXTURECUBE_LOD(_Cubemap, sampler_Cubemap, rvDir, _CubemapMip);

                // float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                float power = pow(1.0-max(0, dot(normalWS,viewDir)), _FresnelPower);
                float3 color = texColor*power*_EnvSpecular;

                return float4(color,1);
            }

			ENDHLSL
        }
    }
}
