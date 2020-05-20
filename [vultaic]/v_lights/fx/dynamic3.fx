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
	float2 position = ( input.TexCoord.xy / resolution.xy ) ;
	float yorigin = 0.5 + 0.1*(tan(sin(position.x*30.0+0.5*(frac(gTime / 2.0)) * 2.5 * 20.)));
	float dist = ( 20.0*abs(yorigin - position.y)) * (1.0 + speed);
	return float4(color/dist * (1. + intensity), 1.0);
}

technique tec
{
	pass Pass0
	{
		VertexShader = compile vs_3_0 vs();
		PixelShader = compile ps_3_0 ps();
	}
}