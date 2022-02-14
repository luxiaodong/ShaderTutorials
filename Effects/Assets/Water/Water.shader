Shader "Water/Water"
{
    Properties {
		_RampTex ("RampTex", 2D) = "white" {}

        _Amp ("Amp", Vector) = (0,0,0,0)
        _Length ("Length", Vector) = (0,0,0,0)
        [HideInInspector] _Freq ("Freq", Vector) = (0,0,0,0)
        _Phase ("Phase", Vector) = (0,0,0,0)
        _DirX ("DirX", Vector) = (0,0,0,0)
        _DirY ("DirY", Vector) = (0,0,0,0)
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
            float4 _RampTex_ST;

            float4 _Amp;
            float4 _Freq;
            float4 _Length;
            float4 _Phase;
            float4 _DirX;
            float4 _DirY;

            //
            float4 calculatePosition(float3 pos)
            {
                float x = pos.x;
                float y = pos.y;
                float z = pos.z;
                float4 f = 3.1415926*2.0/_Length; //频率
                float4 speed = sqrt(9.8/f);// sqrt(gL/2*pi)

                float2 d1 = normalize(float2(_DirX.x, _DirY.x));
                float2 d2 = normalize(float2(_DirX.y, _DirY.y));
                float2 d3 = normalize(float2(_DirX.z, _DirY.z));
                float2 d4 = normalize(float2(_DirX.w, _DirY.w));
                float dot1 = dot(d1, pos.xz);
                float dot2 = dot(d2, pos.xz);
                float dot3 = dot(d3, pos.xz);
                float dot4 = dot(d4, pos.xz);

                float4 dotValue = float4(dot1, dot2, dot3, dot4);
                float4 sita = f*( dotValue - speed*_Time.y + _Phase);
                float4 dx = float4(d1.x, d2.x, d3.x, d4.x);
                float4 dz = float4(d1.y, d2.y, d3.y, d4.y);

                x = x + dot(dx*_Amp, cos(sita));
                y = dot(_Amp, sin(sita));
                z = z + dot(dz*_Amp, cos(sita));
                return float4(x, y, z, 1.0f);
            }

            // 计算法线
            float3 calculateNormal(float3 pos)
            {
                // 切线, 原函数的偏导
                float x = pos.x;
                float y = pos.y;
                float z = pos.z;
                float4 f = 3.1415926*2.0/_Length; //频率
                float4 speed = sqrt(9.8/f);// sqrt(gL/2*pi)

                float2 d1 = normalize(float2(_DirX.x, _DirY.x));
                float2 d2 = normalize(float2(_DirX.y, _DirY.y));
                float2 d3 = normalize(float2(_DirX.z, _DirY.z));
                float2 d4 = normalize(float2(_DirX.w, _DirY.w));
                float dot1 = dot(d1, pos.xz);
                float dot2 = dot(d2, pos.xz);
                float dot3 = dot(d3, pos.xz);
                float dot4 = dot(d4, pos.xz);

                float4 dotValue = float4(dot1, dot2, dot3, dot4);
                float4 sita = f*( dotValue - speed*_Time.y);
                float4 dx = float4(d1.x, d2.x, d3.x, d4.x);
                float4 dz = float4(d1.y, d2.y, d3.y, d4.y);

                float4 sinV = sin(sita);
                float4 cosV = cos(sita);

                // 对x求偏导
                float xdx = 1 - dot(dx * _Amp, sinV * f * dx);
                float ydx = 0 + dot(_Amp, cosV * f * dx);
                float zdx = 0 - dot(dz * _Amp, sinV * f * dx);

                // 对z求偏导
                float xdz = 0 - dot(dx * _Amp, sinV * f * dz);
                float ydz = 0 + dot(_Amp, cosV * f * dz);
                float zdz = 1 - dot(dz * _Amp, sinV * f * dz);

                float3 tangent = normalize(float3(xdx, ydx, zdx));
                float3 binormal = normalize(float3(xdz, ydz, zdz));
                return cross(binormal, tangent);
            }

            v2f vert(a2v i)
            {
                v2f o;
                float4 pos = calculatePosition(i.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(pos);
                o.positionCS = TransformObjectToHClip(pos.xyz);
                // o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.normalWS = TransformObjectToWorldNormal(calculateNormal(i.positionOS.xyz));
                o.uv = TRANSFORM_TEX(i.uv, _RampTex);
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

