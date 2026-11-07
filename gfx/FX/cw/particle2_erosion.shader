Includes = {
	"cw/particle2_states.fxh"
	"cw/particle2.fxh"
	"cw/particle2_functions.fxh"
	"ssao_struct.fxh"
}
PixelShader =
{
	MainCode AlphaErosion
	{
		Input = "VS_OUTPUT_PARTICLE"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float4 Color = PdxTex2D( DiffuseMap, Input.UV0 );
			
				float erosion = 1 - Input.Color.a;
				float maskAlpha = saturate(Color.a);

				float baseFeather = 1.0;
				float sharpness = lerp(1.0, 4.0, erosion * erosion);
				float smoothEnd = erosion + baseFeather / sharpness;
				float alphaEroded = smoothstep(erosion, smoothEnd, maskAlpha);

				Color.rgb *= Input.Color.rgb;
				Color.a = alphaEroded;

				// World-space RGB effects (fog, overlays, highlights) + terrain height fade
				ApplyParticleFeatures( Color, Input.WorldSpacePos );

				// Premultiplies the color by alpha if defined
				#if defined( PREMULTIPLIED )
					Color.rgb *= Input.Color.a;
				#endif

				// Output
				Out.Color = Color;
				Out.SSAOColor = float4( vec4( 1.0f ) );

				return Out;
			}
		]]
	}
}

Effect ParticleAlphaErosion
{
	VertexShader = "VertexParticle"
	PixelShader = "AlphaErosion"
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleAlphaErosion_Premul
{
	VertexShader = "VertexParticle"
	PixelShader = "AlphaErosion"
	BlendState = "PreMultipliedAlpha"
	Defines = { "PREMULTIPLIED" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleAlphaErosionAdditive
{
	VertexShader = "VertexParticle"
	PixelShader = "AlphaErosion"
	BlendState = "AdditiveBlendState"
	RasterizerState = "RasterizerStateNoCulling"
}