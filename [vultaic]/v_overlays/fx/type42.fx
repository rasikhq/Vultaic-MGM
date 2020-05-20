#include "mta-helper.fx"

#define PI 3.141592653589793
#define TAU 6.283185307179586
#define TWO_PI 6.283185
#define NUMBALLS 32.0
float d = -TWO_PI/36.0;

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
	float iGlobalTime = gTime * (0.1 + rate);
	float alpha = pow(intensity*2,2)*opacity;
	float2 p = (2.0*input.TexCoord.xy - resolution)/(min(resolution.x,resolution.y));
	//P *= mat2(cos(iGlobalTime), -sin(iGlobalTime), sin(iGlobalTime), cos(iGlobalTime));
	float3 c = float3(0,0,0);
	for(float i = 0.0; i < NUMBALLS; i++) {
	float t = TWO_PI * i/NUMBALLS + iGlobalTime;
	float x = cos(t);
	float y = sin(3.0 * t + d);
	float2 q = 0.8*float2(x, y);
	c += 0.01/distance(p, q) * float3(color.r*abs(x), color.g*abs(y), color.b*(resolution.y-abs(y)));
	}
	float3 texcolor = 5*pow(c,5);
	float outFX = saturate(texcolor * alpha * opacity);
	return float4(texcolor,outFX);
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