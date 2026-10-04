// Contract candidate: retain untextured triangle VS; reconstruct perspective UV per pixel.
Texture2D<float> scene_depth : register(t0);
SamplerState depth_sampler : register(s0);
Texture2D<float4> artwork : register(t1);
SamplerState artwork_sampler : register(s1);
cbuffer global_viewport : register(b0) { float4 screen_viewport : packoffset(c48); };
cbuffer c0 : register(b2) {
 float4 scissor_rect : packoffset(c0);
 float scissor_mode : packoffset(c1.x);
 float4 atlas_scissor : packoffset(c2);
 float threshold_fade : packoffset(c3.x);
 float4 clip_box : packoffset(c8);
};
struct Input { float4 position : SV_POSITION; float4 color : COLOR0; };
float4 hud_fill(Input input) : SV_TARGET {
 float2 screen_uv=input.position.xy/max(screen_viewport.xy,float2(1,1));
 if(scissor_mode>0.5)clip(scene_depth.SampleLevel(depth_sampler,screen_uv,0)+0.01-threshold_fade);
 float3 screen_point=float3(screen_uv,1);
 float denominator=dot(clip_box.xyz,screen_point);clip(abs(denominator)-0.000001);
 float2 uv=float2(dot(scissor_rect.xyz,screen_point),dot(atlas_scissor.xyz,screen_point))/denominator;
 float4 texel=artwork.Sample(artwork_sampler,saturate(uv));
 return texel*input.color; // Straight alpha artwork; material must use standard alpha blending.
}
