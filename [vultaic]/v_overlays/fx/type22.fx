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
	float time = gTime * (0.25 + rate);
	float2 st = (input.TexCoord.xy * 3.0);
	st *= 3.0;
	float2 p = st * 5.;
	p = (p % 2.);
	p.x += .1 * sin(2.5 * st.x + 4.*time) * intensity;
	p.y += .2 * cos(2.5 * st.y + 5.*time) * intensity;
	float r = .5;
	float l = length(p - (1.));
	float d = abs(l - r);
	float fr = 50. + 40. * sin(3.14*time + st.x);
	float fg = 50. + 40. * sin(5.27*time + st.y);
	float fb = 50. + 40. * sin(7.35*time);
	float outFX = saturate(opacity * smoothstep(.4, .5, float3(1, 1, 1)));
	return float4(color * float3(1. / (fr * d), 1. / (fg * d), 1. / (fb * d)), outFX);
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