Includes = {
	"cw/utility.fxh"
	"cw/heightmap.fxh"
	"sharedconstants.fxh"
	"coloroverlay.fxh"
	"distance_fog.fxh"
	"fog_of_war.fxh"
	"jomini/jomini_water.fxh"
}

PixelShader = {

	TextureSampler RampTexture01
	{
		Ref = PdxTexture4
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		file = "gfx/particles/textures/ramps/blackbody_ramp_01.png"
		srgb = yes
	}

	Code
	[[
		void ApplyParticleFeatures( inout float4 Color, float3 WorldSpacePos )
		{
			#if defined( MAP_PARTICLE ) && !defined( GUI_SHADER )
				// Paralax offset to keep overlays at terrain level
				float3 ToCam = normalize( CameraPosition - WorldSpacePos );
				float ParalaxDist = ( 0.0 - WorldSpacePos.y ) / ToCam.y;
				float3 ParallaxCoord = WorldSpacePos + ToCam * ParalaxDist;
				ParallaxCoord.xz = ParallaxCoord.xz / _ProvinceMapSize;

				float3 ColorOverlay;
				float PreLightingBlend;
				float PostLightingBlend;
				GameProvinceOverlayAndBlend( ParallaxCoord.xz, WorldSpacePos, ColorOverlay, PreLightingBlend, PostLightingBlend );
				Color.rgb = ApplyColorOverlay( Color.rgb, ColorOverlay, saturate( PreLightingBlend + PostLightingBlend ) );

				float3 PostEffectsColor = Color.rgb;
				PostEffectsColor = ApplyFogOfWar( PostEffectsColor, WorldSpacePos );
				PostEffectsColor = GameApplyDistanceFog( PostEffectsColor, WorldSpacePos );
				Color.rgb = lerp( Color.rgb, PostEffectsColor, 1.0 - _FlatmapLerp );
			#endif

			#if defined( FADE_HEIGHT )
				float TerrainHeight = GetHeight( WorldSpacePos.xz );
				TerrainHeight = max( _WaterHeight, TerrainHeight );
				float HeightDiff = saturate( WorldSpacePos.y - TerrainHeight );
				float FadeFactor = saturate( HeightDiff / 0.25 );
				Color.a *= FadeFactor;

				// Adjusts RGB if premultiplied
				#if defined( PREMULTIPLIED )
					Color.rgb *= FadeFactor;
				#endif	
			#endif
		}

		void ComputePyroColor(float4 tex, float emissiveMask, float4 inputColor, out float3 rgb, out float a)
        {
			float emissiveIntensity = 1.5 + ( _NightValue * 1.5 );
            float3 EmissiveTex = PdxTex2D(RampTexture01, float2(emissiveMask, 0.5)).rgb;

			float Compensation = 1.0 / max( inputColor.a, 0.1);
			float3 fireColor = EmissiveTex * emissiveMask * Compensation * emissiveIntensity;

    		// Darken the base (smokeDiffuse) under emissive areas to reduce bleaching
    		float darkenFactor = 1.0;
    		float3 darkenedBase = tex.rgb * (1.0 - emissiveMask * darkenFactor);
		
    		rgb = darkenedBase + fireColor;
    		a = tex.a;
        }
	]]
}
