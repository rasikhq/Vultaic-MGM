#include "mta-helper.fx"

#define PI 3.141592653589793
#define TAU 6.283185307179586

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

float cubicPulse( float c, float w, float x ){
    x = abs(x - c);
    if( x>w ) return 0.0;
    x /= w;
    return 1.0 - x*x*(3.0-2.0*x);
}

float4 ps(vsout input) : COLOR0
{
	float iGlobalTime = gTime * (1. + rate);
	input.TexCoord.y = 1.0 - input.TexCoord.y;
	float2 fragCoord = input.TexCoord;
	float2 iResolution = resolution;

	float time = iGlobalTime * 0.55;

	float2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
	float2 uvOrig = p;
	float rotZ = 1. - 0.23 * sin(1. * cos(length(p * 1.5)));
	mul(p,float2x2(cos(rotZ), sin(rotZ), -sin(rotZ), cos(rotZ)));
	float an = atan2(p.x,p.y);
	float rSquare = pow( pow(p.x*p.x,4.0) + pow(p.y*p.y,4.0), 1.0/8.0 );
	float rRound = length(p);
	float r = lerp(rSquare, rRound, 0.5 + 0.5 * sin(time * 2.));
	float2 uv = float2( 0.3/r + time, an/3.1415927 );
	uv += float2(0., 0.25 * sin(time + uv.x * 1.2));
	float f = 1. + 0.0002 * length(uvOrig);
	uv /= float2(f,f);
	float2 uvDraw = frac(uv * 12.);
	float a = cubicPulse(0.5, 0.06, uvDraw.x);
	a = max(a, cubicPulse(0.5, 0.06, uvDraw.y));
	a = a * r * 0.8;
	a += 0.15 * length(uvOrig);
	return float4( color, pow(a,1.5)*pow(intensity*2,2)/2*opacity );
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