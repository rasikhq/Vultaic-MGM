float4 rgba = float4(0., 0., 0., 0.);

struct PSInput
{
	float4 Diffuse : COLOR0;
	float2 uv : TEXCOORD0;
};

float4 pass1_ps(PSInput PS) : COLOR0 {
	return rgba * pow(PS.Diffuse, 0.2);
}

technique complercated {
	pass P0 {
		FillMode = WireFrame;
		PixelShader  = compile ps_2_0 pass1_ps();
	}
}