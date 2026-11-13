// Planning fixture. Runtime use requires a matching HDRP package and ASE template.
Shader "ConverterSamples/HighDefinitionColor"
{
    Properties { _Tint ("Tint", Color) = (0.4, 0.6, 0.8, 1) }
    SubShader
    {
        Tags { "RenderPipeline"="HDRenderPipeline" "RenderType"="Opaque" }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            float4 _Tint;
            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionCS : SV_POSITION; float2 uv : TEXCOORD0; };
            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                return o;
            }
            float4 frag(Varyings i) : SV_Target { return _Tint; }
            ENDHLSL
        }
    }
}
