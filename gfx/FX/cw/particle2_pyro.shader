Includes = {
	"cw/particle2_states.fxh"
	"cw/particle2.fxh"
	"sharedconstants.fxh"
	"cw/particle2_functions.fxh"
	"ssao_struct.fxh"
	"cw/utility.fxh"
}

PixelShader =
{
	MainCode PS_SixPoint
	{
		Input = "VS_OUTPUT_PARTICLE_ADV"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			// Mask A: Red = Right, Green = Top, Blue = Back
			// Mask B: Red = Left, Green = Bottom, Blue = Front
			float ComputeLightMap( float3 LightMaskA, float3 LightMaskB, float3 LightDir )
			{
				float hMap = ( LightDir.x > 0.0f ) ? ( LightMaskA.r ) : ( LightMaskB.r ); // Horizontal sides
				float vMap = ( LightDir.y > 0.0f ) ? ( LightMaskA.g ) : ( LightMaskB.g ); // Vertical sides
				float dMap = ( LightDir.z > 0.0f ) ? ( LightMaskA.b ) : ( LightMaskB.b ); // Front / Back

				float3 axisWeight = abs(LightDir);
				axisWeight /= (axisWeight.x + axisWeight.y + axisWeight.z + 1e-5);

				return dot(float3(hMap, vMap, dMap), axisWeight);
			}
			
			float RemapSixWayLight( float light, float pivot, float contrast, float alpha )
			{		
			    light = saturate( light );
				contrast = max( contrast, 1e-3 );

				float coverage = saturate( alpha );
				float localContrast = lerp( 1.0, contrast, coverage ); 

				float below = light / pivot;
				float above = (light - pivot) / max(1.0 - pivot, 1e-5);

			    below = pow( saturate( below ), localContrast );
				above = 1.0 - pow( saturate( 1.0 - above ), localContrast );
		    
			    float remapped = lerp( below * pivot, pivot + above * ( 1.0 - pivot ), step( pivot, light ) );

			    return saturate( remapped );
			}

			float3 GetTransmissionWithAbsorption(float transmission, float3 absorptionColor, float absorptionRange )
			{
			    const float absorptionStrength = 0.5f;

				absorptionColor = max(absorptionColor, 1e-5);

			    float3 densityScales = 1.0f + log2(absorptionColor) / log2(absorptionStrength);

			    float3 outTransmission = pow(saturate(transmission / absorptionRange), densityScales);

			    return outTransmission * absorptionRange;
			}

			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float3x3 TangentTransformMatrix = float3x3( Input.Tangent, Input.Normal, Input.Bitangent );
				float3 LightDir = mul( TangentTransformMatrix, ToSunDir );

				// --- Frame 0 ---
				float4 Texture01 = PdxTex2D( DiffuseMap, float2( Input.UV0.x, Input.UV0.y * 0.5 ) );
				float4 Texture02 = PdxTex2D( DiffuseMap, float2( Input.UV0.x, Input.UV0.y * 0.5 + 0.5 ) );
				float Light = ComputeLightMap( Texture01.rgb, Texture02.rgb, LightDir );
				

				// -- Frame 1 ---
				float4 Texture01Blend = PdxTex2D( DiffuseMap, float2( Input.UV1.x, Input.UV1.y * 0.5 ) );
				float4 Texture02Blend = PdxTex2D( DiffuseMap, float2( Input.UV1.x, Input.UV1.y * 0.5 + 0.5 ) );
				float LightBlend = ComputeLightMap( Texture01Blend.rgb, Texture02Blend.rgb, LightDir );
				
				#if defined( REMAP )
					Light = RemapSixWayLight( Light, Input.CustomParameter.x, Input.CustomParameter.y, Texture01.a );
					LightBlend = RemapSixWayLight( LightBlend, Input.CustomParameter.x, Input.CustomParameter.y, Texture01Blend.a );
				#endif

				float3 smokeColor, smokeColorBlend;
				float smokeAlpha, smokeAlphaBlend;

				float3 sunColor = SunDiffuse * ( _DayValue + _NightValue );				
				float3 ambient = 0.025 * Input.Color.rgb; 


				// Color Absorption
				#if defined( COLOR_ABSORPTION )
					float absorptionRange = 2.0;
					float3 transmission = GetTransmissionWithAbsorption( Light, Input.Color.rgb, absorptionRange );
					float3 transmissionBlend = GetTransmissionWithAbsorption( LightBlend, Input.Color.rgb, absorptionRange );
					float3 smokeDiffuse = sunColor * transmission + ( ambient * Texture01.a );
					float3 smokeDiffuseBlend = sunColor * transmissionBlend + ( ambient * Texture01Blend.a );
				#else
					float3 smokeDiffuse =  Input.Color.rgb * sunColor * Light + ( ambient * Texture01.a );
					float3 smokeDiffuseBlend =  Input.Color.rgb * sunColor * LightBlend + ( ambient * Texture01Blend.a );
				#endif

				// Removes fire
				#if defined( NON_EMISSIVE )
					smokeColor = smokeDiffuse;
					smokeAlpha = Texture01.a;
					smokeColorBlend = smokeDiffuseBlend;					
					smokeAlphaBlend = Texture01Blend.a;
				#else
					ComputePyroColor( float4(smokeDiffuse, Texture01.a), Texture02.a, Input.Color, smokeColor, smokeAlpha );
					ComputePyroColor( float4(smokeDiffuseBlend, Texture01Blend.a), Texture02Blend.a, Input.Color, smokeColorBlend, smokeAlphaBlend );
				#endif

				float3 finalColor = lerp( smokeColor, smokeColorBlend, Input.FrameBlend );
				float finalAlpha = lerp( smokeAlpha, smokeAlphaBlend, Input.FrameBlend ) * Input.Color.a;
				
				float4 Color = float4( finalColor, finalAlpha );

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

	MainCode PS_PyroTexture
	{
		Input = "VS_OUTPUT_PARTICLE"
		Output = "PS_COLOR_SSAO"
		Code
		[[			
			PDX_MAIN
			{			
				PS_COLOR_SSAO Out;

				float4 tex0 = PdxTex2D( DiffuseMap, Input.UV0 );
				float4 tex1 = PdxTex2D( DiffuseMap, Input.UV1 );

				float3 smokeColor, smokeColorBlend;
				float smokeAlpha, smokeAlphaBlend;

				float3 sunColor = SunDiffuse * ( _DayValue + _NightValue );

				float4 smokeDiffuse = float4( tex0.rrr * Input.Color.rgb * sunColor, tex0.a );
				float4 smokeDiffuseBlend = float4( tex1.rrr * Input.Color.rgb * sunColor, tex1.a );

				ComputePyroColor( smokeDiffuse, tex0.g, Input.Color, smokeColor, smokeAlpha );
				ComputePyroColor( smokeDiffuseBlend, tex1.g, Input.Color, smokeColorBlend, smokeAlphaBlend );

				#if defined( NON_EMISSIVE )
					smokeColor = smokeDiffuse;
					smokeAlpha = tex0.a;
					smokeColorBlend = smokeDiffuseBlend;					
					smokeAlphaBlend = tex1.a;
				#else
					ComputePyroColor( smokeDiffuse, tex0.g, Input.Color, smokeColor, smokeAlpha );
					ComputePyroColor( smokeDiffuseBlend, tex1.g, Input.Color, smokeColorBlend, smokeAlphaBlend );
				#endif
				
				float3 finalColor = lerp( smokeColor, smokeColorBlend, Input.FrameBlend );
				float finalAlpha = lerp( smokeAlpha, smokeAlphaBlend, Input.FrameBlend ) * Input.Color.a;

				float4 Color = float4( finalColor, finalAlpha );

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


Effect ParticleSixPoint
{
	VertexShader = "VertexParticleAdvanced"
	PixelShader = "PS_SixPoint"
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleSixPoint_Premul
{
	VertexShader = "VertexParticleAdvanced"
	PixelShader = "PS_SixPoint"
    BlendState = "PreMultipliedAlpha"
	Defines = { "PREMULTIPLIED" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticlePyro
{
	VertexShader = "VertexParticle"
	PixelShader = "PS_PyroTexture"
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticlePyro_Premul
{
	VertexShader = "VertexParticle"
	PixelShader = "PS_PyroTexture"
	BlendState = "PreMultipliedAlpha"
	Defines = { "PREMULTIPLIED" }
	RasterizerState = "RasterizerStateNoCulling"
}