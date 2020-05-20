texture ScreenSource;
float Alpha = 1;

sampler TextureSampler = sampler_state
{
    Texture = <ScreenSource>;
};
 
float4 PixelShaderFunction(float2 TextureCoordinate : TEXCOORD0) : COLOR0
{
	float4 color = tex2D(TextureSampler, float2(TextureCoordinate.x, TextureCoordinate.y));
	color += tex2D(TextureSampler, float2(TextureCoordinate.x, TextureCoordinate.y));
	color += tex2D(TextureSampler, float2(TextureCoordinate.x, TextureCoordinate.y));
	color += tex2D(TextureSampler, float2(TextureCoordinate.x, TextureCoordinate.y));
    float value = (color.r + color.g + color.b)/3; 
    color.r = value/(2 * Alpha);
    color.g = value/(2 * Alpha);
    color.b = value/(2 * Alpha);
    return color * Alpha;
}
 
technique OldFilm
{
    pass Pass1
    {
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}