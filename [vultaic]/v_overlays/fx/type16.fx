#include "mta-helper.fx"

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

float dia(in float2 p) {
	float time = gTime * (0.5 + rate);
	float a = atan(p.y * p.x);	
	float s = floor((abs(p.x) + abs(p.y)) * 100.0);
	s *= sin(s * 24.0);
	float s2 = frac(sin(s));
	
	float c = step(1.0, tan(a + s + s2 * sin(time) * 2.1) * 0.75 );
	
	c *= s2 * 0.5 + 0.1;
	return c;		
}

float4 ps(vsout input) : COLOR0
{
	float time = gTime * (0.5 + rate);
	float2 p = (input.TexCoord.xy / resolution.xy) - 0.5;
	p.x *= resolution.x / resolution.y;	
	float s = sin(time * 400.0) * cos(time * 120.0 + 32.0);
	float outFX = saturate(opacity * dia(p));
	return float4(color * intensity, outFX);
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