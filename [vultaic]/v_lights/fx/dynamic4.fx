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
	float2 uv = (input.TexCoord.xy / resolution.xy * 3.5);
	float3 texcolor = (frac(sin(dot(floor(floor(uv.xy*floor(frac(gTime*0.1)*12.0))+gTime*1.0),(5.364,6.357)))*357.536));
	return float4(color * texcolor,1.0);
}

technique tec
{
	pass Pass0
	{
		VertexShader = compile vs_3_0 vs();
		PixelShader = compile ps_3_0 ps();
	}
}