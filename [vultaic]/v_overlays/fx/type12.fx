#include "mta-helper.fx"

float2 resolution = float2(1, 1);
float intensity = 1;
float speed = 10;
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

float funk(float p)
{
	p=(1.+2.*p*sin(gTime))/(1.+1.*p*p*abs(sin(gTime)))*0.1* intensity;
	return p;
}

float4 ps(vsout input) : COLOR0
{
	float time = gTime + gTime * rate;
	float2 p = ( input.TexCoord.xy / resolution.xy )-float2(0.5,0.5);
	float c = 0.0;
	p.x+=-.1*sin(time);
	float f=funk(p.x*10.+(.2*tan(time)))+.1*cos(time)* intensity;
	float d=(p.y*4.-f)*10.;
	c=.175/abs(pow(abs(d),.5));
	c=clamp(c,0.,1.)+0.1*sin(time);
    float outFX = saturate(opacity * c);
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