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
	float2 p = ( input.TexCoord.xy / resolution.xy ) * 0.5;
	float sx = 0.5 * (p.y + 0.5) * sin( 100.0 * p.y - 10. * gTime) * (0.5 + speed);
	float dy = 1./ ( 20. * abs(p.y - sx));
	dy += 1./ (20. * length(p - float2(p.y, 0.)));
	return float4( float3((p.y + 0.5) * dy, 0.5 * dy, dy) * color * intensity * opacity, 1.0 );
}

technique tec
{
	pass Pass0
	{
		VertexShader = compile vs_3_0 vs();
		PixelShader = compile ps_3_0 ps();
	}
}