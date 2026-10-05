Texture2D<float4> artwork : register(t0);
SamplerState artwork_sampler : register(s0);
// Shader lab: panel-local pattern. EFFECT_TIME is a frozen sample until a live time binding is validated.
#define EFFECT_TIME (0.75 + (texture_animation > 0.5 ? texture_elapsed : 0))
float hash2(float2 p) { return frac(sin(dot(p,float2(127.1,311.7)))*43758.5453); }
Texture2D<float> __tex_linear_depth : register(t1);
SamplerState __samp_linear_depth : register(s1);
cbuffer global_viewport : register(b0) { float4 screen_viewport : packoffset(c48); };
cbuffer c0 : register(b2) {
    float4 scissor_rect : packoffset(c0);
    float4 atlas_scissor : packoffset(c2);
    float4 clip_box : packoffset(c8);
    float scissor_mode : packoffset(c1.x);
    float threshold_fade : packoffset(c3.x);
};
struct Input { float4 position : SV_POSITION; float4 color : COLOR0;  };
float4 hud_fill(Input input) : SV_TARGET {
    if (fmod(scissor_mode,2) > 0.5) {
        float2 uv=input.position.xy/max(screen_viewport.xy,float2(1,1));
        clip(__tex_linear_depth.SampleLevel(__samp_linear_depth,uv,0)+0.01-threshold_fade);
    }
    float3 screen_point=float3(input.position.xy/max(screen_viewport.xy,float2(1,1)),1);
    float denominator=dot(clip_box.xyz,screen_point);
    clip(abs(denominator)-0.000001);
    float2 panel_uv=float2(dot(scissor_rect.xyz,screen_point),dot(atlas_scissor.xyz,screen_point))/denominator;
    float4 texel=artwork.Sample(artwork_sampler,saturate(panel_uv));
 float2 lo=float2(fmod(scissor_rect.w,1024),floor(scissor_rect.w/1024))/1023;
 float2 hi=float2(fmod(atlas_scissor.w,1024),floor(atlas_scissor.w/1024))/1023;
 if(all(hi>lo)&&all(panel_uv>=lo)&&all(panel_uv<=hi))texel.rgb*=lerp(.18,1,saturate(clip_box.w));
 float texture_scale=max(.25,fmod(floor(scissor_mode/2),256)/32);
 float texture_elapsed=fmod(floor(scissor_mode/512),16384)/16;
 float texture_animation=floor(scissor_mode/8388608);
 panel_uv/=texture_scale;
 float2 p=floor(panel_uv*float2(256,128));float3 rgb=texel.rgb*input.color.rgb;
    float animation=texture_animation > .5 ? 1:0;float elapsed=texture_elapsed;
    float grain=hash2(float2(floor(p.x/12),p.y));rgb*=.75+.25*grain;
    rgb+=animation*.09*pow(saturate(1-abs(frac(p.x/256-elapsed*.08)-.5)*2),12);
    return float4(saturate(rgb),texel.a*input.color.a);
}
