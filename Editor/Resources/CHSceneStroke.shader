Shader "Hidden/CHCustomTools/SceneStroke"
{
    Properties { [HideInInspector] _ZTest ("Depth", Float) = 8 }
    SubShader
    {
        Pass
        {
            ZWrite Off Cull Off ZTest [_ZTest]
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            float4x4 _CHSceneProjection;
            struct Input { float4 vertex : POSITION; float4 color : COLOR; };
            struct Varying { float4 position : SV_POSITION; float4 color : COLOR; };
            Varying vert(Input input)
            {
                Varying output; output.position = mul(_CHSceneProjection, input.vertex); output.color = input.color; return output;
            }
            float4 frag(Varying input) : SV_Target { return input.color; }
            ENDCG
        }
    }
}
