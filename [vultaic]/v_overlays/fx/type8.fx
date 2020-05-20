#include "mta-helper.fx"

const int num = 300;

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
	float nintensity = intensity * 0.005;
	float time = gTime + gTime * rate;
	float sum = -.27;
	float size = resolution.x / 1000.0;
	for (int i = 0; i < num; ++i) 
	{
		float2 position = resolution / 2.0;
		float t = (float(i) + time) / 50.0;
		float c = float(i) * 4.0;
		position.x += tan(3.0 * t + c) * abs(tan(t)+0.27) * resolution.x * 0.27;
		position.y += tan(.50 * t - c) * abs(cos(t)+0.27) * resolution.y * 0.48;
		sum += size * max(intensity, 1) / length(input.TexCoord.xy - position);
	}
    float outFX = saturate(opacity * sum);
	return float4(color, outFX);
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