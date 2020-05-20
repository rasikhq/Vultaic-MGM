#include "mta-helper.fx"

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

float2 nc (in float2 uv) {
  return (uv / resolution) * 2. - 1.;
}

float random (in float2 uv, in float3 seed) {
  return frac(sin(dot(uv.xy, float2(seed.x,seed.y))) * seed.z);
}

float4 ps(vsout input) : COLOR0
{
	float time = gTime * (0.1 + rate);
	float2 uv = nc(input.TexCoord.xy) * 20.0;
	float2 ipos = floor(uv);
	float3 c = float3(
	random(ipos,float3(12.843, 78.324, 252332.0 + time)),
	random(ipos,float3(92.843, 18.324, 152332.0 + time)),
	random(ipos,float3(22.843, 38.324, 452332.0 + time)));
	float a = min((c.r + c.g + c.b)/3,1.0);
	return float4(color,a*pow(intensity*2,2)/2*opacity);
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