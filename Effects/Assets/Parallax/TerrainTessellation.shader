Shader "EdgeCollapse/TerrainTessellation"
{
    Properties {
        _WireColor ("WireColor", Color) = (0,0,0)
        _WireWidth ("WireWidth", Range(1,5)) = 1
        _Factor ("Factor", Range(1,32)) = 1 
        _DisplacementMap ("Displacement", 2D) = "white" {}
        _DisplacementStrength ("Displacement Strength", Range(0, 1)) = 0.1
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

            struct a2v {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2t {
                float4 positionOS : INTERNALTESSPOS;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD1;
            };

            struct t2g {
                float4 positionCS : SV_POSITION;
            };

            struct g2f {
                float4 positionCS : SV_POSITION;
                float3 barycentricCoordinates : TEXCOOR0;
            };

            struct tessFactor
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            sampler2D _DisplacementMap;

            float3 _WireColor;
            float _WireWidth;
            float _Factor;
            float _DisplacementStrength;

            v2t vert(a2v i)
            {
                v2t o;
                o.positionOS = i.positionOS;
                o.normalOS = i.normalOS;
                o.uv = i.uv;
                return o;
            }

            tessFactor patchConstant (InputPatch<v2t, 3> patch) 
            {
                tessFactor f;
                f.edge[0] = _Factor;
                f.edge[1] = _Factor;
                f.edge[2] = _Factor;
                f.inside = _Factor;
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
                float2 uv = float2(0,0);
                uv += patch[0].uv * barycentricCoordinates.x;
                uv += patch[1].uv * barycentricCoordinates.y;
                uv += patch[2].uv * barycentricCoordinates.z;

                float3 normalOS = float3(0,0,0);
                normalOS += patch[0].normalOS * barycentricCoordinates.x;
                normalOS += patch[1].normalOS * barycentricCoordinates.y;
                normalOS += patch[2].normalOS * barycentricCoordinates.z;

                float3 positionOS = float3(0,0,0);
                positionOS += patch[0].positionOS.xyz * barycentricCoordinates.x;
                positionOS += patch[1].positionOS.xyz * barycentricCoordinates.y;
                positionOS += patch[2].positionOS.xyz * barycentricCoordinates.z;

                float displacement = tex2Dlod(_DisplacementMap, float4(uv, 0, 0)).g;
                displacement = (displacement - 0.5f) * _DisplacementStrength;
                positionOS.xyz += normalize(normalOS) * displacement;

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

