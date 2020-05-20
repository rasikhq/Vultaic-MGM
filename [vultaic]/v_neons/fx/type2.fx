#include "mta-helper.fx"

static float neonlength = 2.25;

float3 pos = 0;
float3 mt = 0;
float3 rgb = 0;

float rate = 1;

 
struct vsin
{
  float4 Position : POSITION;
};
 
struct vsout
{
  float4 Position : POSITION;
  float3 WorldPos : TEXCOORD2;
};
 
vsout vs(vsin input)
{
  vsout output;
  output.Position = mul(input.Position,gWorldViewProjection);
  output.WorldPos = MTACalcWorldPosition(input.Position);;
  return output;
}
 
 
float4 ps(vsout input) : COLOR0
{
  float3 vec = input.WorldPos - pos;
  float lvec = length(vec);
  float nl = neonlength - 0.75f + abs(sin(gTime*rate))/4.0f*3.0f;
  if (lvec > nl || dot(vec,mt)/lvec < 0.0f) 
    discard;
  return float4(rgb,pow((nl - lvec)*2.0f/neonlength,2.0f)/2.0f);
}
 
technique tec
{
  pass Pass0
  {
    //ShadeMode = Flat;
    DepthBias=-0.0002;
    NormalizeNormals = false;
    VertexShader = compile vs_2_0 vs();
    PixelShader = compile ps_2_0 ps();
  }
}