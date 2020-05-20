#include "mta-helper.fx"

float sens = 0.25;
float vel = 0.01;
float pi = 3.14159265359;

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
	float time = gTime * (0.25 + rate);
	float2 pos = ((input.TexCoord.xy - 0.5 * resolution) / resolution.y);
	float n = pi * 20.0 * (1.0 + cos(0.231 * time));
	float m = pi * 20.0 * (1.0 + sin(0.2 * time));
	float z = abs(cos(n * pos.x) * cos(m * pos.y) + cos(n * pos.y) * cos(m * pos.x));
	float c0 = 1.1 - pow(z, sens * 4.0) + 0.3 * cos(3.1 * pos.x + time * 0.99);
	float c1 = 1.1 - pow(z, sens * 1.0) + 0.3 * sin(2.9 * pos.y + time * 1.02);
	float c2 = c0 * sin(3.05 * pos.y + time) + c1 * cos(3.0 * pos.x + time);
	float outFX = saturate(opacity * (c0 + c1 * sin(time * 0.7), c1 + c2 * sin(time * 0.61), c2 + c0 * sin(time * 0.54)));
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