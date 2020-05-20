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

float Hash( float2 p)
{
     float3 p2 = float3(p.xy,1.0);
    return frac(sin(dot(p2,float3(37.1,61.7, 12.4)))*3758.5453123);
}

float noise(in float2 p)
{
    float2 i = floor(p);
     float2 f = frac(p);
     f *= f * (3.0-2.0*f);

    return lerp(lerp(Hash(i + float2(0.,0.)), Hash(i + float2(1.,0.)),f.x),
               lerp(Hash(i + float2(0.,1.)), Hash(i + float2(1.,1.)),f.x),
               f.y);
}

float fbm(float2 p)
{
     float v = 0.0;
     v += noise(p*1.0)*.5;
     v += noise(p*2.)*.25;
     v += noise(p*4.)*.125;
     return v * 1.0;
}

float4 ps(vsout input) : COLOR0
{
	float2 uv = ( input.TexCoord.xy / resolution.xy ) * 2.0 - 1.0;
	float limit = resolution.x/resolution.y;
	uv.x *= limit;

	float iGlobalTime = gTime * (0.1 + rate * 1.5);
	float t = -iGlobalTime*0.125;


	float finalColor = float(0.0);
	for( int i=1; i < 15; ++i )
	{
	float nx = iGlobalTime*float(i);
	float offset = 0.0;//noise(float2(nx,nx)) / float(i);
	float hh = float(i) * 0.1;
	float nt = abs(1.0 / ((-0.5 + fbm( float2(uv.x + offset - 15.0*t/float(i), uv.y + offset + 10.0*t/float(i))))*475.));
	finalColor +=  nt * (hh+0.1);
	}
	float alpha = pow(finalColor,1.5)*pow(intensity*2,2)*opacity/10;
	return float4(color,alpha);
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