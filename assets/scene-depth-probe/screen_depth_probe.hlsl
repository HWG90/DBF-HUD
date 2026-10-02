// Experimental screen-GUI pixel shader. Not registered or deployed.
// __tex_* follows the native GUI blur shader's renderer-texture naming scheme.
// Binding availability and depth units must be verified in the live UI pass.
Texture2D<float> __tex_linear_depth : register(t0);
SamplerState __samp_linear_depth : register(s0);
cbuffer global_viewport : register(b0) {
    float4 screen_viewport : packoffset(c48);
};
struct Input {
    float4 position : SV_POSITION;
    float4 color : COLOR0;
};

// Access-only probe: visualize sampled depth before enabling any discard.
float4 depth_access(Input input) : SV_TARGET {
    float2 uv = input.position.xy / max(screen_viewport.xy, float2(1, 1));
    float sampled = __tex_linear_depth.SampleLevel(__samp_linear_depth, uv, 0);
    float value = saturate(log2(1 + max(sampled, 0)) / 8);
    return float4(value, value, value, 1);
}

// Later candidate: red/green vertex channels carry a 16-bit camera-depth code.
// Assumes scene linear_depth uses metres; this assumption is not yet verified.
float4 depth_compare(Input input) : SV_TARGET {
    float2 uv = input.position.xy / max(screen_viewport.xy, float2(1, 1));
    float scene_depth = __tex_linear_depth.SampleLevel(__samp_linear_depth, uv, 0);
    float2 bytes = round(saturate(input.color.rg) * 255);
    float marker_depth = (bytes.x + bytes.y * 256) * (64.0 / 65535.0);
    clip(scene_depth + 0.01 - marker_depth);
    return float4(0, 1, 0, 1);
}
