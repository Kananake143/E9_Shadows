
cbuffer MatrixBuffer : register(b0)
{
	matrix worldMatrix;
	matrix viewMatrix;
	matrix projectionMatrix;
	matrix lightViewMatrix;
	matrix lightProjectionMatrix;
    matrix lightViewMatrix2;
    matrix lightProjectionMatrix2;
};

struct InputType
{
    float4 position : POSITION;
    float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
};

struct OutputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
    float4 lightViewPos : TEXCOORD1;
    float4 lightPosition2 : TEXCOORD2;
};


OutputType main(InputType input)
{
    OutputType output;
    float4 worldPosition;

	// Calculate the position of the vertex against the world, view, and projection matrices.
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
    
    output.tex = input.tex;
    
    output.normal = mul(input.normal, (float3x3) worldMatrix);
    
    output.normal = normalize(output.normal);
    
    worldPosition = mul(input.position, worldMatrix);
    
	// Calculate the position of the vertice as viewed by the light source.
    output.lightViewPos = mul(worldPosition, lightViewMatrix);
    output.lightViewPos = mul(output.lightViewPos, lightProjectionMatrix);
    
    output.lightPosition2 = mul(worldPosition, lightViewMatrix2);
    output.lightPosition2 = mul(output.lightPosition2, lightProjectionMatrix2);

    
    

	return output;
}