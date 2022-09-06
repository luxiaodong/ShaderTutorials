Shader "EdgeCollapse/PNTriangles"
{
    Properties {
        _WireColor ("WireColor", Color) = (0,0,0)
        _WireWidth ("WireWidth", Range(1,5)) = 1
	}

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            Tags{"LightMode" = "SRPDefaultUnlit"}

			HLSLPROGRAM
            #pragma target 4.6
            #pragma require geometry
            #pragma vertex vert
            #pragma geometry geome
            #pragma fragment frag
            #pragma hull tessHull
            #pragma domain tessDomain

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v 
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct v2t
            {
                float4 positionOS : INTERNALTESSPOS;
                float3 normalOS : NORMAL;
            };

            struct t2g
            {
                float4 positionCS : SV_POSITION;
            };

            struct g2f
            {
                float4 positionCS : SV_POSITION;
                float3 barycentricCoordinates : TEXCOOR0;
            };

            struct tessFactor
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            float3 _WireColor;
            float _WireWidth;

            v2t vert(a2v i)
            {
                v2t o;
                o.positionOS = i.positionOS;
                o.normalOS = i.normalOS;
                return o;
            }

            tessFactor patchConstant (InputPatch<v2t, 3> patch) 
            {
                tessFactor f;
                f.edge[0] = 3;
                f.edge[1] = 3;
                f.edge[2] = 3;
                f.inside = 3;
                return f;
            }

            [domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("fractional_odd")]
            [patchconstantfunc("patchConstant")]
            v2t tessHull(InputPatch<v2t, 3> patch, uint id : SV_OutputControlPointID) 
            {
                return patch[id];
            }

            [domain("tri")]
            t2g tessDomain( tessFactor factors, OutputPatch<v2t, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) 
            {
                t2g o;
                float3 positionOS = float3(0,0,0);
                positionOS += patch[0].positionOS.xyz * barycentricCoordinates.x;
                positionOS += patch[1].positionOS.xyz * barycentricCoordinates.y;
                positionOS += patch[2].positionOS.xyz * barycentricCoordinates.z;

                o.positionCS = TransformObjectToHClip(positionOS);
                return o;
            }

            [maxvertexcount(3)]
            void geome(triangle t2g i[3], inout TriangleStream<g2f> stream)
            {
                g2f g0,g1,g2;
                g0.positionCS = i[0].positionCS;
                g1.positionCS = i[1].positionCS;
                g2.positionCS = i[2].positionCS;
                g0.barycentricCoordinates = float3(1,0,0);
                g1.barycentricCoordinates = float3(0,1,0);
                g2.barycentricCoordinates = float3(0,0,1);

                stream.Append(g0);
                stream.Append(g1);
                stream.Append(g2);
                stream.RestartStrip();
            }

            float4 frag (g2f i) : SV_TARGET 
            {
                float minBary = min(i.barycentricCoordinates.x , min(i.barycentricCoordinates.y, i.barycentricCoordinates.z));
                float delta = fwidth(minBary);
                float c = smoothstep(0, delta*_WireWidth, minBary);
                float3 color = lerp(_WireColor, float3(1,1,1), c);
                return float4(color, 1.0);
            }

			ENDHLSL
        }
    }
}

