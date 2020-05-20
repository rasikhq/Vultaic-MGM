#include "mta-helper.fx"

float size = 30.0;
float speed= .75;

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

float random(float2 co){
    return frac(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
}
float3 random_color(float2 coords){
	float a = floor(random(coords.xy*6.896)*7.);
	//(2^3)-1
	//           { return float3(0.,0.,0.); } //BLACK
	if (a == 0.) { return float3(1.,0.,0.); } //RED
	if (a == 1.) { return float3(0.,1.,0.); } //GREEN
	if (a == 2.) { return float3(1.,1.,0.); } //YELLOW
	if (a == 3.) { return float3(0.,0.,1.); } //BLUE
	if (a == 4.) { return float3(1.,0.,1.); } //MAGENTA
	if (a == 5.) { return float3(0.,1.,1.); } //CYAN
	else         { return float3(1.,1.,1.); } //WHITE
}
float tri(float x){
	x = (x%2.0);
	if (x > 1.0) x = -x+2.0;
	return x;
}
float chess_dist(float2 uv) {
    return max(abs(uv.x),abs(uv.y));
}

float4 ps(vsout input) : COLOR0
{
	float time = gTime * (0.5 + rate * 2.);
	float2 uv = -1.0 + 2.0 * input.TexCoord.xy / resolution.xy;
	uv.y *= resolution.y/resolution.x;
	float3 colors = color * random_color(floor(uv*size))*step(chess_dist((frac(uv*size)-.5)*2.),tri((((time*speed)+((random(floor(uv*size)))*2.)))));
	float outFX = saturate(opacity * colors);
	return float4(colors * intensity, outFX);
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