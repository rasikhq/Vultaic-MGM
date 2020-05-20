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
	float2 p = ( input.TexCoord.xy / resolution.xy ) * 2.0 - 1.0;
	float3 c = float3(0,0,0);
	float ampone = amp+0.1;
	float ampfifteen = amp+0.15;
	float ampthree = amp+0.3;
	float amptwo = amp+0.2;
	float glowT = sin(time) * 0.5 + 0.5;
	float glowFactor = lerp( 0.015, 0.035, glowT );
	c += float3(0.02, 0.03, 0.13) * ( glowFactor * abs( 1.0 / sin(p.x + sin( p.y + time ) * amp ) ));
	c += float3(0.02, 0.20, 0.03) * ( glowFactor * abs( 1.0 / sin(p.x + cos( p.y + time+1.00 ) * ampone ) ));
	c += float3(0.15, 0.05, 0.20) * ( glowFactor * abs( 1.0 / sin(p.y + sin( p.x + time+1.30 ) * ampfifteen ) ));
	c += float3(0.20, 0.05, 0.05) * ( glowFactor * abs( 1.0 / sin(p.y + cos( p.x + time+3.00 ) * ampthree ) ));
	c += float3(0.17, 0.17, 0.05) * ( glowFactor * abs( 1.0 / sin(p.y + cos( p.x + time+5.00 ) * amptwo ) ));
	c += float3(0.02, 0.03, 0.18) * ( glowFactor * abs( 1.0 / sin(p.x + sin( p.y + time ) * amp ) ));
	c += float3(0.02, 0.20, 0.07) * ( glowFactor * abs( 1.0 / sin(p.x + cos( p.y + time+1.20 ) * ampone ) ));
	c += float3(0.15, 0.05, 0.30) * ( glowFactor * abs( 1.0 / sin(p.y + sin( p.x + time+1.80 ) * ampfifteen ) ));
	c += float3(0.20, 0.05, 0.4) * ( glowFactor * abs( 1.0 / sin(p.y + cos( p.x + time+4.00 ) * ampthree ) ));
	c += float3(0.17, 0.17, 0.02) * ( glowFactor * abs( 1.0 / sin(p.y + cos( p.x + time+9.00 ) * amptwo ) ));
	float a = (c.r + c.g + c.b)/3;
	return float4( c*color, pow(a,0.5)*pow(intensity*1.7,3)/2*opacity );
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