#include "mta-helper.fx"

#define MAX_ITER 3

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
	float2 v_texCoord = input.TexCoord.xy / resolution;
	float2 p =  v_texCoord * 8.0 - (20.0);
	float2 i = p;
	float c = 1.0;
	float inten = .05;
	for (int n = 0; n < MAX_ITER; n++)
	{
		float t = time * (1.0 - (3.0 / float(n+1)));

		i = p + float2(cos(t - i.x) + sin(t + i.y),
		sin(t - i.y) + cos(t + i.x));
	
		c += 1.0/length(float2(p.x / (sin(i.x+t)/inten),
		p.y / (cos(i.y+t)/inten)));
	}
	c /= float(MAX_ITER);
	c = 1.5 - sqrt(c);
	float3 texColor = float3(0.02, 0.02, 0.02);
	texColor.rgb *= (1.0 / (1.0 - (c + 0.05))) * intensity;
	float outFX = saturate(opacity * texColor);
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