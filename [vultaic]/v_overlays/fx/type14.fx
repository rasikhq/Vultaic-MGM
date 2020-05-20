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

float3 colorFromTicks(float t){
    float slice = 360.0; // why does this work
    float r = (sin(t+slice*0.0)+1.0)/2.0;
    float g = (sin(t+slice*1.0)+1.0)/2.0;
    float b = (sin(t+slice*2.0)+1.0)/2.0;
    return float3(r,g,b);
}

float4 ps(vsout input) : COLOR0
{
	float2 position = ( input.TexCoord.xy / resolution.xy );
    float x = position.x;
    float y = position.y;
    const float zoom = 60.0;
    float c2 = gTime * 3.0 * (1. + rate);
    float x2 = x / zoom;
    float y2 = y / zoom;
    float k = (
        128.0 + (32.0 * sin((x / 4.0 * zoom + 10.0 * sin(c2 / 128.0) * 8.0) / 8.0))
        + 128.0 + (32.0 * cos((y / 5.0 * zoom + 10.0 * cos(c2 / 142.0) * 8.0) / 8.0))
        + (128.0 + (128.0 * sin(c2 / 40.0 - sqrt(x * x + y * y) * sin(c2 / 64.0) / 8.0)) / 3.0
        + 128.0 + (128.0 * sin(c2 / 80.0 + sqrt(2.0 * x * x + y * y) * sin(c2 / 256.0) / 8.0)) / 3.0)
    ) / 4.0;
	float outFX = saturate(opacity);
	return float4(colorFromTicks(k+c2) * color * intensity, outFX);
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
		FillMode = WireFrame;
        SlopeScaleDepthBias = -0.5;
        DepthBias = countDepthBias(-0.000002, -0.0004, -0.001);
		AlphaBlendEnable = true;
		AlphaRef = 1;
		VertexShader = compile vs_3_0 vs();
		PixelShader = compile ps_3_0 ps();
	}
}