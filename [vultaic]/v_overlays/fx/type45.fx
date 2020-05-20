#include "mta-helper.fx"

#define N 15

float2 resolution = float2(1, 1);
float intensity = 1;
float opacity = 1;
float3 color = float3(1.0, 1.0, 1.0);
float rate = 1.0;
float speed = 1.0;

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

float rand( float x, float y ){return frac( sin( x + y*0.1234 )*1234.0 );}

float interpolar(float2 cord, float L){
   	float XcordEntreL= cord.x/L;
        float YcordEntreL= cord.y/L;
    
	float XcordEnt=floor(XcordEntreL);
        float YcordEnt=floor(YcordEntreL);

	float XcordFra=frac(XcordEntreL);
        float YcordFra=frac(YcordEntreL);
	
	float l1 = rand(XcordEnt, YcordEnt);
	float l2 = rand(XcordEnt+1.0, YcordEnt);
	float l3 = rand(XcordEnt, YcordEnt+1.0);
	float l4 = rand(XcordEnt+1.0, YcordEnt+1.0);
	
	float inter1 = (XcordFra*(l2-l1))+l1;
	float inter2 = (XcordFra*(l4-l3))+l3;
	float interT = (YcordFra*(inter2 -inter1))+inter1;
    return interT;
}

float4 ps(vsout input) : COLOR0
{
	float texcolor = 0.0;
	
	for ( int i = 0; i < N; i++ ){
		float p = frac(float(i) / float(N) - gTime*.015);
		float a = p * (0.90-p) * (1. + rate);
		texcolor += a * (interpolar(input.TexCoord.xy-resolution/2., resolution.y/pow(2.0, p*p*float(N)))-.5);
	}
	texcolor += .4;
	float outFX = saturate(texcolor * opacity * intensity);
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