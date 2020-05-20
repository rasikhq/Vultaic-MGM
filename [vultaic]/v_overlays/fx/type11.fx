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
	float time = gTime * (0.35 + rate);
	float2 p = (input.TexCoord.xy*0.9-resolution)/min(resolution.x,resolution.y);
	float ratio = (resolution.y)/(resolution.x);
	float2 p0 = p + (time/3.0);
	float2 q = (p0 %0.2)-0.1;
	float2 r = float2(p.x*ratio/2.0+0.5,p.y/2.0+0.5);
	float f = 0.0002 / (abs(q.y) * abs(q.x));
	float t1 = sin(time)/2.2+0.5;
	float t2 = cos(time)/2.2+0.5;
    float3 outColor = float3(f*t2,f*r.x*t1*t2,f*r.y*r.x);
    float apMul = saturate((f*t2 + f*r.x*t1*t2 + f*r.y*r.x) / 3);
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