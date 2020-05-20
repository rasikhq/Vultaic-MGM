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

float pnt(float2 src, float2 target) {
  return pow(0.001 / distance(target, src), 1.);
}

float segment(float2 src, float2 t1, float2 t2) {
  if(t2.y == t1.y) {
    if(t1.x > t2.x) {
      float2 tmp = t1;
      t1 = t2;
      t2 = tmp;
    }
    if(src.x <= t1.x)
      return pnt(src, t1);
    if(src.x >= t2.x)
      return pnt(src, t2);
    return pnt(src, float2(src.x, t1.y));
  }
  if(t2.y > t1.y) {
    float2 tmp = t1;
    t1 = t2;
    t2 = tmp;
  }
  if(t2.x == t1.x) {
    if(src.y >= t1.y)
      return pnt(src, t1);
    if(src.y <= t2.y)
      return pnt(src, t2);
    return pnt(src, float2(t1.x, src.y));
  }
  float k = (t2.y - t1.y) / (t2.x - t1.x), b = t1.y - k * t1.x;
  float norm_k = -1. / k;
  float b1 = t1.y - norm_k * t1.x;
  float b2 = t2.y - norm_k * t2.x;
  float base = src.x * norm_k;
  if(src.y == base + b1)
    return pnt(src, t1);
  if(src.y < base + b2)
    return pnt(src, t2);
  float src_b = src.y - base;
  float ix = (src_b - b) / (k - norm_k);
  float iy = norm_k * ix + src_b;
  return pnt(src, float2(ix, iy));
}


float2 to_local(float2 a) {
  return a * 1 * 2. / resolution;
}

float2 to_2d(float3 a) {
  float H_FOV = -70., F = 1 / 2. / tan(radians(H_FOV / 2.));
  return float2(F * a.x / (a.z + F), F * a.y / (a.z + F));
}

float side(float2 src, float3 center, float size, float y, float angle) {
  return segment(src, to_2d(center + float3(cos(angle) * size,  y, sin(angle) * size)), to_2d(center + float3(cos(angle + PI / 2.) * size, y, sin(angle + PI / 2.) * size)));
}

float sidev(float2 src, float3 center, float size, float y, float angle) {
  return segment(src, to_2d(center + float3(cos(angle) * size, y, sin(angle) * size)), to_2d(center + float3(cos(angle) * size, -y, sin(angle) * size)));
}

float cube(float2 src, float3 center, float size, float time) {
  float color = 0., h = size / 2., diagonal = length(float2(h, h)), angle = time;

  color += side(src, center, diagonal, h, angle);
  color += side(src, center, diagonal, h, angle + PI / 2.);
  color += side(src, center, diagonal, h, angle + PI);
  color += side(src, center, diagonal, h, angle + PI * 3. / 2.);

  color += side(src, center, diagonal, -h, angle);
  color += side(src, center, diagonal, -h, angle + PI / 2.);
  color += side(src, center, diagonal, -h, angle + PI);
  color += side(src, center, diagonal, -h, angle + PI * 3. / 2.);

  return color;
}

float4 ps(vsout input) : COLOR0
{
	float iGlobalTime = gTime * (0.5 + rate);
	float alpha = pow(intensity*2,2)*opacity;
	float2 coord = to_local(input.TexCoord.xy - resolution / 2.);
	float cb = cube(coord, float3(0., sin(iGlobalTime) * 0.7, 0.5), 0.5, iGlobalTime);
	float3 texcolor = cb * color;
	float outFX = saturate(opacity * alpha * texcolor);
	return float4(texcolor,outFX);
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