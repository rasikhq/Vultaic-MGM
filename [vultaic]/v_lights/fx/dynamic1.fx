#include "mta-helper.fx"

#define PI 3.1415926535897932384626433832795
const float position = 0.0;

float2 resolution = float2(1, 1);
float intensity = 1;
float speed = 1;
float opacity = 1;
float3 color = float3(1.0, 1.0, 1.0);

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

float band(float2 pos, float amplitude, float frequency) {
	float wave = intensity * amplitude * asin(sin(10.0 * PI * frequency * pos.x + gTime * speed * 0.005)) / PI;
	float light = clamp(amplitude * frequency * 0.002, 0.001 + 0.001 / intensity, 5.0) * intensity / abs(wave - pos.y);
	return light;
}

float4 ps(vsout input) : COLOR0
{
	float2 pos = (input.TexCoord.xy / resolution.xy);
	pos.y += - 0.5 - position;
	float spectrum = 0.027;
	spectrum += band(pos, 0.1, 10.0);
	spectrum += band(pos, 0.2, 8.0);
	spectrum += band(pos, 0.3, 5.0);
	spectrum += band(pos, 0.5, 3.0);
	spectrum += band(pos, 0.8, 2.0);
	spectrum += band(pos, 1.0, 1.0);
	return float4(color * spectrum, 1.0);
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
		VertexShader = compile vs_3_0 vs();
		PixelShader = compile ps_3_0 ps();
	}
}