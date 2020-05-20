#include "mta-helper.fx"

#define pi 3.14159265359

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

float3 hue2rgb(float h)
{
	const float szreg = 1.0/6.0;
	float r = (1.0 - smoothstep(szreg, 2.0*szreg, h)) + smoothstep(4.0*szreg, 5.0*szreg, h);
	float g = smoothstep(0.0, szreg, h) - smoothstep(0.5, 0.5+szreg, h);
	float b = smoothstep(2.0*szreg, 3.0*szreg, h) - smoothstep(5.0*szreg, 1.0, h);
	return float3(r,g,b) * color;
}

float4 ps(vsout input) : COLOR0
{
	float time = gTime + gTime * rate;
	if(input.TexCoord.y/resolution.y > 0.5){
		time -= (time % 1./24.);
	}
	float2 pos=(input.TexCoord.xy/resolution.y);
	pos.x-=resolution.x/resolution.y/2.0;
	pos.y-=0.5;
	
	float f = 3.0;
	float tn = (time % 2.0*pi*f) -pi*f;	
	float t = pos.x*f*pi;	
	float fx=sin(t+time)/5.0;
	float rs=distance(t, tn);
	float dist=abs(pos.y-fx)*25.0*pow(rs, 0.6 + 0.1*sin(time));	
	float3 texcolor = hue2rgb(frac(t/(pi*4.0)+time/pi)) * float3(1.0/dist,1.0/dist,1.0/dist);
	float outFX = saturate(opacity * texcolor);
   	return float4(texcolor * intensity, outFX);
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