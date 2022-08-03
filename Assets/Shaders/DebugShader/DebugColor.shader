Shader "Debug/DebugColor"
{
    Properties
    {
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            
            "RenderType" = "Opaque"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct appdata
            {
                float4 positionOS : POSITION;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float4 color : TEXCOORD0;
            };

            v2f vert (appdata input)
            {
                v2f output;

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                
                output.color = input.color;

                return output;
            }


            float4 frag (v2f input) : SV_Target
            {
                return input.color;
            }
            ENDHLSL
        }
        
    }
}
