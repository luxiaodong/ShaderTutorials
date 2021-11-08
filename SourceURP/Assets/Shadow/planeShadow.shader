Shader "Custom/Shadow/PlaneShadow"
{
    Properties
    {
        _Plane("Plane", vector) = (0,1,0,1)
        _ShadowColor("Color", color) = (0,0,0)
        _ShadowEdge("ShadowEdge", float) = 1
        [Toggle(_DIRECTIONAL_LIGHT)] _DirectionalLight ("_DIRECTIONAL_LIGHT", Float) = 0
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
            Blend SrcAlpha  OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma shader_feature _DIRECTIONAL_LIGHT

            struct a2v
            {
                float4 vertex : POSITION;
            };
 
            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float4 _Plane;
            float3 _ShadowColor;
            float _ShadowEdge;

            v2f vert (a2v i)
            {
                v2f o;
                float4 positionWS = mul(unity_ObjectToWorld, i.vertex);

#ifdef _DIRECTIONAL_LIGHT
                Light light = GetMainLight();
                float3 lightDir = - light.direction;
#else
                float3 spotLightWS = float3(0, 4, -1);
                float3 lightDir = normalize(positionWS.xyz - spotLightWS);
#endif

                float t = (_Plane.w - dot(positionWS.xyz, _Plane.xyz)) / dot(lightDir.xyz, _Plane.xyz);
                float3 shadowWS = positionWS + t*lightDir.xyz;
                o.positionCS = mul(unity_MatrixVP, float4(shadowWS,1));

                float3 shadowOriginWS = float3(0,0,0);
                float distance = length(shadowWS.xyz - shadowOriginWS);
                o.uv = float2(t, distance);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float t = i.uv.x;
                float distance = i.uv.y;
                clip(t);
                float a = pow(2, 2*(_ShadowEdge - distance));
                return float4(_ShadowColor, a);
            }

            ENDHLSL
        }


    }
}