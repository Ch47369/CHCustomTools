// Converter-owned mesh host for the reviewed unlit glitter source.
// Vertex tangent-view normalization/interpolation matches the source.
// The node graph contains all material calculations; no lighting/fog/exposure is added.
Shader /*ase_name*/"Hidden/ASE Converter/Parallax Glitter URP"/*end*/
{
    Properties
    {
        /*ase_props*/
    }
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderPipeline"="UniversalPipeline" }
        Cull Back
        ZWrite On
        ZTest LEqual
        Blend Off
        /*ase_pass*/
        LOD 100
        Pass
        {
            Name "Unlit"
            Tags { "LightMode"="SRPDefaultUnlit" }
            CGPROGRAM
            #pragma target 4.5
            #pragma vertex FilterVertex
            #pragma fragment FilterFragment
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #include "UnityCG.cginc"
            #if defined(SHADER_API_GLES)
                #define TEXTURE2D(name) sampler2D name
                #define SAMPLER(name)
                #define SAMPLE_TEXTURE2D(tex, state, uv) tex2D(tex, uv)
                #define SAMPLE_TEXTURE2D_LOD(tex, state, uv, lod) tex2Dlod(tex, float4(uv, 0, lod))
            #else
                #define TEXTURE2D(name) Texture2D name
                #define SAMPLER(name) SamplerState name
                #define SAMPLE_TEXTURE2D(tex, state, uv) tex.Sample(state, uv)
                #define SAMPLE_TEXTURE2D_LOD(tex, state, uv, lod) tex.SampleLevel(state, uv, lod)
            #endif
            // ASE SRP Time nodes use seconds from _TimeParameters.x. Preserve
            // the source's engine time even for explicit Blit without a camera.
            #define _TimeParameters float4(_Time.y, sin(_Time.y), cos(_Time.y), 0.0)
            /*ase_pragma*/
            struct FilterInput
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                /*ase_vdata:p=p;uv0=tc0.xy;n=n;t=t*/
            };
            struct FilterVaryings
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 tangentView : TEXCOORD1;
                /*ase_interp(2,):sp=sp.xyzw;uv0=tc0.xy*/
            };
            /*ase_globals*/
            FilterVaryings FilterVertex(FilterInput v /*ase_vert_input*/)
            {
                FilterVaryings o;
                /*ase_vert_code:v=FilterInput;o=FilterVaryings*/
                v.position.xyz += /*ase_vert_out:Offset;Float3*/float3(0,0,0)/*end*/;
                o.position = UnityObjectToClipPos(v.position);
                o.uv = v.uv;
                float3 binormal = cross(v.normal,v.tangent.xyz)*v.tangent.w;
                float3 objectView = ObjSpaceViewDir(v.position);
                o.tangentView = normalize(mul(float3x3(v.tangent.xyz,binormal,v.normal),objectView));
                return o;
            }
            float4 FilterFragment(FilterVaryings i /*ase_frag_input*/) : SV_Target
            {
                /*ase_local_var*/float3 ase_tangentView = i.tangentView;
                /*ase_frag_code:i=FilterVaryings*/
                clip(/*ase_frag_out:Clip;Float*/1/*end*/ - 0.5);
                return /*ase_frag_out:Color;Float4*/float4(1,1,1,1)/*end*/;
            }
            ENDCG
        }
    }
    Fallback "Transparent/Cutout/VertexLit"
}
