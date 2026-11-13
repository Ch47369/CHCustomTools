// Converter-owned template for the reviewed two-sided Unlit texture/fog contract.
Shader /*ase_name*/"Hidden/ASE Converter/Two Sided Texture Fog"/*end*/
{
    Properties
    {
        /*ase_props*/
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off
        /*ase_pass*/
        Pass
        {
            Name "Unlit"
            CGPROGRAM
            #pragma target 2.5
            #pragma vertex TextureVertex
            #pragma fragment TextureFragment
            #pragma multi_compile_fog
            #include "UnityCG.cginc"
            /*ase_pragma*/
            struct TextureInput
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                /*ase_vdata:p=p;uv0=tc0.xy*/
            };
            struct TextureVaryings
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                /*ase_interp(2,):sp=sp.xyzw;uv0=tc0.xy*/
            };
            float4 _MainTex_ST;
            /*ase_globals*/
            TextureVaryings TextureVertex(TextureInput v /*ase_vert_input*/)
            {
                TextureVaryings o;
                /*ase_vert_code:v=TextureInput;o=TextureVaryings*/
                v.position.xyz += /*ase_vert_out:Offset;Float3*/float3(0,0,0)/*end*/;
                o.position = UnityObjectToClipPos(v.position);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.position);
                return o;
            }
            fixed4 TextureFragment(TextureVaryings i /*ase_frag_input*/) : SV_Target
            {
                /*ase_frag_code:i=TextureVaryings*/
                fixed4 color = /*ase_frag_out:Color;Float4*/float4(1,1,1,1)/*end*/;
                UNITY_APPLY_FOG(i.fogCoord, color);
                return color;
            }
            ENDCG
        }
    }
}
