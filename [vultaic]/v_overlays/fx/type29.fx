#include "mta-helper.fx"

float amp = 0.50;

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
	float2 uv=(((input.TexCoord.xy-(.5 * resolution)) / min (resolution.y,resolution.x)) * 2.0);
	float fline=0.0,fline2=0.0,y=0.0,t=0.0;
	for (float x=-4.69;x <=4.69;x+=0.95)
	{
		float feigenb = uv.y * t * (1.0001 - t);
		t = pow((feigenb * feigenb) + (x * x),0.5) - 2.71828;
		fline2 = fline2 + .0035 / length(abs(uv.x) + cos(t + time) - abs(uv.y));
		fline = fline + .002 / length(abs(uv.x) * -.6877663+sin((t + time)* .5) + .52) * -cos(4.799 +time);
	};
	float3 c = float3(fline2,-fline,fline);
	float a = min((c.r + c.g + c.b)/3,1.0);
	return float4(color,a*pow(intensity*2,2)/2*opacity);
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