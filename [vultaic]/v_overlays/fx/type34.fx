#include "mta-helper.fx"

#define PI 3.141592653589

float2 resolution = float2(1, 1);
float intensity = 1;
float opacity = 1;
float3 color = float3(1.0, 1.0, 1.0);
float rate = 1.0;

struct vsin
{
	float4 Position : POSITION;
	float2 TexCoord : TEXCOORD0;
};

struct vsout
{
	float4 Position : POSITION;
	float2 TexCoord : TEXCOORD0;
};

vsout vs(vsin input)
{
	vsout output;
	output.Position = mul(input.Position, gWorldViewProjection);
	output.TexCoord = input.TexCoord;
	return output;
}

float sdBox( float3 p, float3 b ) {
  float3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float sdTorus( float3 p, float2 t )
{
  float2 q = float2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float3 ofloat3 = float3(0.1,0.1,0.1);
float opRep( float3 p, float3 c )
{
    float3 q = fmod(p,c)-0.5*c;    
    return sdBox(q,ofloat3);
}

float sphere( float3 p, float s ) { return length(p)-s; }
float reflectance(float3 a, float3 b) { return dot(normalize(a),normalize(b)) * 0.5 + 0.5; }
float2 kaelidoGrid(float2 p) { return float2(step(fmod(p, 2.0), float2(1.0,1.0))); }
float3 rotateY(float3 v, float t) { 
  float cost,sint;
  sincos(t,sint,cost);
  return float3(v.x * cost + v.z * sint, v.y, -v.x * sint + v.z * cost); 
}
float3 rotateX(float3 v, float t) { 
  float cost,sint;
  sincos(t,sint,cost);
  return float3(v.x, v.y * cost - v.z * sint, v.y * sint + v.z * cost); 
}
float3 rotateZ(float3 p, float angle) { 
  float c,s;
  sincos(angle,s,c);
  return float3(c*p.x+s*p.y, -s*p.x+c*p.y, p.z); 
}

float2 rotation(float2 p, float angle)
{
  float c,s;
  sincos(angle,s,c);
  return mul(float2x2(c,-s,s,c),p);
}

float4 ps(vsout input) : COLOR0
{
	float iGlobalTime = gTime * (0.5 + rate);

	input.TexCoord.y = 1.0 - input.TexCoord.y;
	// Ray from UV
	float2 uv = input.TexCoord * 2.0 - 1.0;
	float3 ray = normalize(float3(0.0,0.0,1.0) + float3(1.0, 0.0, 0.0) * uv.x + float3(0.0,1.0,0.0) * uv.y);

	// Color
	float3 c = float3(1.0, 1.0, 1.0);

	// Raymarching
	float t = 0.0;
	for (float r = 0.0; r < 64.0; r++)
		{
		float3 p = float3(0, 0, -1.5) + mul(ray,t);
		p.xy = rotation(p.xy,t*0.8*sin(iGlobalTime));
		p.yz = rotation(p.yz,t*0.08*sin(iGlobalTime*2.0));
		p.z = p.z + iGlobalTime*1.5;
		p.y = p.y + sin(iGlobalTime*.2)*3.;

		float d = sphere(p,0.5);
		d = opRep(p,float3(0.5,0.5,0.5));

		if (d < 0.001 || t > 1000.0)
		{
			c = lerp(float3(1.0, 1.0, 1.0), float3(0.0,0.0,0.0), r / 64.0);
			c = lerp(c, float3(0.0,0.0,0.1), smoothstep(0.1, 1000.0, t));
			break;
		}

		t += d;
	}
	// Hop
	float a = (3-c.r-c.g-c.b)/3;
	return float4( a*color, pow(a,0.5)*intensity/2*opacity );
}

float countDepthBias(float minBias, float maxBias, float closeBias)
{
    float4 viewPos = mul(float4(gWorld[3].xyz, 1), gView);
    float4 projPos = mul(viewPos, gProjection);
    float depthImpact = minBias + ((maxBias - minBias) * (1 - saturate(projPos.z / projPos.w)));
    depthImpact += closeBias * saturate(0.5 - (viewPos.z / viewPos.w));
    return depthImpact;
}

technique tec
{
	pass Pass0
	{
        SlopeScaleDepthBias = -0.5;
        DepthBias = countDepthBias(-0.000002, -0.0004, -0.001);
		AlphaBlendEnable = true;
		AlphaRef = 1;
		VertexShader = compile vs_3_0 vs();
		PixelShader = compile ps_3_0 ps();
	}
}