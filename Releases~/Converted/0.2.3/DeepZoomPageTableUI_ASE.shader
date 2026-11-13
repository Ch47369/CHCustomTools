// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
// Converter-owned template: straight alpha, hard rectangular clipping, global UI variants.
Shader "DeepZoom/DeepZoomPageTableUI_ASE"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)
        [HideInInspector] _StencilComp("Stencil Comparison", Float) = 8
        [HideInInspector] _Stencil("Stencil ID", Float) = 0
        [HideInInspector] _StencilOp("Stencil Operation", Float) = 0
        [HideInInspector] _StencilWriteMask("Stencil Write Mask", Float) = 255
        [HideInInspector] _StencilReadMask("Stencil Read Mask", Float) = 255
        [HideInInspector] _ColorMask("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
        _TileArray( "Tile Array", 2DArray ) = "white" {}
        [HideInInspector][NoScaleOffset] _PageTableTransform( "Page Table Transform", 2D ) = "black" {}
        [HideInInspector][NoScaleOffset] _PageTableLayer( "Page Table Layer", 2D ) = "black" {}
        [HideInInspector] _PageTableGrid( "Page Table Grid", Vector ) = ( 1, 1, 1, 1 )
        [HideInInspector] _FallbackTex( "Previous Image", 2D ) = "black" {}
        [HideInInspector] _ViewRect( "View Rect", Vector ) = ( 0, 0, 1, 1 )
        [HideInInspector] _FlipHorizontally( "Flip Horizontally", Float ) = 0

    }
    SubShader
    {
		LOD 0

        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }
        Stencil
        {
        	Ref [_Stencil]
        	ReadMask [_StencilReadMask]
        	WriteMask [_StencilWriteMask]
        	Comp [_StencilComp]
        	Pass [_StencilOp]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]
        
        Pass
        {
            Name "UI"
            CGPROGRAM
            #define ASE_VERSION 19913
            #define ASE_USING_SAMPLING_MACROS 1

            #pragma target 3.5
            #pragma vertex UiVertex
            #pragma fragment UiFragment
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            #define ASE_NEEDS_TEXTURE_COORDINATES0
            #define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
            #if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
            #define SAMPLE_TEXTURE2D_LOD(tex,samplerTex,coord,lod) tex.SampleLevel(samplerTex,coord, lod)
            #define SAMPLE_TEXTURE2D_ARRAY_LOD(tex,samplerTex,coord,lod) tex.SampleLevel(samplerTex,coord, lod)
            #else//ASE Sampling Macros
            #define SAMPLE_TEXTURE2D_LOD(tex,samplerTex,coord,lod) tex2Dlod(tex,float4(coord,0,lod))
            #define SAMPLE_TEXTURE2D_ARRAY_LOD(tex,samplertex,coord,lod) tex2DArraylod(tex, float4(coord,lod))
            #endif//ASE Sampling Macros
            

            struct UiInput
            {
                float4 position : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                
            };
            struct UiVaryings
            {
                float4 position : SV_POSITION;
                fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
                float4 localPosition : TEXCOORD1;
                
            };
            fixed4 _Color;
            float4 _ClipRect;
            UNITY_DECLARE_TEX2D_NOSAMPLER(_FallbackTex);
            uniform float4 _ViewRect;
            uniform float _FlipHorizontally;
            SamplerState sampler_FallbackTex;
            UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_TileArray);
            UNITY_DECLARE_TEX2D_NOSAMPLER(_PageTableTransform);
            uniform float4 _PageTableGrid;
            SamplerState sampler_PageTableTransform;
            UNITY_DECLARE_TEX2D_NOSAMPLER(_PageTableLayer);
            SamplerState sampler_PageTableLayer;
            SamplerState sampler_TileArray;

            UiVaryings UiVertex(UiInput v )
            {
                UiVaryings o;
                
                v.position.xyz += float3(0,0,0);
                o.position = UnityObjectToClipPos(v.position);
                o.localPosition = v.position;
                o.uv = v.uv;
                o.color = v.color * _Color;
                return o;
            }
            fixed4 UiFragment(UiVaryings i ) : SV_Target
            {
                float4 ase__ViewRect_9999 = _ViewRect;
                float2 texCoord8 = i.uv.xy * float2( 1,1 ) + float2( 0,0 );
                float temp_output_13_0 = (texCoord8).x;
                float ifLocalVar14 = 0;
                if( _FlipHorizontally <= 0.5 )
                {
                	ifLocalVar14 = temp_output_13_0;
                }
                else
                {
                	ifLocalVar14 = ( 1.0 - (texCoord8).x );
                }
                float ase_n14_9797 = (texCoord8).y;
                float2 appendResult16 = (float2(ifLocalVar14 , ase_n14_9797));
                float2 temp_output_20_0 = ( (ase__ViewRect_9999).xy + ( appendResult16 * (ase__ViewRect_9999).zw ) );
                float4 appendResult73 = (float4((temp_output_20_0).x , (temp_output_20_0).y , 0.0 , 0.0));
                float4 ase_fallback_121121 = SAMPLE_TEXTURE2D_LOD( _FallbackTex, sampler_FallbackTex, (appendResult73).xy, (appendResult73).w );
                float2 ase_imageUV_101101 = temp_output_20_0;
                float2 appendResult28 = (float2((temp_output_20_0).x , ( 1.0 - (ase_imageUV_101101).y )));
                float4 ase__PageTableGrid_103103 = _PageTableGrid;
                float2 ase_cell_107107 = floor( ( appendResult28 * (ase__PageTableGrid_103103).xy ) );
                float2 temp_cast_0 = (0.0).xx;
                float2 ase_cellCount_105105 = ( 1.0 / (_PageTableGrid).zw );
                float2 clampResult35 = clamp( ase_cell_107107 , temp_cast_0 , ( ase_cellCount_105105 - 1.0 ) );
                float2 temp_output_39_0 = ( ( clampResult35 + 0.5 ) * (ase__PageTableGrid_103103).zw );
                float4 appendResult44 = (float4((temp_output_39_0).x , (temp_output_39_0).y , 0.0 , 0.0));
                float4 tex2DNode45 = SAMPLE_TEXTURE2D_LOD( _PageTableTransform, sampler_PageTableTransform, (appendResult44).xy, (appendResult44).w );
                float2 temp_output_59_0 = ( ( ase_imageUV_101101 * (tex2DNode45).rg ) + (tex2DNode45).ba );
                float2 ase_pageUV_110110 = temp_output_39_0;
                float4 appendResult52 = (float4((ase_pageUV_110110).x , (ase_pageUV_110110).y , 0.0 , 0.0));
                float4 ase_info_114114 = SAMPLE_TEXTURE2D_LOD( _PageTableLayer, sampler_PageTableLayer, (appendResult52).xy, (appendResult52).w );
                float3 appendResult64 = (float3((temp_output_59_0).x , (temp_output_59_0).y , round( (ase_info_114114).r )));
                float ase_n67_119119 = 0.0;
                float4 ase_tileColor_123123 = SAMPLE_TEXTURE2D_ARRAY_LOD( _TileArray, sampler_TileArray, float3((appendResult64).xy,(appendResult64).z), ase_n67_119119 );
                float ase_inside_117117 = ( ( ( step( 0.0 , (ase_imageUV_101101).x ) * step( (ase_imageUV_101101).x , 1.0 ) ) * step( 0.0 , (ase_imageUV_101101).y ) ) * step( (ase_imageUV_101101).y , 1.0 ) );
                float4 lerpResult96 = lerp( ase_fallback_121121 , ase_tileColor_123123 , ( step( 0.5 , (ase_info_114114).g ) * ase_inside_117117 ));
                
                fixed4 color = lerpResult96;
                color *= i.color;
                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(i.localPosition.xy, _ClipRect);
                #endif
                #ifdef UNITY_UI_ALPHACLIP
                clip(color.a - 0.001);
                #endif
                return color;
            }
            ENDCG
        }
    }
	
	CustomEditor "AmplifyShaderEditor.MaterialInspector"
	Fallback Off
}
/*ASEBEGIN
Version=19913
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":128,"pos":[0,15],"params":["Inherit","False","800","1180","这些属性提供纹理、颜色和参数；属性名与原 Shader 一致。","5","4","6","7","99","103","材质输入","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":134,"pos":[5060,2085],"params":["Inherit","False","2800","1545","向下取整定位网格单元。表达式：floor(float2(imageUV.x, 1.0 - imageUV.y) * _PageTableGrid.xy)","11","24","25","26","27","28","29","30","31","102","104","107","计算 cell","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":4,"pos":[50,115],"params":["Inherit","False","Property","_PageTableGrid","Page Table Grid","3","1","[HideInInspector]","Create","False","0","0","0","True","0","False","Object","-1","","1,1,1,1","1,1,1,1","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":102,"pos":[5110,2915],"params":["Inherit","False","101","ase_imageUV_101","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":25,"pos":[5110,2550],"params":["Inherit","False","Constant","_Float3","Float 3","7","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":26,"pos":[5510,2185],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":103,"pos":[450,480],"params":["Inherit","False","ase__PageTableGrid_103","-1","True","1","0","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":24,"pos":[5110,2185],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":27,"pos":[5910,2185],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":104,"pos":[5110,3280],"params":["Inherit","False","103","ase__PageTableGrid_103","1","0","OBJECT","","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":133,"pos":[1020,15],"params":["Inherit","False","1200","815","按连线计算并传递结果。表达式：1.0 / _PageTableGrid.zw","4","21","22","23","105","计算 cellCount","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":21,"pos":[1070,115],"params":["Inherit","False","Constant","_Float2","Float 2","7","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":22,"pos":[1070,480],"params":["Inherit","False","FLOAT2","2","3","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":28,"pos":[6310,2185],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":29,"pos":[5510,2550],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":23,"pos":[1470,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":30,"pos":[6710,2185],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.FloorOpNode, AmplifyShaderEditor","id":31,"pos":[7110,2185],"params":["Inherit","False","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":105,"pos":[1870,115],"params":["Inherit","False","ase_cellCount_105","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":135,"pos":[8080,15],"params":["Inherit","False","1200","1545","限制数值范围。表达式：clamp(cell, 0.0, cellCount - 1.0)","6","32","33","34","35","106","108","计算 cell","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":33,"pos":[8130,480],"params":["Inherit","False","Constant","_Float5","Float 5","7","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":106,"pos":[8130,845],"params":["Inherit","False","105","ase_cellCount_105","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":107,"pos":[7510,2185],"params":["Inherit","False","ase_cell_107","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":32,"pos":[8130,115],"params":["Inherit","False","Constant","_Float4","Float 4","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":34,"pos":[8530,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":108,"pos":[8130,1210],"params":["Inherit","False","107","ase_cell_107","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":136,"pos":[9500,15],"params":["Inherit","False","1600","815","按连线计算并传递结果。表达式：(cell + 0.5) * _PageTableGrid.zw","6","36","37","38","39","109","110","计算 pageUV","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":35,"pos":[8930,115],"params":["Inherit","False","3","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","2","FLOAT2","1,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":36,"pos":[9550,115],"params":["Inherit","False","Constant","_Float6","Float 6","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":109,"pos":[9550,480],"params":["Inherit","False","103","ase__PageTableGrid_103","1","0","OBJECT","","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":37,"pos":[9950,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":38,"pos":[9950,480],"params":["Inherit","False","FLOAT2","2","3","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":110,"pos":[10750,115],"params":["Inherit","False","ase_pageUV_110","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":127,"pos":[11320,2085],"params":["Inherit","False","2400","1545","以显式 LOD 读取纹理。表达式：tex2Dlod(_PageTableLayer, float4(pageUV, 0, 0))","11","3","48","49","50","51","52","53","54","55","111","114","计算 info","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":39,"pos":[10350,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":111,"pos":[11370,3280],"params":["Inherit","False","110","ase_pageUV_110","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":126,"pos":[11320,15],"params":["Inherit","False","1600","1910","以显式 LOD 读取纹理。表达式：tex2Dlod(_PageTableTransform, float4(pageUV, 0, 0))","9","2","40","41","42","43","44","45","46","47","计算 transform","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":130,"pos":[0,1355],"params":["Inherit","False","640","450","按连线计算并传递结果。表达式：input.uv","1","8","计算 viewUV","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":8,"pos":[50,1455],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":40,"pos":[11370,480],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":41,"pos":[11370,845],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":42,"pos":[11370,1210],"params":["Inherit","False","Constant","_Float7","Float 7","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":43,"pos":[11370,1575],"params":["Inherit","False","Constant","_Float8","Float 8","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":48,"pos":[11770,2185],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":49,"pos":[11770,2550],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":50,"pos":[11370,2550],"params":["Inherit","False","Constant","_Float9","Float 9","8","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":51,"pos":[11370,2915],"params":["Inherit","False","Constant","_Float10","Float 10","8","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":131,"pos":[1020,990],"params":["Inherit","False","1600","1910","比较输入并选择分支，更新局部变量；保留相等时的分支结果。","10","9","10","11","12","13","14","15","16","97","98","条件选择","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":10,"pos":[1070,1455],"params":["Inherit","False","Constant","_Float1","Float 1","7","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":11,"pos":[1070,1820],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":15,"pos":[1070,2550],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":44,"pos":[11770,115],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":52,"pos":[12170,2185],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":2,"pos":[11370,115],"params":["Inherit","True","Property","_PageTableTransform","Page Table Transform","1","2","[HideInInspector]","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":3,"pos":[11370,2185],"params":["Inherit","True","Property","_PageTableLayer","Page Table Layer","2","2","[HideInInspector]","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":6,"pos":[50,480],"params":["Inherit","False","Property","_ViewRect","View Rect","5","1","[HideInInspector]","Create","False","0","0","0","True","0","False","Object","-1","","0,0,1,1","0,0,1,1","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":7,"pos":[50,845],"params":["Inherit","False","Property","_FlipHorizontally","Flip Horizontally","6","1","[HideInInspector]","Create","False","0","0","0","True","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":9,"pos":[1070,1090],"params":["Inherit","False","Constant","_Float0","Float 0","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":12,"pos":[1470,1090],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":13,"pos":[1070,2185],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":46,"pos":[12170,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":47,"pos":[12170,480],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":54,"pos":[12570,2185],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":55,"pos":[12570,2550],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":97,"pos":[1470,1455],"params":["Inherit","False","ase_n14_97","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":132,"pos":[2840,15],"params":["Inherit","False","2000","815","按连线计算并传递结果。表达式：_ViewRect.xy + viewUV * _ViewRect.zw","6","17","18","19","20","100","101","计算 imageUV","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":14,"pos":[1870,1090],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","4","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":45,"pos":[12570,115],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","7","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":53,"pos":[12970,2185],"params":["Inherit","True","Property","_TextureSample1","Texture Sample 1","8","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":98,"pos":[1870,1455],"params":["Inherit","False","97","ase_n14_97","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":99,"pos":[450,115],"params":["Inherit","False","ase__ViewRect_99","-1","True","1","0","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":101,"pos":[4490,115],"params":["Inherit","False","ase_imageUV_101","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":137,"pos":[13940,15],"params":["Inherit","False","1200","1180","按连线计算并传递结果。表达式：imageUV * transform.xy + transform.zw","5","56","57","58","59","113","计算 tileUV","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":138,"pos":[5060,3790],"params":["Inherit","False","2800","1910","用阈值产生 0/1 选择信号。表达式：step(0.0, imageUV.x) * step(imageUV.x, 1.0) * step(0.0, imageUV.y) * step(imageUV.y, 1.0)","17","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","112","117","计算 inside","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":16,"pos":[2270,1090],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":18,"pos":[3290,480],"params":["Inherit","False","FLOAT2","2","3","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":56,"pos":[13990,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":100,"pos":[2890,115],"params":["Inherit","False","99","ase__ViewRect_99","1","0","OBJECT","","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":112,"pos":[5110,5350],"params":["Inherit","False","101","ase_imageUV_101","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":113,"pos":[13990,845],"params":["Inherit","False","101","ase_imageUV_101","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":114,"pos":[13370,2185],"params":["Inherit","False","ase_info_114","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":125,"pos":[15360,15],"params":["Inherit","False","2800","1910","以显式 LOD 读取纹理；取最近整数作为索引。表达式：UNITY_SAMPLE_TEX2DARRAY_LOD(_TileArray, float3(tileUV, round(info.x)), 0)","14","1","60","61","62","63","64","65","66","67","68","115","119","120","123","计算 tileColor","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":17,"pos":[3290,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":19,"pos":[3690,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":57,"pos":[14390,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":58,"pos":[13990,480],"params":["Inherit","False","FLOAT2","2","3","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":77,"pos":[5110,3890],"params":["Inherit","False","Constant","_Float14","Float 14","11","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":78,"pos":[5510,3890],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":80,"pos":[5510,4255],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":81,"pos":[5110,4255],"params":["Inherit","False","Constant","_Float15","Float 15","11","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":115,"pos":[15410,1575],"params":["Inherit","False","114","ase_info_114","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":20,"pos":[4090,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":59,"pos":[14790,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":62,"pos":[15810,115],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":79,"pos":[5910,3890],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":82,"pos":[5910,4255],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":84,"pos":[5110,4620],"params":["Inherit","False","Constant","_Float16","Float 16","11","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":85,"pos":[5510,4620],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":129,"pos":[5060,15],"params":["Inherit","False","2000","1910","以显式 LOD 读取纹理。表达式：tex2Dlod(_FallbackTex, float4(imageUV, 0, 0))","10","5","69","70","71","72","73","74","75","76","121","计算 fallback","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":60,"pos":[15410,480],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":61,"pos":[15410,845],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RoundOpNode, AmplifyShaderEditor","id":63,"pos":[16210,115],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":68,"pos":[15410,1210],"params":["Inherit","False","Constant","_Float11","Float 11","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":69,"pos":[5110,480],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":70,"pos":[5110,845],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":71,"pos":[5110,1210],"params":["Inherit","False","Constant","_Float12","Float 12","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":72,"pos":[5110,1575],"params":["Inherit","False","Constant","_Float13","Float 13","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":83,"pos":[6310,3890],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":86,"pos":[5910,4620],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":88,"pos":[5510,4985],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":89,"pos":[5110,4985],"params":["Inherit","False","Constant","_Float17","Float 17","11","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":64,"pos":[16610,115],"params":["Inherit","False","FLOAT3","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":73,"pos":[5510,115],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":87,"pos":[6710,3890],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":90,"pos":[5910,4985],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":119,"pos":[15810,480],"params":["Inherit","False","ase_n67_119","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":139,"pos":[18380,15],"params":["Inherit","False","2000","1910","按加载状态与图像范围选择备用图或 Tile；模板再应用顶点色、Tint、UI 裁剪、Stencil 和透明混合。","9","92","93","94","95","96","116","118","122","124","计算 color","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":1,"pos":[15410,115],"params":["Inherit","True","Property","_TileArray","Tile Array","0","0","Create","False","0","0","0","True","0","False","","None","None","False","white","LockedToTexture2DArray","Texture2DArray","False","-1","0","2","SAMPLER2DARRAY","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":5,"pos":[5110,115],"params":["Inherit","True","Property","_FallbackTex","Previous Image","4","1","[HideInInspector]","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":66,"pos":[17010,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":67,"pos":[17010,480],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":75,"pos":[5910,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":76,"pos":[5910,480],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":91,"pos":[7110,3890],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":116,"pos":[18430,480],"params":["Inherit","False","114","ase_info_114","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":120,"pos":[16210,480],"params":["Inherit","False","119","ase_n67_119","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":65,"pos":[17410,115],"params":["Inherit","True","Property","_TextureSample2","Texture Sample 2","9","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2DArray","False","8","0","SAMPLER2DARRAY","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":74,"pos":[6310,115],"params":["Inherit","True","Property","_TextureSample3","Texture Sample 3","10","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":92,"pos":[18430,115],"params":["Inherit","False","Constant","_Float18","Float 18","11","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":93,"pos":[18830,115],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":117,"pos":[7510,3890],"params":["Inherit","False","ase_inside_117","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":94,"pos":[19230,115],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":118,"pos":[18430,845],"params":["Inherit","False","117","ase_inside_117","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":121,"pos":[6710,115],"params":["Inherit","False","ase_fallback_121","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":123,"pos":[17810,115],"params":["Inherit","False","ase_tileColor_123","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":95,"pos":[19630,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":122,"pos":[18430,1210],"params":["Inherit","False","121","ase_fallback_121","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":124,"pos":[18430,1575],"params":["Inherit","False","123","ase_tileColor_123","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":96,"pos":[20030,115],"params":["Inherit","False","3","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","2","FLOAT","0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[20730,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","DeepZoom/DeepZoomPageTableUI_ASE","eab467e6cd0b4d27ab8e9e434d8c30e3","True","UI","0","0","UI","2","False","True","2","5","False","","10","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","True","True","True","True","True","0","True","_ColorMask","False","False","False","False","False","False","False","True","True","0","True","_Stencil","255","True","_StencilReadMask","255","True","_StencilWriteMask","0","True","_StencilComp","0","True","_StencilOp","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","2","False","","True","0","True","unity_GUIZTestMode","False","False","True","5","Queue=Transparent=Queue=0","IgnoreProjector=True","RenderType=Transparent=RenderType","PreviewType=Plane","CanUseSpriteAtlas=True","False","False","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","3","False","0","","0","0","Standard","0","0","1","True","False","","True","0"]}
{"wire":[26,0,102,0]}
{"wire":[103,0,4,0]}
{"wire":[24,0,20,0]}
{"wire":[27,0,25,0]}
{"wire":[27,1,26,0]}
{"wire":[22,0,4,0]}
{"wire":[28,0,24,0]}
{"wire":[28,1,27,0]}
{"wire":[29,0,104,0]}
{"wire":[23,0,21,0]}
{"wire":[23,1,22,0]}
{"wire":[30,0,28,0]}
{"wire":[30,1,29,0]}
{"wire":[31,0,30,0]}
{"wire":[105,0,23,0]}
{"wire":[107,0,31,0]}
{"wire":[34,0,106,0]}
{"wire":[34,1,33,0]}
{"wire":[35,0,108,0]}
{"wire":[35,1,32,0]}
{"wire":[35,2,34,0]}
{"wire":[37,0,35,0]}
{"wire":[37,1,36,0]}
{"wire":[38,0,109,0]}
{"wire":[110,0,39,0]}
{"wire":[39,0,37,0]}
{"wire":[39,1,38,0]}
{"wire":[40,0,39,0]}
{"wire":[41,0,39,0]}
{"wire":[48,0,111,0]}
{"wire":[49,0,111,0]}
{"wire":[11,0,8,0]}
{"wire":[15,0,8,0]}
{"wire":[44,0,40,0]}
{"wire":[44,1,41,0]}
{"wire":[44,2,42,0]}
{"wire":[44,3,43,0]}
{"wire":[52,0,48,0]}
{"wire":[52,1,49,0]}
{"wire":[52,2,50,0]}
{"wire":[52,3,51,0]}
{"wire":[12,0,10,0]}
{"wire":[12,1,11,0]}
{"wire":[13,0,8,0]}
{"wire":[46,0,44,0]}
{"wire":[47,0,44,0]}
{"wire":[54,0,52,0]}
{"wire":[55,0,52,0]}
{"wire":[97,0,15,0]}
{"wire":[14,0,7,0]}
{"wire":[14,1,9,0]}
{"wire":[14,2,12,0]}
{"wire":[14,3,13,0]}
{"wire":[14,4,13,0]}
{"wire":[45,0,2,0]}
{"wire":[45,1,46,0]}
{"wire":[45,2,47,0]}
{"wire":[53,0,3,0]}
{"wire":[53,1,54,0]}
{"wire":[53,2,55,0]}
{"wire":[99,0,6,0]}
{"wire":[101,0,20,0]}
{"wire":[16,0,14,0]}
{"wire":[16,1,98,0]}
{"wire":[18,0,100,0]}
{"wire":[56,0,45,0]}
{"wire":[114,0,53,0]}
{"wire":[17,0,100,0]}
{"wire":[19,0,16,0]}
{"wire":[19,1,18,0]}
{"wire":[57,0,113,0]}
{"wire":[57,1,56,0]}
{"wire":[58,0,45,0]}
{"wire":[78,0,112,0]}
{"wire":[80,0,112,0]}
{"wire":[20,0,17,0]}
{"wire":[20,1,19,0]}
{"wire":[59,0,57,0]}
{"wire":[59,1,58,0]}
{"wire":[62,0,115,0]}
{"wire":[79,0,77,0]}
{"wire":[79,1,78,0]}
{"wire":[82,0,80,0]}
{"wire":[82,1,81,0]}
{"wire":[85,0,112,0]}
{"wire":[60,0,59,0]}
{"wire":[61,0,59,0]}
{"wire":[63,0,62,0]}
{"wire":[69,0,20,0]}
{"wire":[70,0,20,0]}
{"wire":[83,0,79,0]}
{"wire":[83,1,82,0]}
{"wire":[86,0,84,0]}
{"wire":[86,1,85,0]}
{"wire":[88,0,112,0]}
{"wire":[64,0,60,0]}
{"wire":[64,1,61,0]}
{"wire":[64,2,63,0]}
{"wire":[73,0,69,0]}
{"wire":[73,1,70,0]}
{"wire":[73,2,71,0]}
{"wire":[73,3,72,0]}
{"wire":[87,0,83,0]}
{"wire":[87,1,86,0]}
{"wire":[90,0,88,0]}
{"wire":[90,1,89,0]}
{"wire":[119,0,68,0]}
{"wire":[66,0,64,0]}
{"wire":[67,0,64,0]}
{"wire":[75,0,73,0]}
{"wire":[76,0,73,0]}
{"wire":[91,0,87,0]}
{"wire":[91,1,90,0]}
{"wire":[65,0,1,0]}
{"wire":[65,1,66,0]}
{"wire":[65,2,120,0]}
{"wire":[65,6,67,0]}
{"wire":[74,0,5,0]}
{"wire":[74,1,75,0]}
{"wire":[74,2,76,0]}
{"wire":[93,0,116,0]}
{"wire":[117,0,91,0]}
{"wire":[94,0,92,0]}
{"wire":[94,1,93,0]}
{"wire":[121,0,74,0]}
{"wire":[123,0,65,0]}
{"wire":[95,0,94,0]}
{"wire":[95,1,118,0]}
{"wire":[96,0,122,0]}
{"wire":[96,1,124,0]}
{"wire":[96,2,95,0]}
{"wire":[0,0,96,0]}
ASEEND*/
//CHKSM=7E2E568C667213C3893760D1162629EFE7B30F1B