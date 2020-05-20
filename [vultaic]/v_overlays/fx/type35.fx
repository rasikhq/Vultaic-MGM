#include "mta-helper.fx"

#define PI 3.141592653589
const float MATH_PI = float( 3.14159265359 );

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

void Rotate( inout float2 p, float a ) 
{
  p = cos( a ) * p + sin( a ) * float2( p.y, -p.x );
}

float saturate( float x )
{
  return clamp( x, 0.0, 1.0 );
}

float4 ps(vsout input) : COLOR0
{
	float iGlobalTime = gTime * (1. + rate * 2.);
	input.TexCoord.y = 1.0 - input.TexCoord.y;
	float scale = 1.5;
	float2 fragCoord = input.TexCoord/scale;
	float2 iResolution = resolution;

	float2 p = ( 2.0 * fragCoord - iResolution.xy/scale ) / iResolution.x/scale * 1000.0;

	float sdf = 1e6;
	float dirX = 0.0;
	for ( float iCircle = 1.0; iCircle < 16.0 * 4.0 - 1.0; ++iCircle )
	{
		float circleN = iCircle / ( 16.0 * 4.0 - 1.0 );
		float t = frac( circleN + iGlobalTime * 0.2 );

		float offset = -180.0 - 330.0 * t;
		float angle  = frac( iCircle / 16.0 + iGlobalTime * 0.01 + circleN / 8.0 );
		float radius = lerp( 50.0, 0.0, 1.0 - saturate( 1.2 * ( 1.0 - abs( 2.0 * t - 1.0 ) ) ) );

		float2 p2 = p;
		Rotate( p2, -angle * 2.0 * MATH_PI );
		p2 += float2( -offset, 0.0 );

		float dist = length( p2 ) - radius;
		if ( dist < sdf )
		{
			dirX = p2.x / radius;
			sdf  = dist;
		}
	}

	float a = 1.0 - smoothstep( 0.0, 1.0, sdf * 0.3 );

	return float4( color, pow(a,0.5)*pow(intensity*2,2)/2*opacity );
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