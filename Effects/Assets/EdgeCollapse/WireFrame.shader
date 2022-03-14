Shader "EdgeCollapse/WireFrame"
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
			HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geome

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v {
                float3 positionOS : POSITION;
            };

            struct v2g
            {
                float4 positionCS : SV_POSITION;
            };

            struct g2f {
                float4 positionCS : SV_POSITION;
                float3 barycentricCoordinates : TEXCOOR0;
            };

            float3 _WireColor;
            float _WireWidth;

            v2g vert(a2v i)
            {
                v2g o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            [maxvertexcount(3)]
            void geome(triangle v2g i[3], inout TriangleStream<g2f> stream)
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
                float delta = fwidth(minBary); // float delta = abs(ddx(minBary) + abs(ddy(minBary)));
                float c = smoothstep(0, delta*_WireWidth, minBary);
                // return float4(c,c,c,1.0f);
                float3 color = lerp(_WireColor, float3(1,1,1), c);
                return float4(color, 1.0);
            }

			ENDHLSL
        }
    }
}

