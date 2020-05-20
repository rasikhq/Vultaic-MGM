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

float4 ps(vsout input) : COLOR0
{
	float time = gTime * (0.25 + rate * 2.);
	float2 co = float2(input.TexCoord.x*cos(time),input.TexCoord.y*sin(time));
	float2 as = float2(resolution.x/resolution.y,1.0);
	float2 position = ( input.TexCoord.xy / resolution.xy ) * as;
	float n = 40.0;
	float x = frac((position.x)*n) - 0.5;
	float y = frac((position.y)*n) - 0.5;
	float2 s = float2(x*x,y*y);
	float c = s.x * s.y * (200.0 + 500.0*((1.0+sin(time*1.5))*0.5)+0.75);
	c = clamp(c,0.0,1.0);
	c *= sin(position.y*16.0+time*2.5) * cos(position.x*16.0+time);
	float3 col = color * c * intensity;
	float outFX = saturate(opacity * col);
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