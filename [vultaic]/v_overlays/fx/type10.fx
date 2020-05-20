#include "mta-helper.fx"

#define PI 3.14159

float2 resolution = float2(1, 1);
float intensity = 1;
float speed = 1;
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
	float time = gTime * (0.5 + rate);
	float2 p = ( input.TexCoord.xy / resolution.xy ) - 0.5;
	float sx = 0.1* (p.x + 0.6) * sin( 200.0 * p.y - 10. * time);
	float dy = 4./ ( 100. * abs(p.y - sx));
	dy += (float2(p.x , 0.)*0.6/(30. * length(p + float2(p.x, 0.)))).y;
	sx += (float2(p.y , 0.)*0.1*( p.x + 0.9)*dy).x;
	
    float apMul = saturate(((p.x + 0.1) * dy + 0.1 * dy + dy) / 3);
    float3 outColor = float3((p.x + 0.1) * dy, 0.1 * dy, dy);
    float outFX = saturate(opacity * apMul);
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