#include "mta-helper.fx"

#define PI 3.141592653589793
#define TAU 6.283185307179586

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

float shape(in float2 pos) // a blob shape to distort
{
  return saturate( sin(pos.x*3.1416) - pos.y+0.1);
}

float nz(float3 p)
{
  float3 i = floor(p);
  float4 a = dot(i, float3(1., 57., 21.)) + float4(0., 57., 21., 78.);
  float3 f = cos((p-i)*acos(-1.))*(-.5)+.5;
  a = lerp(sin(cos(a)*a),sin(cos(1.+a)*(1.+a)),f.x);
  a.xy = lerp(a.xz, a.yw, f.y);
  return lerp(a.x, a.y, f.z);
}

float4 ps(vsout input) : COLOR0
{
	float iGlobalTime = gTime * (0.1 + rate);

	float2 uv = input.TexCoord.yx;
	uv.y = uv.y*3*0.25;
	float2 nt = 0;
	for (int i=1; i<7; i++)
	{
	float ii = pow(i,2.0);
	float fract = float(i)/24;
	float t = fract * iGlobalTime * 20.0;
	float d = (1.0-fract) * 0.05;
	float uvxii = uv.x*ii;
	float uvyii = uv.y*0.25*ii-t;
	nt += float2(nz(float3(uvxii-iGlobalTime*fract, uvyii, 0.0)) * d * 2.0, nz( float3(uvxii+iGlobalTime*fract, uvyii, iGlobalTime*fract/ii)) * d);
	}
	float flame = shape(uv + nt);
	float3 c = pow(flame, 5.0) * saturate(color);

	// tonemapping
	c = saturate(pow(c / (1.0+c),0.7/2.2));
	float a = max(c.b,max(c.r,c.g));

	return float4( c, pow(a,1.5)*pow(intensity*2,2)*opacity );
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