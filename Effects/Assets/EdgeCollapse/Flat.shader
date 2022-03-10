Shader "EdgeCollapse/Flat"
{
    Properties {
	}

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
			HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geome

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

            struct v2g
            {
                v2f data;
                float3 barycentricCoordinates : TEXCOOR4;
            };

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            [maxvertexcount(3)]
            void geome(triangle v2f i[3], inout TriangleStream<v2f> stream)
            {
                float3 p0 = i[0].positionWS.xyz;
                float3 p1 = i[1].positionWS.xyz;
                float3 p2 = i[2].positionWS.xyz;
                float3 triangleNormal = normalize( cross(p1-p0, p2-p0) );
                i[0].normalWS = triangleNormal;
                i[1].normalWS = triangleNormal;
                i[2].normalWS = triangleNormal;
            
                stream.Append(i[0]);
                stream.Append(i[1]);
                stream.Append(i[2]);
                stream.RestartStrip();
            }


            float4 frag (v2f i) : SV_TARGET 
            {

                //世界坐标系下的偏导数
                float3 dpdx = ddx(i.positionWS);
                float3 dpdy = ddy(i.positionWS);
                float3 normal = cross(dpdx, dpdy);

                // return float4( normalize(normal) , 1.0f);
                return float4( normalize(i.normalWS.xyz) , 1.0f);
            }

			ENDHLSL
        }
    }
}

