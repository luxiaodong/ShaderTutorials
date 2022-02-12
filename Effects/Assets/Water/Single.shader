Shader "Water/Single"
{
    Properties {
		_RampTex ("RampTex", 2D) = "white" {}

        _Amp ("Amp", float) = 1.0
        _Length ("Length", float) = 1.0
        _Freq ("Freq", float) = 1.0
        _Speed ("Speed", float) = 1.0 //假设速度.
        _DirX ("DirX", float) = 1.0
        _DirY ("DirY", float) = 0
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

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

            float _Amp;
            float _Freq;
            float _Length;
            float _Speed;
            float _DirX;
            float _DirY;

            float4 calculatePosition(float3 pos)
            {
                float x = pos.x;
                float y = pos.y;
                float z = pos.z;
                float f = 3.1415926*2.0/_Length;
                float sita = f*(x - _Speed*_Time.y);
                x = x + _Amp * cos(sita);
                y = _Amp * sin(sita);
                return float4(x, y, z, 1.0f);
            }

            float3 calculateNormal(float3 pos)
            {
                // 切线, 原函数的偏导
                float x = pos.x;
                float y = pos.y;
                float z = pos.z;
                float f = 3.1415926*2.0/_Length;
                float sita = f*(x - _Speed*_Time.y);
                float3 tangent = normalize(float3(1 - _Amp * sin(sita) * f, _Amp * cos(sita) * f ,0));
                return cross(tangent, float3(0,0,-1));
            }

            v2f vert(a2v i)
            {
                v2f o;
                float4 pos = calculatePosition(i.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(pos);
                o.positionCS = TransformObjectToHClip(pos.xyz);
                o.normalWS = TransformObjectToWorldNormal( calculateNormal(i.positionOS.xyz) );
                o.uv = i.uv;
                return o;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                //向量
                Light light = GetMainLight();
                float3 ndotl = max(0, dot(i.normalWS, light.direction));

                //各项
                float3 texColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, i.uv);
                float3 color = texColor * ndotl;
                return float4(color, 1.0f);
            }

			ENDHLSL
        }
    }
}


// Shader "My/Gerstner" {
//     Properties {
//         //零参数是没有用的
//         _A("A_振幅,从水平面到波峰的高度", Vector) = (1, 1, 0, 0)//xy有用
//         _Q("Q_用来控制波的陡度，其值越大，则波越陡", Vector) = (0.66, 0, 0, 0)//x有用
//         _S("S_速度,每秒种波峰移动的距离", Vector) = (2, 2, 0, 0)//xy有用
//         _Dx("X_垂直于波峰沿波前进方向的水平矢量X", Vector) = (0.6, 0, 0, 0)//x有用
//         _Dz("Z_垂直于波峰沿波前进方向的水平矢量Z", Vector) = (0.24, 0, 0, 0)//x有用
//         _L("L_波长,世界空间中波峰到波峰之间的距离", Vector) = (1, 1, 1, 1)//x有用，但是yzw不能是零
//     }
//     SubShader {
//         Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        
//         Pass { 
//             Tags { "LightMode"="ForwardBase" }
        
//             CGPROGRAM
            
//             #pragma vertex vert
//             #pragma fragment frag
            
//             #include "UnityCG.cginc"
//             #include "Lighting.cginc"
//             #include "AutoLight.cginc"
            
            
//             float4 _A;
//             float4 _Q;
//             float4 _S;
//             float4 _Dx;
//             float4 _Dz;
//             float4 _L;    
            
//             struct a2v {
//                 float4 vertex : POSITION;
//                 float4 color : TEXCOORD1;
//             };
            
//             struct v2f {
//                 float4 pos : SV_POSITION;
//                 float3 worldPos : TEXCOORD1;
//                 float4 color : TEXCOORD2;
            
//             };
//             float3 CalculateWavesDisplacement(float3 vert)
//             {
//                 float PI = 3.141592f;
//                 float3 Gpos = float3(0,0,0);
//                 float4 w = 2*PI/_L;
//                 float4 psi = _S*2*PI/_L;
//                 float4 phase = w*_Dx*vert.x+w*_Dz*vert.z+psi*_Time.x;
//                 float4 sinp=float4(0,0,0,0), cosp=float4(0,0,0,0);
//                 sincos(phase, sinp, cosp);
//                 Gpos.x = dot(_Q*_A*_Dx, cosp);
//                 Gpos.z = dot(_Q*_A*_Dz, cosp);
//                 Gpos.y = dot(_A, sinp);
//                 return Gpos;
//             } 
//             v2f vert(a2v v) {
//                 v2f o;
//                 float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
//                 float3 disPos = CalculateWavesDisplacement(worldPos);
//                 v.vertex.xyz = mul(unity_WorldToObject, float4(worldPos+disPos, 1));
//                 o.pos = UnityObjectToClipPos(v.vertex);                 
//                 o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;            
//                 o.color = v.color;
//                 return o;
//             }
            
//             fixed4 frag(v2f i) : SV_Target {
                            
//                 return i.color;
                
//             }
            
//             ENDCG
//         }
//         }
//         }
// }


