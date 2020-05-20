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
	float time = gTime + gTime * rate;
	float2 pos = ( input.TexCoord.xy / resolution.xy );
	float color_r = color.r;		
	float color_g = color.g;		
	float color_b = color.b;		
	float dist = (pos[1] - 0.4*sin((pos[0]+time/1.5)*2.0) - 0.5);
	dist = abs(dist);
	color_r = pow(1.0 - dist, 2.0);
	float dist1 = (pos[1] - 0.5*sin((pos[0]+time/1.0)*2.0) - 0.5);
	dist1 = abs(dist1);
	color_g = pow(1.0 - dist1, 2.0);
	float dist2 = (pos[1] - 0.4*sin((pos[0]+time/0.5)*2.0) - 0.5);
	dist2 = abs(dist2);
	color_b = pow(1.0 - dist2, 2.0);
	
    float3 outColor = saturate(float3(color_r, color_g, color_b));
    float outFX = saturate(((outColor.r + outColor.g + outColor.b) / 3) * opacity);
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