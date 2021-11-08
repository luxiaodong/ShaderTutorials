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
                float4 vertex : SV_POSITION;
            };

            float3 _ShadowColor;
            half4 _Plane;

            v2f vert (a2v i)
            {
                v2f o;
                Light light = GetMainLight();
                float3 lightDir = light.direction;
                float4 worldPos = mul(unity_ObjectToWorld, i.vertex);

                float t = (_Plane.w - dot(worldPos.xyz, _Plane.xyz)) / dot(lightDir.xyz, _Plane.xyz);
                worldPos.xyz = worldPos.xyz + t*lightDir.xyz;
                o.vertex = mul(unity_MatrixVP, worldPos);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                return float4(_ShadowColor, 1);
            }

            ENDHLSL
        }


    }
}