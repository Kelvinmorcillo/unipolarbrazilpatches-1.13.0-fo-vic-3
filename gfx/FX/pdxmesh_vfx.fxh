

VertexShader =
{
	Code
	[[
		#define UI_SCREEN_BURN_UV0_MULT float2( 2.4f, 3.1f )
		#define UI_SCREEN_BURN_UV0_SPEED 0.05f
		#define UI_SCREEN_BURN_UV1_SPEED 0.1f

		#define UI_PANNING_TEXTURE_UV0_MULT float2 ( 5.0f, 1.0f )
		#define UI_PANNING_TEXTURE_UV0_SPEED float2 ( 0.0f, 0.4f )

		#define UI_PANNING_TEXTURE_UV2_MULT float2( 3.0f, 0.5f )
		#define UI_PANNING_TEXTURE_UV2_SPEED float2 ( 0.05f, 0.05f)
	]]
}

PixelShader =
{
	Code
	[[
		#define UV_DIST_STRENGTH 0.1f

		#define LOWER_EDGE_FALLOFF 0.8f
		#define LOWER_EDGE_MULT 1.0f
		#define LOWER_EDGE_CUT 0.1f
		#define LOWER_EDGE_COL_SLIDE 0.1f

		#define UPPER_EDGE_FALLOFF 0.1f
		#define UPPER_EDGE_COL float3( 0.2f, 0.0f, 0.0f )

		#define FINAL_ALPHA_MULT 1.0f
		#define FINAL_COL_MULT 3.0f


		// Panning Texture Defines
		#define PanningTex_Alpha 			0.5						// Alpha
		#define PanningTex_PanSpeed 		1.0						// Pan speed
		#define PanningTex_GapDistance 		3.0						// Distance between each UV repetition
		#define PanningTex_TextureScale 	float2 ( 1.0, 2.5 )		// Uv scale
		#define PanningTex_FadeDistance 	0.15					// Distance of fade in/out
		#define PanningTex_FadeContrast 	0.1						// Sharpness of fade in/out
	]]
}
