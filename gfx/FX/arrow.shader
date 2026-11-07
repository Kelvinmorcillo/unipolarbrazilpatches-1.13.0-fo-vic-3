Includes = {
	"cw/camera.fxh"
	"sharedconstants.fxh"
	"standardfuncsgfx.fxh"
	"coloroverlay.fxh"
	"arrow_settings.fxh"
}

VertexStruct VS_INPUT
{
	float3 vPosition  : POSITION;
	float2 vTexCoord  : TEXCOORD0;
};

VertexStruct VS_OUTPUT
{
	float4 vPosition : PDX_POSITION;
	float2 vTexCoord : TEXCOORD0;
	float3 vPos		 : TEXCOORD1;
};

ConstantBuffer( 0 )
{
	float AnimationLength;
	float MoveLength;
	float ClipLength;
	float TotalLength;
	float Width;
};

ConstantBuffer( 1 )
{
	int IsSelected;
	int IsFaded;
};


VertexShader =
{
	MainCode VertexShader
	{
		Input = "VS_INPUT"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT Out;
				float4 pos = float4( Input.vPosition, 1.0f );
			#ifdef FLAT_MAP
				pos.y = lerp( pos.y, _FlatmapHeight, _FlatmapLerp );
			#endif
				pos.y += 0.15f;

				Out.vPos = pos.xyz;
				Out.vPosition  = FixProjectionAndMul( ViewProjectionMatrix, pos );
				Out.vTexCoord = Input.vTexCoord;

				return Out;
			}
		]]
	}
}


