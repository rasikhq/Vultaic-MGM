#include "mta-helper.fx"

#define PI 3.141592653589793

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

float4 ps(vsout input) : COLOR0
{
	float iGlobalTime = gTime * (0.5 + rate * 1.5);
	input.TexCoord.y = 1.0 - input.TexCoord.y;
	float2 fragCoord = input.TexCoord;

	float t = iGlobalTime * 0.7;

	float scale = 50.0 / resolution.y;
	float2 p = fragCoord.xy * scale + 0.5; // pos normalized /w grid
	p += float2(2, 0.5) * iGlobalTime;

	float rnd = frac(sin(dot(floor(p), float2(21.98, 19.37))) * 4231.73);
	rnd = floor(rnd * 2.0) / 2.0 + floor(t) / 2.0;

	float anim = smoothstep(0.0, 0.7, frac(t));
	float phi = PI * (rnd + 0.5 * anim + 0.25);
	float2 dir = float2(cos(phi), sin(phi));

	float2 pf = frac(p);
	float d1 = abs(dot(pf - float2(0.5, 0), dir)); // line 1
	float d2 = abs(dot(pf - float2(0.5, 1), dir)); // line 2
	float a = pow((0.5 - min(d1, d2)),4)*5;
	return float4( color, a*pow(intensity*2,2)/2*opacity );
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