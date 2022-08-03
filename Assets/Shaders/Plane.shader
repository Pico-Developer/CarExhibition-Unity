Shader "Car/Plane"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("BaseColor", Color) = (0, 0, 0, 1)
        
        _NormalTex ("_NormalTex", 2D) = "bump" {}
        _ReflectionCube ("ReflectionCube", Cube) = "black" {}
        _Reflectivity ("Reflectivity", Range(.0, 1.0)) = 1.0
        
        _HeightMap ("HeightMap", 2D) = "black"
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
        }
        LOD 100

        Pass {
            
            Tags
            {
                "LightMode"="UniversalForward"
            }
            
            Cull Back
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "Comm.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            float4 _NormalTex_ST;
            TEXTURE2D(_HeightMap);
            SAMPLER(sampler_HeightMap);
            float4 _HeightMap_ST;

            TEXTURECUBE(_ReflectionCube);
            SAMPLER(sampler_ReflectionCube);
            float _Reflectivity;
            
            float4 _BaseColor;
            
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
                float4 uv : TEXCOORD0;
                float4 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                float4 bitangentWS : TEXCOORD3;
            };

            v2f vert(appdata input)
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
                
                
                //input.baseUV * baseST.xy + baseST.zw;
                output.uv.xy = TRANSFORM_TEX(input.baseUV, _MainTex);
                output.uv.zw = TRANSFORM_TEX(input.baseUV, _NormalTex);
                
                return output;
            }

            

            float4 frag(v2f input): SV_TARGET
            {
                float3 positionWS = float3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
                float3x3 TBN = float3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
                TBN = transpose(TBN);
                
                Light light = GetMainLight();
                float3 lightDir = normalize(light.direction);
                float3 viewDir = normalize(GetWorldSpaceViewDir(positionWS));

                float4 normTex = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, input.uv.zw);
                float3 unpackNormal = UnpackNormalScale(normTex, 1);
                float3 normal = mul(TBN, unpackNormal);

                

                float3 ambient = light.color.xyz;
                
                // lambert
                float lamb = lambert(normal, lightDir);

                float3 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy).rgb;
                float3 diffuse = mainColor * _BaseColor * lamb * ambient;

                return float4(diffuse, 1);
            }
            
            ENDHLSL
        }
    }
}