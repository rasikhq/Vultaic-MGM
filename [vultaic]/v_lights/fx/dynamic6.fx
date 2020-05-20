#include "mta-helper.fx"

float2 resolution = float2(1, 1);
float intensity = 1;
float speed = 10;
float opacity = 1;
float3 color = float3(1.0, 1.0, 1.0);

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
	float2 uPos = ( input.TexCoord.xy / resolution.xy ) * 3.;
	uPos -= .3;
	float3 texcolor = (0.0);
	float time = gTime * (1. + speed * 0.0005);
	for( float i = 0.; i <10.; ++i ) {
		uPos.y += sin( uPos.x*(i) + (time * i * i * .1) ) * 0.1 * intensity;
		float fTemp = abs(1.0 / uPos.y / 500.0);
		texcolor += float3( fTemp*(8.0-i)/7.0, fTemp*i/10.0, pow(fTemp,1.0)*1.5 );
	}
	return float4(texcolor * color * opacity, 10.0);
}

technique tec
{
	pass Pass0
	{
		VertexShader = compile vs_3_0 vs();
		PixelShader = compile ps_3_0 ps();
	}
}