PixelShader =
{
	TextureSampler DiffuseTexture
	{
		Index = 0
		MipFilter = "Linear"
		MinFilter = "Linear"
		MagFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler ArrowColorTexture
	{
		Index = 3
		MipFilter = "Linear"
		MinFilter = "Linear"
		MagFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}

	MainCode PixelShader
	{
		Input = VS_OUTPUT
		Output = PDX_COLOR

		Code
		[[
			PDX_MAIN
			{
				// Map Uvs
				float2 ProvinceCoords = Input.vPos.xz / _ProvinceMapSize;
				float2 MapCoords = ( Input.vPos.xz * _WorldSpaceToTerrain0To1 );
				MapCoords.x *= 2.0;

				// Unit position
				float Passed = Input.vTexCoord.y < MoveLength ? 1.0f : 0.0f;

				// Inital Uv tiling
				float Tiling = 10.0 * Width;
				float NumTiles = floor( TotalLength / Tiling );
				float Offset = ( TotalLength - ( Tiling * NumTiles ) ) / Tiling;
				float2 Uv = Input.vTexCoord.xy;
				Uv.y /= Tiling;
				Uv.y = Uv.y + 1.0 - Offset;
				Uv.x *= 0.5;

				float2 texDdx = ddx( Uv );
				float2 texDdy = ddy( Uv );

				// Find and repeat Uv segments along the full spline, with a different end point
				float ArrowEnd = lerp( 0.5, 0.0, _FlatmapLerp );
				float Tile = Uv.y;
				Uv.y = mod( Uv.y, 1.0 );
				if( Tile >= NumTiles )
				{
					Uv.y += ArrowEnd;
				}
				else if( frac( Tile ) > 0.5 )
				{
					Uv.y = 0.5 - Uv.y;
				}
				Uv.y = 1.0 - Uv.y;

				// Arrow Base textures
				float FillMask = PdxTex2DGrad( DiffuseTexture, Uv, texDdx, texDdy ).a;
				float OutlineMask = PdxTex2DGrad( DiffuseTexture, Uv, texDdx, texDdy ).g;

				// Finding water vs land, constant data
				float4 AlternateColor = BilinearColorSampleAtOffset( ProvinceCoords, IndirectionMapSize, InvIndirectionMapSize, ProvinceColorIndirectionTexture, ProvinceColorTexture, AlternateProvinceColorsOffset );
				AlternateColor.rg = vec2( 0.0f ); // Zero out unused channels to avoid issues
				float4 LakeColor = float4( 0.0f, 0.0f, 0.0f, 1.0f ); // Needs to match color in mappaintingmanager.cpp
				float4 SeaColor = float4( 0.0f, 0.0f, 1.0f, 0.0f );	// Needs to match color in mappaintingmanager.cpp
				float4 LakeDiff = LakeColor - AlternateColor;
				float4 SeaDiff = SeaColor - AlternateColor;
				float WaterLerp = 1.0 - ( dot( LakeDiff, LakeDiff ) * dot( SeaDiff, SeaDiff ) );

				// Animated Caustics
				float3x3 BaseMatrix = Create3x3( -2.0, -1.0, 2.0, 3.0, -2.0, 1.0, 1.0, 2.0, 2.0 );
				float2 CausticUv = MapCoords * 220.0;
				CausticUv = lerp( CausticUv, CausticUv * 0.35, _FlatmapLerp );
				float Speed = 0.05;
				float3 a = mul( float3( CausticUv.x, CausticUv.y, GlobalTime * Speed ), BaseMatrix );
				float3 b = mul( a, BaseMatrix ) * 0.4;
				float3 c = mul( b, BaseMatrix ) * 0.3;
				float CausticsNoise = float( pow( min( min( length( 0.5 - frac( a ) ), length( 0.5 - frac( b ) ) ), length( 0.5 - frac( c ) ) ), 6.0 ) * 9.0 );
				float3 CausticsColor = float3( 0.05, 0.15, 0.9 ) * 0.75 * CausticsNoise;
				#if defined( ARROW_COLOR_VISUALS )
					CausticsColor *= 0.0;
				#endif

				// Base colors
				#if defined( ARROW_COLOR_VISUALS )
					float3 vLandBaseColor = PdxTex2D( ArrowColorTexture, Input.vTexCoord ).rgb;
					float3 vWaterBaseColor = vLandBaseColor;
				#else
					float3 vLandBaseColor = LandBaseColor;
					float3 vWaterBaseColor = WaterBaseColor;
				#endif

				// Outline colors
				float3 LandOutlineColor = vLandBaseColor * LandInnerArrowColorMult;
				float3 WaterOutlineColor = vWaterBaseColor * WaterInnerArrowColorMult;

				float Opacity = lerp( ArrowOpacity, FlatmapOpacity, _FlatmapLerp );
				float Spacing = lerp( ArrowSpacing, FlatmapArrowSpacing, _FlatmapLerp );
				float UvScaling = lerp( ArrowUvScaling, FlatmapUvScaling, _FlatmapLerp );

				// Land to water colors, flipped when passed
				float3 BaseColor = lerp( vLandBaseColor, vWaterBaseColor + CausticsColor * ( 1.0 - Passed ), WaterLerp );
				float3 PassedColor = lerp( LandOutlineColor, WaterOutlineColor, WaterLerp );
				float3 OutlineColor = lerp( LandOutlineColor, WaterOutlineColor, WaterLerp );
				float3 OutlinePassedColor = lerp( vLandBaseColor, vWaterBaseColor, WaterLerp );

				// Inner Arrow
				float UvLength = Input.vTexCoord.y * UvScaling * 0.25 ;
				UvLength -= GlobalTime * ArrowSpeed;
				float2 InnerArrowUv = float2( Input.vTexCoord.x, UvLength );
				InnerArrowUv = 1.0 - mod( abs( InnerArrowUv ), 1.0 );

				// Fix for when the Uvs pan into the negative
				if ( UvLength < 0.0 )
				{
					InnerArrowUv.y = 1.0 - InnerArrowUv.y;
					UvLength -= 1.0;
				}

				// Inner Arrow Mask
				float InnerArrowMask = PdxTex2DGrad( DiffuseTexture, InnerArrowUv, texDdx, texDdy ).r;
				InnerArrowMask = InnerArrowMask * FillMask;
				float3 InnerArrowColor = InnerArrowMask * OutlineColor;
				InnerArrowColor = lerp( InnerArrowColor, InnerArrowColor + CausticsColor * 3.0, WaterLerp );

				// Colors when passed
				float3 OutColor = lerp( BaseColor, PassedColor, Passed );
				OutlineColor = lerp( OutlineColor, OutlinePassedColor, Passed );
				InnerArrowColor = lerp( InnerArrowColor, OutlinePassedColor, Passed );

				// Compounded
				OutColor = lerp( OutColor, OutlineColor, OutlineMask );

				float Segment = step( mod( abs( UvLength ), Spacing ), 1.0 );
				OutColor = lerp( OutColor, InnerArrowColor, Segment * saturate( InnerArrowMask - OutlineMask ) );
				Opacity = FillMask * Opacity;

				// Alpha
				float vFadeLength = ClipLength + 2.0f;
				float FadeAlpha = Input.vTexCoord.y - vFadeLength;
				FadeAlpha = saturate( FadeAlpha * saturate( 1.0f - ( FadeAlpha / -vFadeLength ) ) );
				Opacity *= FadeAlpha;
				Opacity = lerp( Opacity, Opacity * ArrowNonSelectedFade, (float)IsFaded );

				float NormalizedSplineY = Input.vTexCoord.y * ( 1.0 / TotalLength );
				float HighlightAreaLeft = LevelsScan( Uv.x + 0.5, ArrowHighlightAreaSize, ArrowHighlightAreaSoftness );
				float HighlightAreaRight = LevelsScan( 1.0 - Uv.x, ArrowHighlightAreaSize, ArrowHighlightAreaSoftness );
				float HighlightAreaStart = LevelsScan( NormalizedSplineY, ArrowHighlightAreaEndsLength, ArrowHighlightAreaEndsSoftness );
				float HighlightAreaEnd = LevelsScan( 1.0 - NormalizedSplineY, ArrowHighlightAreaEndsLength, ArrowHighlightAreaEndsSoftness );

				float HighlightArea = HighlightAreaLeft * HighlightAreaRight;

				float3 HighlightColor = ArrowHighlightColor * ( sin( ( ( NormalizedSplineY * 20.0 ) ) - GlobalTime * 2.0 ) + 2.0  ) * ArrowHighlightColorMult;

				OutColor = lerp( OutColor, HighlightColor, ( 1.0 - Opacity ) * (float)IsSelected * HighlightAreaLeft * HighlightAreaRight * HighlightAreaStart * HighlightAreaEnd );

				// Close fade
				Opacity = saturate( Opacity + HighlightArea * (float)IsSelected );
				Opacity = FadeCloseAlpha( Opacity );

				return float4( OutColor, Opacity );
			}
		]]
	}
}


BlendState ArrowBlendState
{
 	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
}

RasterizerState RasterizerState
{
 	DepthBias = 0
	#fillmode = wireframe
}

DepthStencilState DepthStencilState
{
	DepthEnable = yes
	DepthWriteEnable = no
}

Effect ArrowMoveEffect
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	BlendState = "ArrowBlendState"
}

Effect ArrowMoveEffectFlatMap
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	BlendState = "ArrowBlendState"

	Defines = { "FLAT_MAP" }
}

Effect ArrowTextureColorEffect
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	BlendState = "ArrowBlendState"

	Defines = { "ARROW_COLOR_VISUALS" "FLAT_MAP" }
}

Effect ArrowTextureColorEffectFlatMap
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	BlendState = "ArrowBlendState"

	Defines = { "ARROW_COLOR_VISUALS" "FLAT_MAP" }
}

