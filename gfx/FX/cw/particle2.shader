Includes = {
	"cw/particle2_states.fxh"
	"cw/particle2.fxh"
	"cw/particle2_functions.fxh"
	"ssao_struct.fxh"
}

PixelShader =
{
	MainCode PixelColor
	{
		Input = "VS_OUTPUT_PARTICLE"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				return Input.Color;
			}
		]]
	}
	
	MainCode PixelTexture
	{
		Input = "VS_OUTPUT_PARTICLE"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float4 Color = PdxTex2D( DiffuseMap, Input.UV0 ) * Input.Color;
				float4 NextColor = PdxTex2D( DiffuseMap, Input.UV1 ) * Input.Color;
				Color = Color * ( 1.0f - Input.FrameBlend ) + NextColor * Input.FrameBlend;

				// World-space RGB effects (fog, overlays, highlights) + terrain height fade
				ApplyParticleFeatures( Color, Input.WorldSpacePos );

				// Premultiplies the color by alpha if defined
				#if defined( PREMULTIPLIED )
					Color.rgb *= Input.Color.a;
					Out.SSAOColor = float4( vec4( Color.a ) );
				#endif

				// Output
				Out.Color = Color;		

				return Out;
			}
		]]
	}
}

Effect ParticleTexture
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleColor
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelColor"
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleTextureBillboard
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	Defines = { "BILLBOARD" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleColorBillboard
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelColor"
	Defines = { "BILLBOARD" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleTBE
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	BlendState = "AdditiveBlendState"
	Defines = { "BILLBOARD" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleCBE
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelColor"
	BlendState = "AdditiveBlendState"
	Defines = { "BILLBOARD" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleTE
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	BlendState = "AdditiveBlendState"
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleCE
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelColor"
	BlendState = "AdditiveBlendState"
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleColorFade
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelColor"
	Defines = { "FADE_STEEP_ANGLES" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleTextureFade
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	Defines = { "FADE_STEEP_ANGLES" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleCFE
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelColor"
	BlendState = "AdditiveBlendState"
	Defines = { "FADE_STEEP_ANGLES" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleTFE
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	BlendState = "AdditiveBlendState"
	Defines = { "FADE_STEEP_ANGLES" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleCFB
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelColor"
	Defines = { "FADE_STEEP_ANGLES" "BILLBOARD" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleTFB
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	Defines = { "FADE_STEEP_ANGLES" "BILLBOARD" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleCFBE
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelColor"
	BlendState = "AdditiveBlendState"
	Defines = { "FADE_STEEP_ANGLES" "BILLBOARD" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleTFBE
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	BlendState = "AdditiveBlendState"
	Defines = { "FADE_STEEP_ANGLES" "BILLBOARD" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleTextureDepthFade
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	Defines = { "PARTICLE_FADE_HEIGHT"}
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleTextureBillboardDepthFade
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	Defines = { "BILLBOARD" "PARTICLE_FADE_HEIGHT"}
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleFlipX
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	Defines = { "BILLBOARD" "FLIP_X" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleFlipX_Premul
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	BlendState = "PreMultipliedAlpha"
	Defines = { "BILLBOARD" "FLIP_X" "PREMULTIPLIED" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticlePreMultiplied
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	BlendState = "PreMultipliedAlpha"
	Defines = { "PREMULTIPLIED" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticlePreMultiplied_Billboard
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	BlendState = "PreMultipliedAlpha"
	Defines = { "BILLBOARD" "PREMULTIPLIED" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleBlendAdd
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	BlendState = "BlendAdd"
	Defines = { "PREMULTIPLIED" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleBlendAdd_Billboard
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	BlendState = "BlendAdd"
	Defines = { "BILLBOARD" "PREMULTIPLIED" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleAdditiveNoDepth
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelTexture"
	BlendState = "AdditiveBlendState"
	RasterizerState = "RasterizerStateNoCulling"
	DepthStencilState = DepthStencilStateNoDepth
}