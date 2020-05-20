#include "mta-helper.fx"

#define PI 3.14159265359

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

float random(float n) {
	return frac(abs(sin(n * 55.753) * 367.34));   
}

float random(float2 n) {
	return random(dot(n, float2(2.46, -1.21)));
}

float cycle(float n) {
	return cos(frac(n) * 2.0 * PI) * 0.5 + 0.5;
}

float3 hsbToRGB(float h,float s,float b){
	return b*(1.0-s)+(b-b*(1.0-s))*clamp(abs(abs(6.0*(h-float3(0,1,2)/3.0))-3.0)-1.0,0.0,1.0);
}

float4 ps(vsout input) : COLOR0
{
	float time = gTime * (0.5 + rate);
	float2 st = (input.TexCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
	float radian = radians(60.0);
	float scale = 10.0;
	st = (st + float2(st.y, 0.0) * cos(radian)) + float2(floor(4.0 * (st.x - st.y * cos(radian))), 0.0);
	st *= scale;
 	float n = cycle(random(floor(st * 4.0)) * 0.2 + random(floor(st * 2.0)) * 0.3 + random(floor(st)) * 0.5 + time * 0.5);
	float outFX = saturate(opacity * hsbToRGB(frac(time*0.25 + random(n*0.00001)), 1.0, 1.0));
	return float4(color * intensity, outFX);
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