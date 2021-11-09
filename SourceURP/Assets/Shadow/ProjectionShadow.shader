Shader "Custom/Shadow/ProjectionShadow"
{
    Properties
    {
        // _Plane("Plane", vector) = (0,1,0,1)
        _ShadowColor("Color", color) = (0,0,0)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque"}


        Pass 
        {
            Tags{"LightMode" = "SRPDefaultUnlit"}

            ZWrite Off
            Cull Off
            Blend SrcAlpha  OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v
            {
                float4 vertex : POSITION;
            };
 
            struct v2f
            {
                float4 positionCS : SV_POSITION;
                //float2 uv : TEXCOORD0;
            };

            // float4 _Plane;
            float3 _ShadowColor;
            //float4x4 _ShadowMatrix;
            uniform float4x4 _ShadowMatrix;

            void shadowMatrix(out float4x4 m)
            {
                float3 l = float3(0, 4, -1);
                float3 n = float3(0, 1, 0); //_Plane.xyz;
                float ldotp = dot(n, l);
                float d = 0.001; //_Plane.w;

                m[0][0] = -l.x*n.x + d + ldotp;
                m[0][1] = -l.y*n.x;
                m[0][2] = -l.z*n.x;
                m[0][3] = -n.x;

                m[1][0] = -l.x*n.y;
                m[1][1] = -l.y*n.y + d + ldotp;
                m[1][2] = -l.z*n.y;
                m[1][3] = -n.y;

                m[2][0] = -l.x*n.z;
                m[2][1] = -l.y*n.z;
                m[2][2] = -l.z*n.z + d + ldotp;
                m[2][3] = -n.z;

                m[3][0] = -l.x*d;
                m[3][1] = -l.y*d;
                m[3][2] = -l.z*d;
                m[3][3] = ldotp;
            }

            v2f vert (a2v i)
            {
                v2f o;
                float4 positionWS = mul(unity_ObjectToWorld, i.vertex);
                //float4x4 m;
                //shadowMatrix(m);
                positionWS = mul(_ShadowMatrix, positionWS);
                float4 ShadowWS = positionWS.xyzw/positionWS.w;
                o.positionCS = mul(unity_MatrixVP, ShadowWS);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                return float4(_ShadowColor, 1);
            }

            ENDHLSL
        }


        Pass
        {
            Tags{"LightMode" = "LightweightForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v
            {
                float4 vertex : POSITION;
            };
    
            struct v2f
            {
                float4 positionCS : SV_POSITION;
            };
    
            v2f o;

            v2f vert (a2v i)
            {
                o.positionCS = TransformObjectToHClip(i.vertex.xyz);
                return o;
            }
   
            float4 frag (v2f i) : COLOR
            {
                return float4(1,1,1,1);
            }

            ENDHLSL
        }


    }
}