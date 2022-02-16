Shader "SDF/SDF2D"
{
    Properties {
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

            float sdf_circle(float2 p, float r)
            {
                return length(p) - r;
            }

            float sd_box(float2 p, float2 b)
            {
                float2 d = abs(p)-b;
                return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
            }

            float sd_boxRound(float2 p, float2 b, float r)
            {
                float2 q = abs(p)-b+r;
                return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r;
            }

            float sd_boxRound2(float2 p, float2 b, float4 r)
            {
                r.xy = (p.x>0.0)?r.xy : r.zw;
                r.x  = (p.y>0.0)?r.x  : r.y;
                float2 q = abs(p)-b+r.x;
                return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
            }

            float sd_ellipse(float2 p, float2 ab)
            {
                p = abs(p); if( p.x > p.y ) {p=p.yx;ab=ab.yx;}
                float l = ab.y*ab.y - ab.x*ab.x;
                float m = ab.x*p.x/l;      float m2 = m*m; 
                float n = ab.y*p.y/l;      float n2 = n*n; 
                float c = (m2+n2-1.0)/3.0; float c3 = c*c*c;
                float q = c3 + m2*n2*2.0;
                float d = c3 + m2*n2;
                float g = m + m*n2;
                float co;
                if( d<0.0 )
                {
                    float h = acos(q/c3)/3.0;
                    float s = cos(h);
                    float t = sin(h)*sqrt(3.0);
                    float rx = sqrt( -c*(s + t + 2.0) + m2 );
                    float ry = sqrt( -c*(s - t + 2.0) + m2 );
                    co = (ry+sign(l)*rx+abs(g)/(rx*ry)- m)/2.0;
                }
                else
                {
                    float h = 2.0*m*n*sqrt( d );
                    float s = sign(q+h)*pow(abs(q+h), 1.0/3.0);
                    float u = sign(q-h)*pow(abs(q-h), 1.0/3.0);
                    float rx = -s - u - c*4.0 + 2.0*m2;
                    float ry = (s - u)*sqrt(3.0);
                    float rm = sqrt( rx*rx + ry*ry );
                    co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
                }
                float2 r = ab * float2(co, sqrt(1.0-co*co));
                return length(r-p) * sign(p.y-r.y);
            }

            v2f vert(a2v i)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformObjectToHClip(i.positionOS);
                o.normalWS = TransformObjectToWorldNormal(i.positionOS);
                o.uv = i.uv;
                return o;
            }

            float4 frag (v2f i) : SV_TARGET 
            {
                float2 uv = 2*i.uv - 1;
                // float sdf = sd_box(uv, float2(0.6, 0.3));
                // float sdf = sdf_circle(uv, 0.5);
                // float sdf = sd_boxRound(uv, float2(0.6, 0.3), 0.1);
                // float sdf = sd_boxRound2(uv, float2(0.6, 0.3), float4(0.1,0.1,0.2,0.2));
                float sdf = sd_ellipse(uv, float2(0.6, 0.3));
                float3 color = step(sdf, 0);
                return float4(color, 1.0f);
            }

			ENDHLSL
        }
    }
}

