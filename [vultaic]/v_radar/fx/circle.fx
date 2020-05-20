texture tex;
float dg1 = 0;
float dg2 = 0;
float4 rgba1 = float4(0,0,1,1);
float4 rgba2 = float4(1,0,0,1);

static const float PI = 3.14159265f;

sampler Sampler0 = sampler_state
{
    Texture = (tex);
};

float4 PixelShaderFunction(float2 coords: TEXCOORD0) : COLOR0   
{
    float4 color = tex2D(Sampler0,coords);
    coords.xy = coords.yx;

    if (coords.y < 0.5)
    {
        if (dg1 < 0) coords.x = 1 - coords.x;
        float dx = coords.x - 0.5f;
        float dy = coords.y - 0.5f;
        float rad = -PI + abs(dg1) * PI;
        float pos = atan2(dy,dx);
        color.a *= (rad - pos) > 0 ? 1 : 0;
        return color *= rgba1;
    }
    else
    {
        coords.y = 1 - coords.y;
        if (dg2 < 0) coords.x = 1 - coords.x;
        float dx = coords.x - 0.5f;
        float dy = coords.y - 0.5f;
        float rad = -PI + abs(dg2) * PI;
        float pos = atan2(dy,dx);
        color.a *= (rad - pos) > 0 ? 1 : 0;
        return color *= rgba2;
    }	
}
 
technique radarcircle2x
{
    pass Pass0
    {
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
} 
