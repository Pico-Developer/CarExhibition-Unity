Shader "Debug/DebugNormal"
{
    Properties
    {
        _BumpMap ("NormalTex", 2D) = "bump" {}
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
                float2 baseUV : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                // float3 positionWS: VAR_POSITION;
                float2 uv : TEXCOORD0;
                float4 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                float4 bitangentWS : TEXCOORD3;
            };

            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            float4 _BumpMap_ST;

            v2f vert (appdata input)
            {
                v2f output;

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS.xyz = TransformObjectToWorldNormal(input.normalOS);
                output.tangentWS.xyz = TransformObjectToWorldDir(input.tangentOS);
                output.bitangentWS.xyz = cross(output.normalWS.xyz,output.tangentWS.xyz) * input.tangentOS.w * unity_WorldTransformParams.w;

                output.tangentWS.w = positionWS.x;
                output.bitangentWS.w = positionWS.y;
                output.normalWS.w = positionWS.z;
                
                output.uv.xy = TRANSFORM_TEX(input.baseUV, _BumpMap);

                return output;
            }

            float lambert(float3 normal, float3 lightDir, float lambertScale = 0.0f)
            {
                return clamp(dot(lightDir, normal), 0, 1) * (1 - lambertScale) + lambertScale;
            }
            

            float4 frag (v2f input) : SV_Target
            {
                float3x3 TBN = float3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
                TBN = transpose(TBN);

                half4 normalTex = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv.xy);
                half3 unpackNormal = UnpackNormal(normalTex);
                float3 normal = mul(TBN, unpackNormal);

                normal = normal * 0.5 + 0.5;
                
                return float4(normal, 1);
            }
            ENDHLSL
        }
        
    }
}
