#include "mta-helper.fx"

const float fadedist = 4;

float scale = 4;
float3 pos = 0;
float3 mt = 0;
float3 rt = 0;
float rate = 1;

texture tex;

sampler Sampler0 = sampler_state
{
  Texture = <tex>;
};

 
struct vsin
{
  float4 Position : POSITION;
  //float3 Normal : NORMAL0;
};

struct vsout
{
  float4 Position : POSITION;
  float3 WorldPos : TEXCOORD2;
  //float3 Normal : TEXCOORD3;
};

vsout vs(vsin input)
{
  vsout output;
  output.Position = mul(input.Position,gWorldViewProjection);
  output.WorldPos = MTACalcWorldPosition(input.Position);
  //MTAFixUpNormal(input.Normal);
  //output.Normal = MTACalcWorldNormal(input.Normal);
  return output;
}
 
 
float4 ps(vsout input) : COLOR0
{
  float3 vec = input.WorldPos - pos;
  float deg = dot(vec,mt)/length(vec);
  /*if (deg < 0.0f) 
    discard;*/
  clip(deg);
  float nd = (fadedist-length(deg*vec))/fadedist;
  /*if (nd <= 0.0f)
    discard;*/
  clip(nd);
  float3 sinn,coss;
  sincos(rt,sinn,coss);
  // Old method of multiplying 3 matrices against the vector
  float3x3 matrixX = {1.0f,0.0f,0.0f,0.0f,coss.y,-sinn.y,0.0f,sinn.y,coss.y};
  float3x3 matrixY = {coss.x,0.0f,sinn.x,0.0f,1.0f,0.0f,-sinn.x,0.0f,coss.x};
  float3x3 matrixZ = {coss.z,-sinn.z,0.0f,sinn.z,coss.z,0.0f,0.0f,0.0f,1.0f};
  float3 position = mul(matrixX,mul(matrixY,mul(matrixZ,vec)));
  // New method of a sorted transformation array. Which is better - no idea
  //float2 position = {coss.y*(coss.z*vec[0]-sinn.z*vec[1])+sinn.y*vec[2],coss.x*(sinn.z*vec[0]+coss.z*vec[1])-sinn.x*(-sinn.y*(coss.z*vec[0]-sinn.z*vec[1])+coss.y*vec[2])};
  
  position /= scale;
  if (abs(position.x) > 0.5f || abs(position.y) > 0.5f)
    discard;
  //clip(-abs(position)+0.5);
  //position += float2(0.5f,0.5f);
  position += 0.5f;
  //position.y = 1.0f-position.y;
  float4 color = tex2D(Sampler0,position);
  color.a *= nd * abs(sin(gTime*rate))*0.75;
  return color;
}
 
technique tec
{
  pass Pass0
  {
    DepthBias = -0.0002;
    VertexShader = compile vs_3_0 vs();
    PixelShader = compile ps_3_0 ps();
  }
}