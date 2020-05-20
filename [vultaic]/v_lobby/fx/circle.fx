static const float PI = 3.14159265f;
static const float DEG_TO_PI = PI / 180.0f;
static const float START_ANGLE = PI;
static const float TOTAL_ANGLE = -(2 * PI);

texture tex_Source;
float progress = 0.f;

// Original texture sampler (Screen)
sampler sam_Source = sampler_state {
    Texture = <tex_Source>;
};

// Pixel shader structure
struct PSInput {
    float4 Position : POSITION0;
    float4 Diffuse  : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

float4 PSShader(PSInput PS) : COLOR0 {
    // Fetch color at pixel
    float4 result = tex2D(sam_Source, PS.TexCoord);

    // Calculate pixel radian angle, -PI/+PI = Bottom, ascends clockwise
    float angle = atan2(-PS.TexCoord.x + 0.5, PS.TexCoord.y - 0.5);

    // Convert progress to angle inside progress bar space.
    float realAngle = START_ANGLE + TOTAL_ANGLE * progress;

    // Set alpha to 0 if it's above the progress-angle.
    if (angle >= realAngle) {
        result.a = 0;
    }

    // Allows tocolor(r,g,b,a)
    result = result * PS.Diffuse;

    return result;
};

technique circle {
    pass P0 {
        PixelShader = compile ps_2_0 PSShader();
    }
}