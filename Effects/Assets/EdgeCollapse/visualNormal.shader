Shader "EdgeCollapse/visualNormal"
{
    Properties {
        _NormalColor ("NormalColor", Color) = (0,0,0)
        _NormalLength ("NormalLength", Range(0,1)) = 1
	}

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            Cull OFF

			HLSLPROGRAM
            #pragma target 4.0
            #pragma require geometry
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geome

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct v2g
            {
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
            };

            struct g2f {
                float4 positionCS : SV_POSITION;
            };

            float3 _NormalColor;
            float _NormalLength;

            v2g vert(a2v i)
            {
                v2g o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.normalWS   = TransformObjectToWorldNormal(i.normalOS).xyz;
                // o.normalWS = SafeNormalize(i.positionOS);
                return o;
            }
/*
            [maxvertexcount(6)]
            void geome(triangle v2g p[3], inout LineStream<g2f> stream)
            {
                for(int i = 0; i < 3; i++)
                {
                    g2f g0,g1;
                    g0.positionCS = TransformWorldToHClip(p[i].positionWS);
                    g1.positionCS = TransformWorldToHClip(p[i].positionWS + SafeNormalize(p[i].normalWS) * _NormalLength);
                    
                    stream.Append(g0);
                    stream.Append(g1);
                    stream.RestartStrip();
                }
            }
*/

            [maxvertexcount(3)]
            void geome(triangle v2g p[3], inout TriangleStream<g2f> stream)
            {
                float3 averageNormal = SafeNormalize(p[0].normalWS + p[1].normalWS + p[2].normalWS);

                float3 posWS_0 = p[0].positionWS + averageNormal * _NormalLength;
                float3 posWS_1 = p[1].positionWS + averageNormal * _NormalLength;
                float3 posWS_2 = p[2].positionWS + averageNormal * _NormalLength;
                
                g2f g0,g1,g2;
                g0.positionCS = TransformWorldToHClip(posWS_0);
                g1.positionCS = TransformWorldToHClip(posWS_1);
                g2.positionCS = TransformWorldToHClip(posWS_2);

                stream.Append(g0);
                stream.Append(g1);
                stream.Append(g2);

                stream.RestartStrip();                
            }

            float4 frag (g2f i) : SV_TARGET 
            {
                return float4(_NormalColor, 1.0f);
            }

			ENDHLSL
        }

    }
}

