Texture2D<float> __tex_linear_depth : register(t0);
SamplerState __samp_linear_depth : register(s0);
cbuffer global_viewport : register(b0) { float4 screen_viewport : packoffset(c48); };
cbuffer c0 : register(b2) {
    float scissor_mode : packoffset(c1.x);
    float threshold_fade : packoffset(c3.x);
};
struct Input { float4 position : SV_POSITION; float4 color : COLOR0; };
float4 hud_fill(Input input) : SV_TARGET {
    if (scissor_mode > 0.5) {
        float2 uv=input.position.xy/max(screen_viewport.xy,float2(1,1));
        clip(__tex_linear_depth.SampleLevel(__samp_linear_depth,uv,0)+0.01-threshold_fade);
    }
    return input.color;
}
