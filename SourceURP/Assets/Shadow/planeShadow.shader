Shader "Custom/Shadow/PlaneShadow"
{
    Properties
    {
        _ShadowColor("Color", color) = (0,0,0)
        _Plane("Plane", vector) = (0,1,0,1)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque"}

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


        Pass 
        {
            Tags{"LightMode" = "SRPDefaultUnlit"}

            ZWrite Off
            Cull Back

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
                float2 uv : TEXCOORD0;
            };

            float3 _ShadowColor;
            half4 _Plane;

            v2f vert (a2v i)
            {
                v2f o;
                Light light = GetMainLight();
                float3 lightDir = - light.direction;
                float4 worldPos = mul(unity_ObjectToWorld, i.vertex);

                float t1 = (_Plane.w - dot(worldPos.xyz, _Plane.xyz)) / dot(lightDir.xyz, _Plane.xyz);
                float t2 = (_Plane.w - dot(worldPos.xyz, _Plane.xyz)) / dot(_Plane.xyz, _Plane.xyz);

                if(t1 > 0)
                {
                    worldPos.xyz = worldPos.xyz + t1*lightDir.xyz;
                }
                else
                {
                    worldPos.xyz = worldPos.xyz + t2*_Plane.xyz;
                }

                o.positionCS = mul(unity_MatrixVP, worldPos);
                o.uv = float2(t1, t2);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float t1 = i.uv.x;
                float t2 = i.uv.y;
                clip(t1);
                return float4(_ShadowColor, 1);
            }

            ENDHLSL
        }


    }
}