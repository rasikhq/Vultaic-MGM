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

float rand(float2 uv)
{
  return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}

float2 uv2tri(float2 uv)
{
  float sx = uv.x - uv.y / 2.0; // skewed x
  float sxf = frac(sx);
  float offs = step(frac(1.0 - uv.y), sxf);
  return float2(floor(sx) * 2.0 + sxf + offs, uv.y);
}

float tri(float2 uv, float time)
{
    float sp = 1.2 + 3.3 * rand(floor(uv2tri(uv)));
    return max(0.0, sin(sp * time));
}

float4 ps(vsout input) : COLOR0
{
	float iGlobalTime = gTime * (0.2 + rate * 1.2);
	float alpha = pow(intensity*2,2)*opacity;
	float3 v = float3(1,0,0);
	float3 d = float3(1,1,1);
	float2 p = input.TexCoord.xy / resolution.xy;
	float nx = abs((p.y-0.5)*-3.*cos(iGlobalTime));
	float3 col = float3(nx,nx,nx);
	float3 invrt =  1.0 - col;
	float2 uv = (input.TexCoord.xy - resolution.xy / 2.0) / resolution.y;
	float t1 = iGlobalTime / 2.0;
	float t2 = t1 + 0.5;
	float c1 = tri(uv * (2.0 + 4.0 * frac(t1)) + floor(t1), iGlobalTime);
	float c2 = tri(uv * (2.0 + 4.0 * frac(t2)) + floor(t2), iGlobalTime);
	float nxrp = lerp(c1, c2, abs(1.0 - 2.0 * frac(t1)));
	float4 lrp = float4(nxrp,nxrp,nxrp,nxrp);
	return float4(invrt,1.)*(lrp*float4(color,alpha));
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