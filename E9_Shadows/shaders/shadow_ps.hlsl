Texture2D shaderTexture : register(t0);

Texture2D depthMap1 : register(t1);
Texture2D depthMap2 : register(t2);

SamplerState diffuseSampler : register(s0);
SamplerState shadowSampler : register(s1);


struct LightData
{

    float4 ambient;
    float4 diffuse;
    float3 direction;
    float padding;
};

cbuffer LightBuffer : register(b1)
{
    LightData light1;
    LightData light2; // NEW
};

struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
    float4 lightViewPos : TEXCOORD1;
    float4 lightViewPos2 : TEXCOORD2;
};



// Calculate lighting intensity based on direction and normal. Combine with light colour.
float4 CalculateLight(LightData light, float3 normal, float shadowFactor, float4 textureColour)
{
    float3 lightDir = normalize(light.direction);

    // Ambient Light
    float4 ambient = light.ambient * textureColour;

    // Diffuse Light (only if not in shadow)
    float lightIntensity = saturate(dot(normal, -lightDir));
    float4 diffuse = saturate(light.diffuse * lightIntensity * shadowFactor) * textureColour;

    return ambient + diffuse;
}


float2 getProjectiveCoords(float4 lightViewPosition)
{
    // Calculate the projected texture coordinates.
    float2 projTex = lightViewPosition.xy / lightViewPosition.w;
    projTex *= float2(0.5, -0.5);
    projTex += float2(0.5f, 0.5f);
    return projTex;
}

// Is the gemoetry in our shadow map
//bool hasDepthData(float2 uv)
//{
  //  if (uv.x < 0.f || uv.x > 1.f || uv.y < 0.f || uv.y > 1.f)
  //  {
  //      return false;
  //  }
  //  return true;
//}

float CalculateShadow(Texture2D sMap, float4 lightViewPosition, float bias, SamplerState shadowSampler)
{
    // Convert Light View Position to UV coords [0, 1] and Depth [0, 1]
    float3 lightCoord = lightViewPosition.xyz / lightViewPosition.w;
    lightCoord = lightCoord * 0.5f + 0.5f;

    // Check if coordinate is outside the shadow map bounds
    if (lightCoord.x < 0.f || lightCoord.x > 1.f || lightCoord.y < 0.f || lightCoord.y > 1.f)
    {
        return 1.0f; // Outside map, assume fully lit
    }

    // Sample the shadow map (get recorded depth)
    float depthValue = sMap.Sample(shadowSampler, lightCoord.xy).r;

    // Calculate light depth (the fragment's depth) and apply bias
    float lightDepth = lightCoord.z;
    
    float shadow = 0.0f;

    // Compare the light's depth with the depth recorded in the map
    if (lightDepth < depthValue + bias) // Note: bias + recorded depth (depthValue) or - light depth (lightDepth)
    {
        shadow = 1.0f; // Fragment is closer to light than what's recorded -> not in shadow
    }
    else
    {
        shadow = 0.0f; // In shadow
    }

    return shadow;
}


float4 main(InputType input) : SV_TARGET
{
    float bias = 0.005f;
    float4 textureColour = shaderTexture.Sample(diffuseSampler, input.tex);
    float3 normal = normalize(input.normal);

	// Calculate the projected texture coordinates.
    float shadowFactor1 = CalculateShadow(depthMap1, input.lightViewPos, bias, shadowSampler);
    float4 lightColour1 = CalculateLight(light1, normal, shadowFactor1, textureColour);
    
    // --- Light 2: Shadow Calculation ---
    float shadowFactor2 = CalculateShadow(depthMap2, input.lightViewPos2, bias, shadowSampler);
    float4 lightColour2 = CalculateLight(light2, normal, shadowFactor2, textureColour);
	
    float4 finalColour = lightColour1 + lightColour2;
    
    return saturate(finalColour);
}