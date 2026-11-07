Includes = {
	"jomini/jomini_province_overlays.fxh"
	"harvest_condition_variables.fxh"
	"sharedconstants.fxh"
}

PixelShader =
{
	TextureSampler HarvestConditionPatternTextures
	{
		Ref = HarvestConditionPatternTexturesRef
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		type = "2darray"
	}

	BufferTexture HarvestConditionTypeDataBuffer
	{
		Ref = HarvestConditionTypeData
		type = float4
	}

	Code
	[[
		int GetProvinceIndex( float2 MapCoords )
		{
			float2 ColorIndex = PdxTex2D( ProvinceColorIndirectionTexture, MapCoords ).rg;
			return ColorIndex.x * 255.0 + ColorIndex.y * 255.0 * 256.0;
		}

		float GetHarvestConditionPattern( float2 Uv, int index )
		{
			float2 PatternUv = float2( Uv.x * 2.0, 1.0 - Uv.y ) * 25.0;
			float Pattern = PdxTex2D( HarvestConditionPatternTextures, float3( PatternUv, index ) ).r;
			return Pattern;
		}

		void ApplyHarvestConditionOverlay( inout float3 OutColor, float2 MapCoords )
		{
			// Color is set by the painting manager
			float3 HarvestConditionColor = OutColor;

			int ProvinceIndex = GetProvinceIndex( MapCoords );
			float4 ProvinceData = PdxReadBuffer4( HarvestConditionProvinceDataBuffer, ProvinceIndex );
			float4 TypeData = PdxReadBuffer4( HarvestConditionTypeDataBuffer, ProvinceData.b );

			// Apply fade state when hovering over different types: value is between 0 (faded) and 1 (opaque)
			{
				float FadeStateOpacity = 1.0; // Stay opaque by default (no fade)
				if ( TypeData.g == HarvestConditionFadeStateFaded )
				{
					FadeStateOpacity = 0.0f; // Stay faded
				}
				else if ( TypeData.g == HarvestConditionFadeStateFadingIn )
				{
					FadeStateOpacity = _HarvestConditionTransitionProgress; // Progress changes from 0 (faded) to 1 (opaque), follow the value
				}
				else if ( TypeData.g == HarvestConditionFadeStateFadingOut )
				{
					FadeStateOpacity = 1.0 - _HarvestConditionTransitionProgress; // Progress changes from 0 (faded) to 1 (opaque), follow the reversed value
				}

				HarvestConditionColor = lerp( vec3( 1.0 ), HarvestConditionColor, FadeStateOpacity );
			}

			// Apply the pattern texture if needed
			{
				int PatternTextureIndex = (int)TypeData.r;
				if ( PatternTextureIndex >= 0 )
				{
					float Pattern = GetHarvestConditionPattern( MapCoords, PatternTextureIndex );
					HarvestConditionColor = lerp( vec3( 0 ), HarvestConditionColor, Pattern );
				}
			}

			OutColor = lerp( OutColor, HarvestConditionColor, HarvestConditionOverlayAlpha );
		}
	]]
}
