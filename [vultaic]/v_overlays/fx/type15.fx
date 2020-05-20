#include "mta-helper.fx"

const float PI = 3.14159265359;
const float L = 0.5;
const float epsilon = 0.1;

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
	float time = gTime * (0.5 + rate);
	float n = 20.0;
	float m = 20.0;
	float2 R = resolution.xy;
    float2 uv = input.TexCoord.xy / R.x;
    uv -= 0.5 * R / R.x;
    n += 2.00*sin(time);
    m += 1.66*cos(time);
    float node = abs(cos(n * PI * uv.x / L) * cos(m * PI * uv.y / L) - cos(m * PI * uv.x / L) * cos(n * PI * uv.y / L));
	float outFX = saturate(opacity * smoothstep(0., epsilon, node*0.05));
	return float4(color, outFX);;
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