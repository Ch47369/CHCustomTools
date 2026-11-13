// Converter-owned raw image filter template. Input/output share the caller's
// color encoding. No camera injection, lighting, tone mapping, fog or exposure.
Shader /*ase_name*/"Hidden/ASE Converter/Image Filter HDRP"/*end*/
{
    Properties
    {
        /*ase_props*/
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="HDRenderPipeline" }
        Cull Off
        ZWrite Off
        ZTest Always
        Blend Off
        /*ase_pass*/
        Pass
        {
            Name "Unlit"
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex FilterVertex
            #pragma fragment FilterFragment
            #include "UnityCG.cginc"
            #if defined(SHADER_API_GLES)
                #define TEXTURE2D(name) sampler2D name
                #define SAMPLER(name)
                #define SAMPLE_TEXTURE2D(tex, state, uv) tex2D(tex, uv)
            #else
                #define TEXTURE2D(name) Texture2D name
                #define SAMPLER(name) SamplerState name
                #define SAMPLE_TEXTURE2D(tex, state, uv) tex.Sample(state, uv)
            #endif
            // ASE SRP Time nodes use seconds from _TimeParameters.x. Preserve
            // the source's engine time even for explicit Blit without a camera.
            #define _TimeParameters float4(_Time.y, sin(_Time.y), cos(_Time.y), 0.0)
            /*ase_pragma*/
            struct FilterInput
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                /*ase_vdata:p=p;uv0=tc0.xy*/
            };
            struct FilterVaryings
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                /*ase_interp(1,):sp=sp.xyzw;uv0=tc0.xy*/
            };
            /*ase_globals*/
            FilterVaryings FilterVertex(FilterInput v /*ase_vert_input*/)
            {
                FilterVaryings o;
                /*ase_vert_code:v=FilterInput;o=FilterVaryings*/
                v.position.xyz += /*ase_vert_out:Offset;Float3*/float3(0,0,0)/*end*/;
                o.position = UnityObjectToClipPos(v.position);
                o.uv = v.uv;
                return o;
            }
            float4 FilterFragment(FilterVaryings i /*ase_frag_input*/) : SV_Target
            {
                /*ase_frag_code:i=FilterVaryings*/
                return /*ase_frag_out:Color;Float4*/float4(1,1,1,1)/*end*/;
            }
            ENDCG
        }
    }
}
