// Retain native vertex color and atlas coverage. Depth uses existing c0 slots.
Texture2D<float4> __tex_diffuse_map : register(t0);
SamplerState __samp_diffuse_map : register(s0);
Texture2D<float> __tex_linear_depth : register(t1);
SamplerState __samp_linear_depth : register(s1);
cbuffer global_viewport : register(b0) {
    float4 screen_viewport : packoffset(c48);
};
cbuffer c0 : register(b2) {
    float scissor_mode : packoffset(c1.x); // scene-depth comparison enabled
    float threshold_fade : packoffset(c3.x); // positive camera depth, metres
};
struct Input {
    float4 position : SV_POSITION;
    float4 color : COLOR0;
    float2 uv : TEXCOORD0;
};
float4 hud_font(Input input) : SV_TARGET {
    if (scissor_mode > 0.5) {
        float2 screen_uv = input.position.xy / max(screen_viewport.xy, float2(1,1));
        float scene_depth = __tex_linear_depth.SampleLevel(__samp_linear_depth,screen_uv,0);
        clip(scene_depth + 0.01 - threshold_fade);
    }
    return __tex_diffuse_map.Sample(__samp_diffuse_map,input.uv) * input.color;
}
